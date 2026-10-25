{
  stdenv,
  stdenvNoCC,
  mk-apk-package,
  overrides-fromsrc,
  buildGradlePackage,
  lib,
  jdk25_headless,
  fetchFromGitHub,

  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  gradle_9_2_1,

  go_1_27,
  curl,
  cacert,
  patch,
  unzip,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-37-0
    s.build-tools-36-0-0
    s.build-tools-37-0-0
    s.ndk-28-2-13676358
  ]);

  androidSdkRoot = "${androidSdk}/share/android-sdk";
  androidNdkRoot = "${androidSdkRoot}/ndk/28.2.13676358";
  aapt2 = "${androidSdkRoot}/build-tools/36.0.0/aapt2";

  gradle = gradle_9_2_1;

  version = "5.3.0";
  src = fetchFromGitHub {
    owner = "bropines";
    repo = "tailsocks";
    tag = "v${version}";
    hash = "sha256-OhYKDZoRe1u3duC1XzoRDtMURCO81Wmf1g3zsJfKkic=";
  };

  tailscaleVersion = "1.104.1";
  # git rev-parse v1.104.1^{}
  tailscaleCommit = "9a522a9786c97eb7910c01ccb7bd66557b04c910";
  # git rev-parse v5.3.0^{}
  appCommit = "45fa11699b98de140101672550462b1eae0e8656";
  # TZ=UTC git log -1 --format=%cd --date=format-local:%Y-%m-%d_%H%M%S v5.3.0^{}
  appCommitTime = "2026-10-24_061206";

  tailscaleSrc = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale";
    tag = "v${tailscaleVersion}";
    hash = "sha256-f80GVxstQrr8ENP1bseoIpLflQ+QYEisDF8PHzTs7Lg=";
  };

  hevSocks5Tunnel = fetchFromGitHub {
    owner = "heiher";
    repo = "hev-socks5-tunnel";
    rev = "c6e4c72246fb0f20bda299f0efc7814bb3098d57";
    fetchSubmodules = true;
    hash = "sha256-eLErBWUseEJ+zvsNPtMU6tFo7GtzT3owPaAMIHzlIFc=";
  };

  # Patches use paths orig/... and tailscale_src/... ; -p1 makes both apply
  # inside the unpacked Tailscale tree, matching appctr/build.sh.
  prepareTailscale = ''
    rm -rf appctr/tailscale_src
    cp -R ${tailscaleSrc} appctr/tailscale_src
    chmod -R u+w appctr/tailscale_src
    for p in appctr/patches/*.patch; do
      patch -p1 --batch --forward -F0 -d appctr/tailscale_src < "$p"
    done
    echo "v${tailscaleVersion}" > appctr/tailscale_src/.build_version
    echo "${tailscaleCommit}" > appctr/tailscale_src/.commit
  '';

  goModCache = stdenvNoCC.mkDerivation {
    pname = "tailsocks-go-mod-cache";
    inherit version src;

    nativeBuildInputs = [
      go_1_27
      curl
      cacert
      patch
      unzip
    ];

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-3MgwED5GWRcaXHuD47xFsChgzsMftVNRJtsqTM5BENE=";

    dontConfigure = true;
    dontFixup = true;

    buildPhase = ''
      runHook preBuild

      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      export GOPATH="$TMPDIR/go"
      export GOCACHE="$TMPDIR/go-build-cache"
      export GOMODCACHE="$TMPDIR/go-mod-cache"
      export GOTOOLCHAIN=local
      export GOPROXY=https://proxy.golang.org,direct
      export GOSUMDB=sum.golang.org
      export GOFLAGS=-buildvcs=false

      cp -R "$src" source
      chmod -R u+w source
      cd source
      ${prepareTailscale}

      anet_version=$(awk '$1 == "github.com/wlynxg/anet" { print $2; exit }' appctr/go.mod)
      (
        cd appctr/tailscale_src
        go get "github.com/wlynxg/anet@$anet_version"
        go mod tidy
      )

      # Go 1.27 rejects x/mobile's godebug gotypesalias=0. Replace it with a
      # stripped tree before the appctr module graph loads that go.mod.
      curl -fsSL -o "$TMPDIR/mobile.zip" \
        "https://proxy.golang.org/golang.org/x/mobile/@v/v0.0.0-20251126181937-5c265dc024c4.zip"
      unzip -q "$TMPDIR/mobile.zip" -d "$TMPDIR/xmobile-unpack"
      xsrc="$(find "$TMPDIR/xmobile-unpack" -name go.mod -printf '%h\n' -quit)"
      test -n "$xsrc"
      mv "$xsrc" "$TMPDIR/x-mobile"
      substituteInPlace "$TMPDIR/x-mobile/go.mod" \
        --replace-fail 'godebug gotypesalias=0' ""
      (
        cd appctr
        go mod edit -replace=golang.org/x/mobile="$TMPDIR/x-mobile"
        go mod tidy
        go mod download
      )
      (cd "$TMPDIR/x-mobile" && go mod download)

      cp appctr/tailscale_src/go.mod "$TMPDIR/tailscale.go.mod"
      cp appctr/tailscale_src/go.sum "$TMPDIR/tailscale.go.sum"

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      rm -rf "$TMPDIR/go-mod-cache/cache/download/sumdb"
      chmod -R u+w "$TMPDIR/go-mod-cache" "$TMPDIR/x-mobile"
      mkdir -p "$out"
      mv "$TMPDIR/go-mod-cache" "$out/cache"
      mv "$TMPDIR/x-mobile" "$out/x-mobile"
      # go get/tidy added anet for the Android patches. The offline build
      # starts from upstream sources, so keep the settled module files.
      cp "$TMPDIR/tailscale.go.mod" "$out/tailscale.go.mod"
      cp "$TMPDIR/tailscale.go.sum" "$out/tailscale.go.sum"
      runHook postInstall
    '';
  };

  appctrArtifacts = stdenv.mkDerivation {
    pname = "tailsocks-appctr";
    inherit version src;

    nativeBuildInputs = [
      go_1_27
      jdk25_headless
      patch
      unzip
      writableTmpDirAsHomeHook
    ];

    dontConfigure = true;

    env = {
      JAVA_HOME = jdk25_headless.passthru.home;
      ANDROID_HOME = androidSdkRoot;
      ANDROID_SDK_ROOT = androidSdkRoot;
      ANDROID_NDK_HOME = androidNdkRoot;
      ANDROID_NDK_ROOT = androidNdkRoot;
    };

    buildPhase = ''
      runHook preBuild

      export GOPATH="$TMPDIR/go"
      export GOCACHE="$TMPDIR/go-cache"
      export GOMODCACHE="$PWD/.gomodcache"
      export GOBIN="$TMPDIR/go-bin"
      mkdir -p "$GOPATH" "$GOCACHE" "$GOBIN" "$GOMODCACHE" "$HOME/.android"
      cp -R ${goModCache}/cache/. "$GOMODCACHE"
      chmod -R u+w "$GOMODCACHE"
      export PATH="$GOBIN:$PATH"
      export GOTOOLCHAIN=local
      export GOPROXY=off
      export GOSUMDB=off
      export GOFLAGS=-buildvcs=false

      cp -R "$src" source
      chmod -R u+w source
      cd source
      ${prepareTailscale}
      cp ${goModCache}/tailscale.go.mod appctr/tailscale_src/go.mod
      cp ${goModCache}/tailscale.go.sum appctr/tailscale_src/go.sum

      cp -R ${goModCache}/x-mobile x-mobile
      chmod -R u+w x-mobile
      substituteInPlace x-mobile/cmd/gomobile/init.go \
        --replace-fail 'if err := goInstall([]string{"golang.org/x/mobile/cmd/gobind@latest"}, nil); err != nil {' \
                       'if _, err := exec.LookPath("gobind"); err != nil {'
      patch -d x-mobile -p1 < ${../tailscale/gomobile-avoid-empty-go-mod.patch}
      (
        cd appctr
        go mod edit -replace=golang.org/x/mobile=../x-mobile
      )

      (cd x-mobile/cmd/gobind && go build -o "$GOBIN/gobind" .)
      (cd x-mobile/cmd/gomobile && go build -o "$GOBIN/gomobile" .)

      ts_commit="${tailscaleCommit}"
      app_commit="${appCommit}"
      version_ldflags="-X tailscale.com/version.shortStamp=${tailscaleVersion} -X tailscale.com/version.longStamp=${tailscaleVersion}-t''${ts_commit:0:9}-g''${app_commit:0:9} -X tailscale.com/version.gitCommitStamp=$ts_commit -X tailscale.com/version.extraGitCommitStamp=$app_commit"
      tags="ts_omit_systray,ts_omit_kube,ts_omit_aws,ts_omit_bird,ts_omit_qrcodes,ts_omit_desktop_sessions,ts_omit_dbus,ts_omit_networkmanager,ts_omit_resolved,ts_omit_sdnotify,ts_omit_tpm,ts_omit_logtail,ts_omit_synology,ts_omit_syspolicy,ts_omit_ssh,ts_omit_iptables,ts_omit_tap,ts_omit_linuxdnsfight,ts_omit_captiveportal,ts_omit_completion,ts_omit_completion_scripts,ts_omit_oauthkey,ts_omit_syslog,ts_omit_clientupdate,ts_omit_portlist,ts_omit_capture,ts_omit_debugportmapper,ts_omit_wakeonlan,ts_omit_serviceclientprefs,ts_omit_androidbin,ts_omit_androiddns,ts_omit_connreject"

      abi_goarch() { case $1 in armeabi-v7a) echo arm;; arm64-v8a) echo arm64;; x86) echo 386;; x86_64) echo amd64;; esac; }
      abi_clang() { case $1 in armeabi-v7a) echo armv7a-linux-androideabi21;; arm64-v8a) echo aarch64-linux-android21;; x86) echo i686-linux-android21;; x86_64) echo x86_64-linux-android21;; esac; }
      abi_suffix() { case $1 in armeabi-v7a) echo arm;; arm64-v8a) echo arm64;; x86) echo x86;; x86_64) echo x86_64;; esac; }

      mkdir -p appctr/tailscale_src/tmp appctr/tmp
      gomobile_targets=""
      for abi in armeabi-v7a arm64-v8a x86 x86_64; do
        goarch=$(abi_goarch "$abi")
        suffix=$(abi_suffix "$abi")
        gomobile_targets="''${gomobile_targets:+$gomobile_targets,}android/$goarch"
        export CC="${androidNdkRoot}/toolchains/llvm/prebuilt/linux-x86_64/bin/$(abi_clang "$abi")-clang"
        export CGO_ENABLED=1
        if [ "$goarch" = arm ]; then export GOARM=7; else unset GOARM; fi
        echo "-> Compiling tailscaled with the CLI [$abi]"
        (
          cd appctr/tailscale_src
          GOOS=android GOARCH=$goarch go build -v \
            -buildmode=pie \
            -trimpath \
            -tags "$tags,ts_include_cli" \
            -ldflags="-s -w -buildid= -checklinkname=0 $version_ldflags" \
            -o "tmp/libtailscale_$suffix.so" "./cmd/tailscaled"
        )
      done

      unset CC GOARM
      export CGO_ENABLED=1

      # gomobile's c-shared link resolves imports in GOPATH mode. A vendor tree
      # has one directory per import path; linking module-cache folders by
      # their module path nests packages inside each other and hides them.
      (
        cd appctr
        go mod vendor
      )
      # The x/mobile replace is outside the module, so vendor may symlink it
      # and drop bind/java/Seq.java. gobind reads that file from the vendored tree.
      test -f x-mobile/bind/java/Seq.java
      rm -rf appctr/vendor/golang.org/x/mobile
      mkdir -p appctr/vendor/golang.org/x
      cp -a x-mobile/. appctr/vendor/golang.org/x/mobile/
      rm -rf "$GOPATH/src"
      mkdir -p "$GOPATH/src"
      cp -a appctr/vendor/. "$GOPATH/src/"
      rm -rf "$GOPATH/src/tailscale.com" "$GOPATH/src/appctr" "$GOPATH/src/golang.org/x/mobile"
      mkdir -p "$GOPATH/src/golang.org/x"
      ln -sfn "$PWD/x-mobile" "$GOPATH/src/golang.org/x/mobile"
      ln -sfn "$PWD/appctr/tailscale_src" "$GOPATH/src/tailscale.com"
      ln -sfn "$PWD/appctr" "$GOPATH/src/appctr"
      # vendor/modules.txt hides bind/java, which gobind imports. Module mode
      # with the x/mobile replace sees the full tree.
      rm -rf appctr/vendor

      # android-nixpkgs names the platform android-37.0. gomobile only accepts android-N.
      sdkwrap="$TMPDIR/android-sdk"
      mkdir -p "$sdkwrap/platforms"
      ln -s "${androidSdkRoot}/build-tools" "$sdkwrap/build-tools"
      ln -s "${androidSdkRoot}/platform-tools" "$sdkwrap/platform-tools"
      ln -s "${androidSdkRoot}/ndk" "$sdkwrap/ndk"
      ln -s "${androidSdkRoot}/platforms/android-37.0" "$sdkwrap/platforms/android-37"
      export ANDROID_HOME="$sdkwrap"
      export ANDROID_SDK_ROOT="$sdkwrap"

      (
        cd appctr
        gomobile init
        gomobile bind \
          -ldflags="-s -w -buildid= -checklinkname=0 -X appctr.coreVersion=v${tailscaleVersion}-${
            builtins.substring 0 7 appCommit
          }-${appCommitTime} $version_ldflags" \
          -trimpath \
          -target="$gomobile_targets" \
          -androidapi 21 \
          -tags "$tags" \
          -o tmp/appctr.aar \
          -v \
          .
      )

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm644 appctr/tmp/appctr.aar "$out/appctr.aar"
      abi_suffix() { case $1 in armeabi-v7a) echo arm;; arm64-v8a) echo arm64;; x86) echo x86;; x86_64) echo x86_64;; esac; }
      for abi in armeabi-v7a arm64-v8a x86 x86_64; do
        suffix=$(abi_suffix "$abi")
        install -Dm755 "appctr/tailscale_src/tmp/libtailscale_$suffix.so" "$out/jniLibs/$abi/libtailscale.so"
      done
      runHook postInstall
    '';
  };

  appPackage = buildGradlePackage rec {
    pname = "tailsocks";
    inherit src version;
    inherit gradle;

    lockFile = ./gradle.lock;
    # From-source kotlinx-serialization is compiled without its compiler plugin,
    # so library calls such as JsonElement.serializer() are absent.
    overrides = removeAttrs overrides-fromsrc [
      "org.jetbrains.kotlinx:kotlinx-serialization-core:1.7.3"
      "org.jetbrains.kotlinx:kotlinx-serialization-core-jvm:1.7.3"
      "org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.3"
      "org.jetbrains.kotlinx:kotlinx-serialization-json-jvm:1.7.3"
    ];
    buildJdk = jdk25_headless;

    passthru = {
      inherit goModCache appctrArtifacts;
    };

    nativeBuildInputs = [
      androidSdk
      gradle
      jdk25_headless
      writableTmpDirAsHomeHook
    ];

    env = {
      JAVA_HOME = jdk25_headless.passthru.home;
      ANDROID_HOME = androidSdkRoot;
      ANDROID_SDK_ROOT = androidSdkRoot;
      ANDROID_NDK_HOME = androidNdkRoot;
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = aapt2;
    };

    gradleFlags = [
      "-Dorg.gradle.java.home=${jdk25_headless.passthru.home}"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk25_headless.passthru.home}"
      "-Dandroid.aapt2FromMavenOverride=${aapt2}"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${aapt2}"
      "-Dandroid.builder.sdkDownload=false"
      "-PupdateCheckDefault=false"
      "-PselfUpdate=false"
      # mk-apk-package signs afterwards. Upstream refuses an unsigned release
      # unless this property is set.
      "-PallowUnsignedRelease"
    ];

    gradleBuildFlags = ":app:assembleRelease";

    preConfigure = ''
      export ANDROID_USER_HOME="$HOME/.android"
      export GRADLE_USER_HOME="$HOME/.gradle"
      mkdir -p "$ANDROID_USER_HOME" "$GRADLE_USER_HOME"
      echo "sdk.dir=${androidSdkRoot}" > local.properties
      gradleFlagsArray+=(--no-daemon --init-script "$gradleInitScript" --offline)

      rm -rf app/src/main/jni/hev-socks5-tunnel
      mkdir -p app/src/main/jni/hev-socks5-tunnel
      cp -R ${hevSocks5Tunnel}/. app/src/main/jni/hev-socks5-tunnel/
      chmod -R u+w app/src/main/jni/hev-socks5-tunnel

      mkdir -p appctr/tmp app/src/main/jniLibs
      install -Dm644 ${appctrArtifacts}/appctr.aar appctr/tmp/appctr.aar
      # verifyGoBridgeFresh compares mtimes. Nix store files keep upstream
      # timestamps, so force the prebuilt bridge to sort after every source.
      touch -d @4102444800 appctr/tmp/appctr.aar
      cp -a ${appctrArtifacts}/jniLibs/. app/src/main/jniLibs/

      substituteInPlace app/build.gradle.kts \
        --replace-fail 'commandLine("git", "rev-parse", "--short=6", "HEAD")' 'commandLine("echo", "${
          builtins.substring 0 6 appCommit
        }")'
      # AGP 8.13.2 defaults to build-tools 35, which is not in this SDK.
      substituteInPlace app/build.gradle.kts \
        --replace-fail '    compileSdk = 37' '    compileSdk = 37; buildToolsVersion = "36.0.0"'
    '';

    installPhase = ''
      runHook preInstall
      apk="$(echo app/build/outputs/apk/release/*universal*release*.apk)"
      install -Dm644 "$apk" "$out/tailsocks.apk"
      runHook postInstall
    '';

    meta = with lib; {
      sourceProvenance = with sourceTypes; [ fromSource ];
      description = "Unofficial Tailscale client for Android";
      homepage = "https://github.com/bropines/tailsocks";
      license = licenses.gpl3Only;
      platforms = platforms.unix;
    };
  };
in
mk-apk-package {
  inherit appPackage;
  mainApk = "tailsocks.apk";
  signScriptName = "sign-tailsocks";
  fdroid = {
    appId = "io.github.bropines.tailscaled";
    metadataYml = ''
      Categories:
        - Connectivity
      License: GPL-3.0-only
      SourceCode: https://github.com/bropines/tailsocks
      IssueTracker: https://github.com/bropines/tailsocks/issues
      AutoName: Tailsocks
      Summary: Unofficial Tailscale client
      Description: |-
        Unofficial Tailscale client for Android, built from source.
    '';
  };
}
