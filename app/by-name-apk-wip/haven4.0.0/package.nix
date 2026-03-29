{
  mk-apk-package,
  lib,
  jdk17_headless,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  rustPlatform,
  patchelf,
  zlib,
  apksigner,
  writableTmpDirAsHomeHook,
  androidSdkBuilder,
  git,
  cargo-ndk,
  python313,
  go,
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
        s.ndk-27-3-13750724
        s.cmake-3-31-6
      ]);

      gradle =
        (gradle-packages.mkGradle {
          version = "8.11.1";
          hash = "sha256-85eyhwI6zboen2/F6nLSLdY2adWe1KKJopsadu7hUcY=";
          defaultJava = jdk17_headless;
        }).wrapped;

      rustStdAarch64Android = fetchurl {
        url = "https://static.rust-lang.org/dist/rust-std-1.94.0-aarch64-linux-android.tar.xz";
        hash = "sha256-QCyA32cqS5/JSLbci94hpj4Qk+sciiwr1CIhwwnZ66I=";
      };

      rustStdHost = fetchurl {
        url = "https://static.rust-lang.org/dist/rust-std-1.94.0-x86_64-unknown-linux-gnu.tar.xz";
        hash = "sha256-3TNlMQfDbgQAggUNnlR+ZNrFtFa6dAaUMNg4wAwYmgU=";
      };

      rustStdX8664Android = fetchurl {
        url = "https://static.rust-lang.org/dist/rust-std-1.94.0-x86_64-linux-android.tar.xz";
        hash = "sha256-SIyKWBYSrEd5oF8Flnt2qW4P8L3Rq42ZwTqFnBkFawE=";
      };

      rustcOfficial = fetchurl {
        url = "https://static.rust-lang.org/dist/rustc-1.94.0-x86_64-unknown-linux-gnu.tar.xz";
        hash = "sha256-MaDTrJOD3960/Ohu7tWt4yMBMcY1JkwOq3JS2/I18o4=";
      };

      cargoOfficial = fetchurl {
        url = "https://static.rust-lang.org/dist/cargo-1.94.0-x86_64-unknown-linux-gnu.tar.xz";
        hash = "sha256-jhdiTz3jngeYRb+yXtFaBC9LUM7KeON8VsS5sVlJufc=";
      };

      setupOfficialRustToolchain = ''
        rustToolchain="$TMPDIR/rust-toolchain"
        mkdir -p "$rustToolchain"

        mkdir -p "$TMPDIR/rustc-official" "$TMPDIR/cargo-official" "$TMPDIR/rust-std-host" "$TMPDIR/rust-std-aarch64" "$TMPDIR/rust-std-x86_64"
        tar -xJf ${rustcOfficial} -C "$TMPDIR/rustc-official"
        tar -xJf ${cargoOfficial} -C "$TMPDIR/cargo-official"
        tar -xJf ${rustStdHost} -C "$TMPDIR/rust-std-host"
        tar -xJf ${rustStdAarch64Android} -C "$TMPDIR/rust-std-aarch64"
        tar -xJf ${rustStdX8664Android} -C "$TMPDIR/rust-std-x86_64"

        bash "$TMPDIR/rustc-official"/rustc-1.94.0-x86_64-unknown-linux-gnu/install.sh \
          --prefix="$rustToolchain" \
          --disable-ldconfig
        bash "$TMPDIR/cargo-official"/cargo-1.94.0-x86_64-unknown-linux-gnu/install.sh \
          --prefix="$rustToolchain" \
          --disable-ldconfig
        bash "$TMPDIR/rust-std-host"/rust-std-1.94.0-x86_64-unknown-linux-gnu/install.sh \
          --prefix="$rustToolchain" \
          --disable-ldconfig
        bash "$TMPDIR/rust-std-aarch64"/rust-std-1.94.0-aarch64-linux-android/install.sh \
          --prefix="$rustToolchain" \
          --disable-ldconfig
        bash "$TMPDIR/rust-std-x86_64"/rust-std-1.94.0-x86_64-linux-android/install.sh \
          --prefix="$rustToolchain" \
          --disable-ldconfig

        for rustBinary in \
          "$rustToolchain/bin/cargo" \
          "$rustToolchain/bin/rustc" \
          "$rustToolchain/bin/rustdoc"
        do
          patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} "$rustBinary"
        done
        while IFS= read -r -d "" rustBinary; do
          patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} "$rustBinary"
        done < <(find "$rustToolchain/lib/rustlib/x86_64-unknown-linux-gnu/bin" -type f -perm -0100 -print0)

        export PATH="$rustToolchain/bin:$PATH"
        export LD_LIBRARY_PATH="${
          lib.makeLibraryPath [
            stdenv.cc.cc.lib
            zlib
          ]
        }:''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        export CARGO="$rustToolchain/bin/cargo"
        export RUSTC="$rustToolchain/bin/rustc"
      '';

      rdpTransportJniLibs = stdenv.mkDerivation (finalAttrs: {
        pname = "haven-rdp-transport-jni-libs";
        inherit (finalAttrs0) version src;

        cargoRoot = "rdp-kotlin/rust";
        cargoDeps = rustPlatform.fetchCargoVendor {
          inherit (finalAttrs)
            pname
            version
            src
            cargoRoot
            ;
          hash = "sha256-EIAn9ooDfj0MTRe+fV3ZkMvAZvuMeP3Nf5Vvfb56aD4=";
        };

        nativeBuildInputs = [
          patchelf
          cargo-ndk
          rustPlatform.cargoSetupHook
        ];

        dontConfigure = true;

        env = {
          ANDROID_HOME = "${androidSdk}/share/android-sdk";
          ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
          ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/27.3.13750724";
          ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk/27.3.13750724";
        };

        preBuild = setupOfficialRustToolchain;

        buildPhase = ''
          runHook preBuild
          cd rdp-kotlin/rust

          outDir="$TMPDIR/jniLibs"
          cargo ndk -t arm64-v8a -o "$outDir" build --release
          cargo ndk -t x86_64 -o "$outDir" build --release

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          install -Dm755 "$TMPDIR/jniLibs/arm64-v8a/librdp_transport.so" "$out/arm64-v8a/librdp_transport.so"
          install -Dm755 "$TMPDIR/jniLibs/x86_64/librdp_transport.so" "$out/x86_64/librdp_transport.so"
          runHook postInstall
        '';
      });
    in
    {
      pname = "haven";
      version = "4.0.0";

      src = fetchFromGitHub {
        owner = "GlassOnTin";
        repo = "Haven";
        tag = "v${finalAttrs0.version}";
        fetchSubmodules = true;
        hash = "sha256-7mf64vDAK98dEfEOWXzKL22bMJYi52cLA5U0pNeot1s=";
      };

      patches = [
        # Build unsigned APK (no keystore in sandbox); apksigner re-signs in installPhase.
        ./remove-signing-config.patch
        # Allow skipping Chaquopy pip requirements in reproducible/offline builds.
        ./skip-python-requirements.patch
        # Override AGP's default NDK selection for the native local module.
        ./set-ndk-version.patch
        # Build the Rust JNI libraries in Nix instead of invoking cargo-ndk from Gradle.
        ./skip-gradle-rdp-native-build.patch
      ];

      gradleBuildTask = ":app:assembleArm64Release";
      gradleUpdateTask = finalAttrs0.gradleBuildTask;

      # Lock refresh steps:
      # 1. Build the updater:
      #    nix build --impure .#haven.mitmCache.updateScript
      # 2. Copy the resulting fetch-deps.sh, set outPath=haven_deps.json, run from repo root.
      mitmCache = gradle.fetchDeps {
        inherit (finalAttrs0) pname;
        pkg = finalAttrs0.finalPackage;
        data = ./haven_deps.json;
        silent = false;
        useBwrap = false;
      };

      nativeBuildInputs = [
        gradle
        jdk17_headless
        apksigner
        writableTmpDirAsHomeHook
        git
        python313
        go
        unzip
      ];

      env = {
        JAVA_HOME = jdk17_headless;
        ANDROID_HOME = "${androidSdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
        ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/27.3.13750724";
        ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
        HAVEN_SKIP_PYTHON_REQUIREMENTS = "1";
      };

      preConfigure = ''
        export ANDROID_USER_HOME="$HOME/.android"
        mkdir -p "$ANDROID_USER_HOME"
        echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties

        mkdir -p rdp-kotlin/jniLibs
        cp -r ${rdpTransportJniLibs}/. rdp-kotlin/jniLibs/

        export GOCACHE="$TMPDIR/go-cache"
        export GOPATH="$TMPDIR/go"
        mkdir -p "$GOCACHE" "$GOPATH/bin"
        export PATH="$GOPATH/bin:$PATH"

        # Install gomobile and gobind so rclone-android build script finds them.
        # This occurs before gradle runs, so mitmCache proxy captures it.
        go install golang.org/x/mobile/cmd/gomobile@latest
        go install golang.org/x/mobile/cmd/gobind@latest

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
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        export ANDROID_USER_HOME="$HOME/.android"
        export GRADLE_USER_HOME="$HOME/.gradle"
        mkdir -p "$ANDROID_USER_HOME" "$GRADLE_USER_HOME"
        export GRADLE_OPTS="''${GRADLE_OPTS:+$GRADLE_OPTS }-Duser.home=$HOME"
      '';

      gradleFlags = [
        "-xlintVitalRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
        "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
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
