{
  mk-apk-package,
  lib,
  stdenv,
  stdenvNoCC,
  fetchFromGitHub,
  androidSdkBuilder,
  gradle_8_7,
  go_1_26,
  jdk17_headless,
  writableTmpDirAsHomeHook,
  gnumake,
  zip,
  unzip,
  fetchpatch,
}:
let
  appPackage =
    let
      version = "1.100.0-td727cb81f-ge7966699a";
      tailscaleVersion = lib.head (lib.splitString "-" version);

      src = fetchFromGitHub {
        owner = "tailscale";
        repo = "tailscale-android";
        tag = version;
        hash = "sha256-sjNk+YSG2/9MOPPUDIJgp2VuFqChyI5bQO6FSLiGrLA=";
      };

      xMobileSrc = fetchFromGitHub {
        owner = "golang";
        repo = "mobile";
        # https://github.com/tailscale/tailscale-android/blob/5c5030c5434dc465d1e277b19222456544553482/go.mod#L7
        rev = "81131f6468ab";
        hash = "sha256-/WelLIFKCHuMZnRnaWFvBo8wZB33fRJurbbFEs16tG0=";
      };

      goModCache = stdenvNoCC.mkDerivation {
        pname = "tailscale-go-mod-cache";
        inherit version src;

        nativeBuildInputs = [ go_1_26 ];

        outputHashMode = "recursive";
        outputHashAlgo = "sha256";
        outputHash = "sha256-G8wHMWAuHqK4XeJsjEzqOW8iBRuasy+pEBOqh38PVO8=";

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

          cp -R ${xMobileSrc} x-mobile
          chmod -R u+w x-mobile
          patch -d x-mobile -p1 < ${./gomobile-avoid-empty-go-mod.patch}
          go mod edit -replace=golang.org/x/mobile=./x-mobile

          go mod download

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          chmod -R u+w "$TMPDIR/go-mod-cache"
          mv "$TMPDIR/go-mod-cache" "$out"
          runHook postInstall
        '';
      };

      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-34
        s.build-tools-34-0-0
        s.ndk-27-3-13750724
      ]);

      gradle = gradle_8_7;
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "tailscale";
      inherit version src;

      passthru = {
        inherit goModCache;
      };

      patches = [
        (fetchpatch {
          name = "Fix/restart vpn state bug";
          url = "https://github.com/tailscale/tailscale-android/pull/730.diff";
          hash = "sha256-1thWUOONa0HZLXAK4Z0tJ2AmbLJrNATJn6Y7UmN6Yvg=";
        })
      ];

      gradleBuildTask = "assembleRelease";
      gradleUpdateTask = finalAttrs.gradleBuildTask;

      mitmCache = gradle.fetchDeps {
        pname = "tailscale";
        pkg = finalAttrs.finalPackage;
        data = ./tailscale_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        go_1_26
        gnumake
        jdk17_headless
        writableTmpDirAsHomeHook
        zip
        unzip
      ];

      env = {
        JAVA_HOME = jdk17_headless.passthru.home;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/27.3.13750724";
        NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/27.3.13750724";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2";
      };

      preBuild = ''
        export HOME="$PWD/.home"
        mkdir -p "$HOME/.android" "$HOME/.cache"

        patchShebangs tool build-tags.sh version-ldflags.sh

        export GOCACHE="$TMPDIR/go-cache"
        export GOPATH="$TMPDIR/go"
        export GOMODCACHE="$PWD/.gomodcache"
        cp -R ${goModCache} "$GOMODCACHE"
        chmod -R u+w "$GOMODCACHE"
        export GOPROXY=off
        export GOSUMDB=off
        export GOTOOLCHAIN=local

        # nixpkgs currently has Go 1.26.2; upstream's 1.26.4 directive makes
        # Go try to resolve the toolchain module, which cannot be verified
        # with GOSUMDB disabled in the offline build.
        substituteInPlace go.mod --replace-fail 'go 1.26.4' 'go 1.26.2'
        find "$GOMODCACHE" -name go.mod -print | while read -r gomod; do
          if grep -q '^go 1\.26\.4$' "$gomod"; then
            substituteInPlace "$gomod" --replace-fail 'go 1.26.4' 'go 1.26.2'
          fi
        done

        unzip -q "$GOMODCACHE/cache/download/tailscale.com/@v/v${tailscaleVersion}.zip" -d tailscale-module-tmp
        mv "tailscale-module-tmp/tailscale.com@v${tailscaleVersion}" tailscale-module
        rm -rf tailscale-module-tmp
        chmod -R u+w tailscale-module
        substituteInPlace tailscale-module/go.mod --replace-fail 'go 1.26.4' 'go 1.26.2'
        go mod edit -replace=tailscale.com=./tailscale-module

        cp -R ${xMobileSrc} x-mobile
        chmod -R u+w x-mobile
        patch -d x-mobile -p1 < ${./gomobile-avoid-empty-go-mod.patch}
        go mod edit -replace=golang.org/x/mobile=./x-mobile

        export TOOLCHAINDIR="${go_1_26}/share/go"
        export TOOLCHAIN_DIR="$TOOLCHAINDIR"
        export PATH="$TOOLCHAINDIR/bin:$PATH"

        # gomobile still falls back to GOPATH-style package resolution while
        # building the generated gobind wrapper. Mirror the resolved module graph
        # into GOPATH/src so those imports remain available in GOPATH mode.
        mkdir -p "$GOPATH/src/github.com/tailscale" "$GOPATH/src/golang.org/x"
        ln -s "$PWD" "$GOPATH/src/github.com/tailscale/tailscale-android"
        ln -s "$PWD/tailscale-module" "$GOPATH/src/tailscale.com"
        ln -s "$PWD/x-mobile" "$GOPATH/src/golang.org/x/mobile"
        find "$GOMODCACHE" -name go.mod -print | while read -r gomod; do
          module_dir="$(dirname "$gomod")"
          rel_path="''${module_dir#$GOMODCACHE/}"
          module_path="''${rel_path%@*}"
          case "$module_path" in
            golang.org/toolchain*) continue ;;
          esac
          mkdir -p "$GOPATH/src/$(dirname "$module_path")"
          if [ ! -e "$GOPATH/src/$module_path" ]; then
            ln -s "$module_dir" "$GOPATH/src/$module_path"
          fi
        done

        cat > tailscale.version <<EOF
        VERSION_LONG="${version}"
        VERSION_SHORT="${version}"
        VERSION_GIT_HASH=""
        VERSION_EXTRA_HASH=""
        EOF

        cat > android/local.properties <<EOF
        sdk.dir=${androidSdk}/share/android-sdk
        EOF

        substituteInPlace android/build.gradle \
          --replace-fail 'ndkVersion "23.1.7779620"' 'ndkVersion "27.3.13750724"'
        substituteInPlace android/build.gradle \
          --replace-fail 'versionCode 468' 'versionCode 576'

        substituteInPlace Makefile \
          --replace-fail 'ndk;23.1.7779620' 'ndk;27.3.13750724'

        echo "org.gradle.jvmargs=-Xmx4096m" >> android/gradle.properties
        cat >> android/gradle.properties <<EOF
        android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2
        org.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2
        EOF

        make env
        make libtailscale
      '';

      gradleFlags = [
        "-xlintVitalRelease"
        "-p"
        "android"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
      ];

      installPhase = ''
        runHook preInstall
        install -Dm644 android/build/outputs/apk/release/android-release-unsigned.apk "$out/tailscale.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Tailscale Android client built from source";
        homepage = "https://github.com/tailscale/tailscale-android";
        license = licenses.bsd3;
        platforms = platforms.unix;
      };
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "tailscale.apk";
  signScriptName = "sign-tailscale";
  fdroid = {
    appId = "com.tailscale.ipn";
    metadataYml = ''
      Categories:
        - Internet
      License: BSD-3-Clause
      WebSite: https://tailscale.com/
      SourceCode: https://github.com/tailscale/tailscale-android
      IssueTracker: https://github.com/tailscale/tailscale-android/issues
      Changelog: https://github.com/tailscale/tailscale-android/releases
      AutoName: Tailscale
      Summary: Mesh VPN client
      Description: |-
        Tailscale is a mesh VPN client for connecting devices over a
        private WireGuard-based network.
        This package is built from source from the upstream
        tailscale-android repository.
    '';
  };
}
