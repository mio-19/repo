{
  mk-apk-package,
  lib,
  stdenvNoCC,
  gradle_9_3_1,
  jdk25_headless,
  go_1_26,
  stdenv,
  fetchFromGitHub,

  writableTmpDirAsHomeHook,
  androidSdkBuilder,
}:
let
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-36
        s.build-tools-36-0-0
        s.platforms-android-35
        s.build-tools-35-0-0
        s.ndk-28-2-13676358
      ]);

      gradle = gradle_9_3_1;

      androidLibXrayLiteSrc = fetchFromGitHub {
        owner = "2dust";
        repo = "AndroidLibXrayLite";
        rev = "880725442c1d4023a973ccbcdbf527c89ef83a32";
        hash = "sha256-TLKqh2/mPagul4Lgmx+kKCQw7TAKaZnBJJlq55a9no0=";
      };

      androidLibXrayLiteGoModCache = stdenvNoCC.mkDerivation {
        pname = "android-lib-xray-lite-go-mod-cache";
        version = "26.3.27";
        src = androidLibXrayLiteSrc;

        nativeBuildInputs = [ go_1_26 ];

        outputHashMode = "recursive";
        outputHashAlgo = "sha256";
        outputHash = "sha256-c0W+2Sxn9PDv2ZGEwDoASp8wl1h9l0ydooLlBwFyTHQ=";

        dontConfigure = true;
        dontFixup = true;

        buildPhase = ''
          runHook preBuild

          export HOME="$TMPDIR/home"
          mkdir -p "$HOME"
          export GOPATH="$TMPDIR/go"
          export GOCACHE="$TMPDIR/go-build-cache"
          export GOMODCACHE="$TMPDIR/go-mod-cache"
          export GOPROXY=https://proxy.golang.org,direct
          export GOSUMDB=sum.golang.org

          cp -R "$src" source
          chmod -R u+w source
          cd source
          go mod download

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          cp -R "$TMPDIR/go-mod-cache" "$out"
          runHook postInstall
        '';
      };

      libv2rayAar = stdenv.mkDerivation {
        pname = "android-lib-xray-lite-aar";
        version = "26.3.27";
        src = androidLibXrayLiteSrc;

        nativeBuildInputs = [
          go_1_26
          jdk25_headless
          writableTmpDirAsHomeHook
        ];

        env = {
          JAVA_HOME = jdk25_headless;
          ANDROID_HOME = "${androidSdk}/share/android-sdk";
          ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
          ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk/28.2.13676358";
        };

        buildPhase = ''
          runHook preBuild

          export HOME="$TMPDIR/home"
          mkdir -p "$HOME/.android"
          export GOPATH="$TMPDIR/go"
          export GOCACHE="$TMPDIR/go-cache"
          export GOMODCACHE="$PWD/.gomodcache"
          cp -R ${androidLibXrayLiteGoModCache} "$GOMODCACHE"
          chmod -R u+w "$GOMODCACHE"
          export GOPROXY=off
          export GOSUMDB=off
          export GOFLAGS="-mod=mod"

          xMobileDir="$(find "$GOMODCACHE" -type d -path '*/golang.org/x/mobile@*' -print -quit)"
          test -n "$xMobileDir"
          cp -R "$xMobileDir" ./x-mobile
          chmod -R u+w ./x-mobile
          substituteInPlace x-mobile/cmd/gomobile/init.go \
            --replace-fail 'if err := goInstall([]string{"golang.org/x/mobile/cmd/gobind@latest"}, nil); err != nil {' \
                           'if _, err := exec.LookPath("gobind"); err != nil {'
          patch -d x-mobile -p1 < ${../tailscale/gomobile-avoid-empty-go-mod.patch}
          go mod edit -replace=golang.org/x/mobile=./x-mobile
          go mod vendor

          gomobileBin="$PWD/gomobile-bin"
          gobindBin="$PWD/gobind-bin"
          (cd ./x-mobile && go build -o "$gomobileBin" ./cmd/gomobile)
          (cd ./x-mobile && go build -o "$gobindBin" ./cmd/gobind)
          mkdir -p "$GOPATH/bin" "$GOPATH/pkg/gomobile" "$GOPATH/src/github.com/2dust" "$GOPATH/src/golang.org/x"
          install -m755 "$gobindBin" "$GOPATH/bin/gobind"
          ln -s "$PWD" "$GOPATH/src/github.com/2dust/AndroidLibXrayLite"
          ln -s "$PWD/x-mobile" "$GOPATH/src/golang.org/x/mobile"
          rm -rf vendor/golang.org/x/mobile
          cp -R vendor/. "$GOPATH/src/"
          find "$GOMODCACHE" -name go.mod -print | while read -r gomod; do
            module_dir="$(dirname "$gomod")"
            rel_path="''${module_dir#$GOMODCACHE/}"
            module_path="''${rel_path%@*}"
            mkdir -p "$GOPATH/src/$(dirname "$module_path")"
            if [ ! -e "$GOPATH/src/$module_path" ]; then
              ln -s "$module_dir" "$GOPATH/src/$module_path"
            fi
          done
          export PATH="$GOPATH/bin:$PATH"
          "$gomobileBin" bind -x -v -androidapi 24 -trimpath -ldflags='-s -w -buildid=' ./

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          install -Dm644 libv2ray.aar "$out/libv2ray.aar"
          runHook postInstall
        '';
      };
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "v2rayng";
      version = "2.0.18";

      src = fetchFromGitHub {
        owner = "2dust";
        repo = "v2rayNG";
        tag = finalAttrs.version;
        fetchSubmodules = true;
        hash = "sha256-7lY5qC7zhvlDWEF+WNU3N0I5d1UdZ5aii8OCZmwiHcs=";
      };

      sourceRoot = "${finalAttrs.src.name}/V2rayNG";

      gradleBuildTask = ":app:assembleFdroidRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = ./v2rayng_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk25_headless

        writableTmpDirAsHomeHook
      ];

      env = {
        JAVA_HOME = jdk25_headless;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
        mkdir -p app/libs
        cp ${libv2rayAar}/libv2ray.aar app/libs/libv2ray.aar
      '';

      postPatch = ''
        pluginResolutionBlock=$'pluginManagement {\n    resolutionStrategy {\n        eachPlugin {\n            if (requested.id.id == "com.android.application" || requested.id.id == "com.android.library") {\n                val agpVersion = requested.version ?: "9.1.0"\n                useModule("com.android.tools.build:gradle:$agpVersion")\n            }\n            if (requested.id.id == "org.jetbrains.kotlin.android") {\n                val kotlinVersion = requested.version ?: "2.3.10"\n                useModule("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")\n            }\n        }\n    }\n'
        substituteInPlace settings.gradle.kts \
          --replace-fail "pluginManagement {" "$pluginResolutionBlock"
      '';

      gradleFlags = [
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk25_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        apk_dir="app/build/outputs/apk/fdroid/release"
        apk_name="$(sed -n 's/.*"outputFile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$apk_dir/output-metadata.json" | head -n 1)"
        test -n "$apk_name"
        apk_path="$apk_dir/$apk_name"
        test -f "$apk_path"
        install -Dm644 "$apk_path" "$out/v2rayng.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "v2rayNG Android client built from source";
        homepage = "https://github.com/2dust/v2rayNG";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "v2rayng.apk";
  signScriptName = "sign-v2rayng";
  fdroid = {
    appId = "com.v2ray.ang.fdroid";
    metadataYml = ''
      Categories:
        - Internet
      License: GPL-3.0-only
      SourceCode: https://github.com/2dust/v2rayNG
      IssueTracker: https://github.com/2dust/v2rayNG/issues
      Changelog: https://github.com/2dust/v2rayNG/releases
      AutoName: v2rayNG
      Summary: V2Ray/Xray client for Android
      Description: |-
        v2rayNG is an Android client for V2Ray and Xray cores.
        This package builds the upstream F-Droid flavor from source.
    '';
  };
}
