{
  mk-apk-package,
  lib,
  pkgs,
  jdk21_headless,
  gradle_9_3_1,
  stdenv,
  stdenvNoCC,
  fetchFromGitHub,
  rustPlatform,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  git,
  go_1_26,
  python313,
  unzip,
}:
let
  appPackage = stdenv.mkDerivation (
    finalAttrs0:
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-36
        s.build-tools-36-0-0
        s.build-tools-35-0-0
        s.ndk-29-0-14206865
        s.cmake-3-31-6
      ]);
      androidSdkRoot = "${androidSdk}/share/android-sdk";
      androidNdkRoot = "${androidSdkRoot}/ndk/29.0.14206865";
      aapt2 = "${androidSdkRoot}/build-tools/36.0.0/aapt2";

      gradle = gradle_9_3_1;

      xMobileSrc = fetchFromGitHub {
        owner = "golang";
        repo = "mobile";
        rev = "81488f6aeb60";
        hash = "sha256-LIFK+KQPgpzZqh7U92fEnCSHBSVF8HPv9lIVhWy5xBo=";
      };

      androidCrossConfig = {
        config.allowUnfree = true;
        localSystem = pkgs.stdenv.buildPlatform.system;
      };

      mkAndroidPkgs =
        {
          config,
          rustTarget,
        }:
        import pkgs.path (
          androidCrossConfig
          // {
            crossSystem = {
              inherit config;
              androidSdkVersion = "35";
              androidNdkVersion = "29";
              useAndroidPrebuilt = true;
              rust.rustcTarget = rustTarget;
            };
          }
        );

      aarch64AndroidPkgs = mkAndroidPkgs {
        config = "aarch64-unknown-linux-android";
        rustTarget = "aarch64-linux-android";
      };

      x86_64AndroidPkgs = mkAndroidPkgs {
        config = "x86_64-unknown-linux-android";
        rustTarget = "x86_64-linux-android";
      };

      rdpCargoDeps = rustPlatform.fetchCargoVendor {
        pname = "haven-rdp-transport-jni-libs";
        inherit (finalAttrs0) version src;
        cargoRoot = "rdp-kotlin/rust";
        hash = "sha256-EIAn9ooDfj0MTRe+fV3ZkMvAZvuMeP3Nf5Vvfb56aD4=";
      };

      mkRdpTransportJniLib =
        {
          crossPkgs,
          rustTarget,
          abi,
        }:
        crossPkgs.rustPlatform.buildRustPackage {
          pname = "haven-rdp-transport-jni-lib-${abi}";
          inherit (finalAttrs0) version src;

          sourceRoot = "${finalAttrs0.src.name}/rdp-kotlin/rust";
          cargoDeps = rdpCargoDeps;

          CARGO_BUILD_TARGET = rustTarget;
          doCheck = false;

          env = {
            ANDROID_HOME = androidSdkRoot;
            ANDROID_SDK_ROOT = androidSdkRoot;
            ANDROID_NDK_ROOT = androidNdkRoot;
            ANDROID_NDK_HOME = androidNdkRoot;
          };

          installPhase = ''
            runHook preInstall
            install -Dm755 target/${rustTarget}/release/librdp_transport.so \
              "$out/${abi}/librdp_transport.so"
            runHook postInstall
          '';
        };

      rdpTransportJniLibs = pkgs.symlinkJoin {
        name = "haven-rdp-transport-jni-libs";
        paths = [
          (mkRdpTransportJniLib {
            crossPkgs = aarch64AndroidPkgs;
            rustTarget = "aarch64-linux-android";
            abi = "arm64-v8a";
          })
          (mkRdpTransportJniLib {
            crossPkgs = x86_64AndroidPkgs;
            rustTarget = "x86_64-linux-android";
            abi = "x86_64";
          })
        ];
      };

      prepareXMobile = replacement: ''
        cp -R ${xMobileSrc} x-mobile
        chmod -R u+w x-mobile
        substituteInPlace x-mobile/cmd/gomobile/init.go \
          --replace-fail 'if err := goInstall([]string{"golang.org/x/mobile/cmd/gobind@latest"}, nil); err != nil {' \
                         'if _, err := exec.LookPath("gobind"); err != nil {'
        patch -d x-mobile -p1 < ${../tailscale/gomobile-avoid-empty-go-mod.patch}
        (cd go && go mod edit -replace=golang.org/x/mobile=${replacement})
      '';

      rcloneGoModCache = stdenvNoCC.mkDerivation {
        pname = "haven-rclone-go-mod-cache";
        inherit (finalAttrs0) version src;

        nativeBuildInputs = [ go_1_26 ];

        outputHashMode = "recursive";
        outputHashAlgo = "sha256";
        outputHash = "sha256-bOB7/2FWasLfSOhKK0s5q5HKmHXoX/gPtWzUdwR3v1M=";

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
          export GOSUMDB=off

          cp -R "$src" source
          chmod -R u+w source
          cd source/rclone-android

          ${prepareXMobile "../x-mobile"}
          cd go
          go mod download

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          rm -rf "$TMPDIR/go-mod-cache/cache/download/sumdb"
          chmod -R u+w "$TMPDIR/go-mod-cache"
          mv "$TMPDIR/go-mod-cache" "$out"
          runHook postInstall
        '';
      };

      rcloneTransportJniLibs = stdenv.mkDerivation {
        pname = "haven-rclone-transport-jni-libs";
        inherit (finalAttrs0) version src;

        nativeBuildInputs = [
          go_1_26
          jdk21_headless
          unzip
        ];

        dontConfigure = true;

        env = {
          JAVA_HOME = jdk21_headless.passthru.home;
          ANDROID_HOME = androidSdkRoot;
          ANDROID_SDK_ROOT = androidSdkRoot;
          ANDROID_NDK_ROOT = androidNdkRoot;
          ANDROID_NDK_HOME = androidNdkRoot;
        };

        preBuild = ''
          export HOME="$TMPDIR/home"
          mkdir -p "$HOME"

          export GOCACHE="$TMPDIR/go-cache"
          export GOPATH="$TMPDIR/go"
          export GOMODCACHE="$PWD/.gomodcache"
          mkdir -p "$GOCACHE" "$GOPATH"
          cp -R ${rcloneGoModCache} "$GOMODCACHE"
          chmod -R u+w "$GOMODCACHE"
          export GOPROXY=off
          export GOSUMDB=off
        '';

        buildPhase = ''
          runHook preBuild

          export GOBIN="$TMPDIR/go-bin"
          mkdir -p "$GOBIN"
          export PATH="$GOBIN:${go_1_26}/bin:$PATH"

          cd rclone-android
          ${prepareXMobile "../x-mobile"}
          cd go
          go install golang.org/x/mobile/cmd/gobind
          go install golang.org/x/mobile/cmd/gomobile
          go mod vendor
          cd ../..

          mkdir -p "$GOPATH/src/sh.haven" "$GOPATH/src/golang.org/x"
          ln -s "$PWD/rclone-android/go" "$GOPATH/src/sh.haven/rcbridge"
          ln -s "$PWD/rclone-android/x-mobile" "$GOPATH/src/golang.org/x/mobile"
          cp -R rclone-android/go/vendor/. "$GOPATH/src/"

          mkdir -p rclone-android/jniLibs rclone-android/build
          cd rclone-android/go

          export GO111MODULE=off
          gomobile init
          gomobile bind \
            -target=android/arm64,android/amd64 \
            -javapkg=sh.haven.rclone.binding \
            -androidapi=26 \
            -o ../build/rcbridge.aar \
            sh.haven/rcbridge

          cd ..
          unzip -o build/rcbridge.aar "jni/*" -d build/extracted

          install -Dm755 build/extracted/jni/arm64-v8a/libgojni.so jniLibs/arm64-v8a/libgojni.so
          install -Dm755 build/extracted/jni/x86_64/libgojni.so jniLibs/x86_64/libgojni.so

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          install -Dm755 build/extracted/jni/arm64-v8a/libgojni.so "$out/arm64-v8a/libgojni.so"
          install -Dm755 build/extracted/jni/x86_64/libgojni.so "$out/x86_64/libgojni.so"
          runHook postInstall
        '';
      };
    in
    {
      pname = "haven";
      version = "5.5.1";

      src = fetchFromGitHub {
        owner = "GlassOnTin";
        repo = "Haven";
        tag = "v${finalAttrs0.version}";
        fetchSubmodules = true;
        hash = "sha256-4rRHbQrUmQK4BaG9uMGwJWelGL+QLvBIlO+z+tfuI4c=";
      };

      patches = [
        # Build unsigned APK (no keystore in sandbox)
        ./remove-signing-config.patch
        # Override AGP's default NDK selection for the native local module.
        ./set-ndk-version.patch
        # Build the Rust JNI libraries in Nix instead of invoking cargo-ndk from Gradle.
        ./skip-gradle-rdp-native-build.patch
      ];

      gradleBuildTask = ":app:assembleArm64Release";
      gradleUpdateTask = finalAttrs0.gradleBuildTask;

      # $(nix build .#apk_haven.mitmCache.updateScript --no-link --print-out-paths)
      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs0) pname;
        pkg = finalAttrs0.finalPackage;
        data = ./haven_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk21_headless
        writableTmpDirAsHomeHook
        git
        python313
        go_1_26
        unzip
      ];

      env = {
        JAVA_HOME = jdk21_headless;
        ANDROID_HOME = androidSdkRoot;
        ANDROID_SDK_ROOT = androidSdkRoot;
        ANDROID_NDK_ROOT = androidNdkRoot;
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = aapt2;
        HAVEN_SKIP_PYTHON_REQUIREMENTS = "1";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdkRoot}" > local.properties

        mkdir -p rdp-kotlin/jniLibs
        cp -r ${rdpTransportJniLibs}/. rdp-kotlin/jniLibs/

        mkdir -p rclone-android/jniLibs
        cp -r ${rcloneTransportJniLibs}/. rclone-android/jniLibs/

        # When running in mitmCache dependency-fetch mode, configure pip (used by
        # Chaquopy) to trust the mitm proxy certificate so PyPI downloads are captured.
        if [[ -n "''${MITM_CACHE_CA:-}" ]]; then
          export PIP_CERT="$MITM_CACHE_CA"
          export REQUESTS_CA_BUNDLE="$MITM_CACHE_CA"
          export SSL_CERT_FILE="$MITM_CACHE_CA"
          export PIP_PROXY="http://''${MITM_CACHE_ADDRESS}"
          export HTTPS_PROXY="http://''${MITM_CACHE_ADDRESS}"
          export HTTP_PROXY="http://''${MITM_CACHE_ADDRESS}"
          export https_proxy="http://''${MITM_CACHE_ADDRESS}"
          export http_proxy="http://''${MITM_CACHE_ADDRESS}"
          export ALL_PROXY="http://''${MITM_CACHE_ADDRESS}"
          export all_proxy="http://''${MITM_CACHE_ADDRESS}"
          export NO_PROXY=""
          export no_proxy=""
        fi
      '';

      preBuild = lib.optionalString stdenv.isDarwin ''
        # AGP writes SDK metadata under ~/.android; /var/empty is read-only on Darwin sandboxes.
        export ANDROID_USER_HOME="$HOME/.android"
        export GRADLE_USER_HOME="$HOME/.gradle"
        mkdir -p "$ANDROID_USER_HOME" "$GRADLE_USER_HOME"
        export GRADLE_OPTS="''${GRADLE_OPTS:+$GRADLE_OPTS }-Duser.home=$HOME"
      '';

      gradleFlags = [
        "-xlintVitalRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk21_headless}"
        "-Dandroid.aapt2FromMavenOverride=${aapt2}"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${aapt2}"
      ];

      installPhase = ''
        runHook preInstall
        apk_path="$(echo app/build/outputs/apk/arm64/release/haven-*-arm64-release.apk)"
        install -Dm644 "$apk_path" "$out/haven.apk"
        runHook postInstall
      '';

      meta = with lib; {
        description = "Haven – SSH/Mosh terminal and Reticulum network client for Android";
        homepage = "https://github.com/GlassOnTin/Haven";
        license = licenses.gpl3Only;
        platforms = platforms.unix;
      };
    }
  );
in
mk-apk-package {
  inherit appPackage;
  mainApk = "haven.apk";
  signScriptName = "sign-haven";
  fdroid = {
    appId = "sh.haven.app";
    metadataYml = ''
      Categories:
        - Internet
        - System
      License: GPL-3.0-only
      SourceCode: https://github.com/GlassOnTin/Haven
      IssueTracker: https://github.com/GlassOnTin/Haven/issues
      AutoName: Haven
      Summary: SSH/Mosh terminal and Reticulum network client
      Description: |-
        Haven is an SSH/Mosh terminal and Reticulum network client for Android,
        featuring end-to-end encrypted messaging via the Reticulum stack.
        This package is built from source (arm64).
    '';
  };
}
