{
  androidSdkBuilder,
  cmake,
  darwin,
  fetchFromGitHub,
  git,
  go,
  overrides-fromsrc,
  buildGradlePackage,
  gperf,
  jdk21_headless,
  lib,
  mkSignScript,
  meson,
  ninja,
  path,
  perl,
  pkg-config,
  python3,
  rustPlatform,
  stdenv,
  unzip,
  which,
  cargo,
  rustc,
  writableTmpDirAsHomeHook,
  gradle_8_14_4,
}:

let
  version = "12.10.4.0";

  src = fetchFromGitHub {
    owner = "forkgram";
    repo = "TelegramAndroid";
    rev = version;
    hash = "sha256-Xxw6StKhSKUDgTNu+EsHP8qtrJuc2ALLJcWiKKIE3oo=";
    fetchSubmodules = true;
  };

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-36
    s.platforms-android-35
    s.build-tools-36-0-0
    s.build-tools-35-0-0
    s.ndk-27-2-12479018
  ]);

  androidCrossConfig = {
    config.allowUnfree = true;
    localSystem = stdenv.buildPlatform.system;
  };

  mkAndroidPkgs =
    {
      config,
      rustTarget,
    }:
    import path (
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

  armv7AndroidPkgs = mkAndroidPkgs {
    config = "armv7a-unknown-linux-androideabi";
    rustTarget = "armv7-linux-androideabi";
  };

  tlottieCargoDeps = rustPlatform.fetchCargoVendor {
    pname = "forkgram-tlottie";
    inherit version src;
    cargoRoot = "TMessagesProj/jni/tlottie";
    hash = "sha256-R/l5zMRB/2/a4Yf6toPBBvJ1SvebWsGeumwW9U6b7So=";
  };

  mkTlottieArchive =
    {
      abi,
      crossPkgs,
      rustTarget,
    }:
    crossPkgs.rustPlatform.buildRustPackage {
      pname = "forkgram-tlottie-${abi}";
      inherit version src;

      sourceRoot = "${src.name}/TMessagesProj/jni/tlottie";
      cargoDeps = tlottieCargoDeps;
      CARGO_BUILD_TARGET = rustTarget;
      doCheck = false;

      buildPhase = ''
        runHook preBuild
        cargo rustc \
          --profile release-nostd \
          --target ${rustTarget} \
          --lib \
          --no-default-features \
          --features cpu,no-std,c-api \
          --crate-type staticlib
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        install -Dm644 target/${rustTarget}/release-nostd/libtlottie.a \
          "$out/${abi}/libtlottie.a"
        runHook postInstall
      '';
    };

  tlottieArm64 = mkTlottieArchive {
    abi = "arm64-v8a";
    crossPkgs = aarch64AndroidPkgs;
    rustTarget = "aarch64-linux-android";
  };

  tlottieArmv7 = mkTlottieArchive {
    abi = "armeabi-v7a";
    crossPkgs = armv7AndroidPkgs;
    rustTarget = "armv7-linux-androideabi";
  };
in
buildGradlePackage rec {
  pname = "forkgram";
  inherit version src;

  gradle = gradle_8_14_4;

  lockFile = ./gradle.lock;

  overrides = overrides-fromsrc;

  buildJdk = jdk21_headless;

  nativeBuildInputs = [
    androidSdk
    cmake
    git
    gperf
    go
    cargo
    rustc
    jdk21_headless
    meson
    ninja
    perl
    python3
    unzip
    which
    pkg-config
    writableTmpDirAsHomeHook
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.system_cmds
  ];

  patches = [
    # TODO: consider https://github.com/DrKLO/Telegram/pull/1854
    ./0001-Killergram.patch
    # NOTE: The max account patch renders the application unusable.
    # It is kept here for reference only.
    # ./0002-max-account-count.patch
    ./fdroid.patch
  ];

  postPatch = ''

            find . -name "build.gradle" -type f -print0 | while IFS= read -r -d "" file; do if grep -q "androidx.annotation:annotation:" "$file"; then substituteInPlace "$file" --replace-fail "androidx.annotation:annotation:" "androidx.annotation:annotation-jvm:"; fi; done
            
            cat << 'EOF' > TMessagesProj/jni/prebuild/build_tlottie.sh
    #!/usr/bin/env bash
    SCRIPT_DIR="$(cd "$(dirname "''${BASH_SOURCE[0]}")" && pwd)"
    LIB_DIR="$SCRIPT_DIR/lib"
    mkdir -p "$LIB_DIR/arm64-v8a" "$LIB_DIR/armeabi-v7a"
    cp "$SCRIPT_DIR/safe_tlottie/arm64-v8a/libtlottie.a" "$LIB_DIR/arm64-v8a/"
    cp "$SCRIPT_DIR/safe_tlottie/armeabi-v7a/libtlottie.a" "$LIB_DIR/armeabi-v7a/"
    EOF
            
            patchShebangs TMessagesProj/jni/

            substituteInPlace TMessagesProj/jni/prepare.py \
              --replace-fail "return 'rm -rf ' + folder" "return 'true'" \
              --replace-quiet "git submodule init && git submodule update" "" \
              --replace-quiet "git checkout -- prebuild" "" \
              --replace-quiet "cd boringssl && git reset --hard HEAD && cd .." "" \
              --replace-quiet "git reset HEAD tde2e/ && git checkout -- tde2e/" "" \
              --replace-quiet "cd tde2e_source && git reset --hard HEAD && cd .." "" \
              --replace-quiet "git checkout -- ffmpeg" "" \
              --replace-quiet "git checkout -- prebuild" ""

            install -Dm644 ${tlottieArm64}/arm64-v8a/libtlottie.a \
              TMessagesProj/jni/prebuild/safe_tlottie/arm64-v8a/libtlottie.a
            install -Dm644 ${tlottieArmv7}/armeabi-v7a/libtlottie.a \
              TMessagesProj/jni/prebuild/safe_tlottie/armeabi-v7a/libtlottie.a


            substituteInPlace TMessagesProj/jni/CMakeLists.txt \
              --replace-fail 'set(CMAKE_C_FLAGS "''${CMAKE_C_FLAGS} -ffunction-sections -fdata-sections -fvisibility=hidden -flto=full")' 'set(CMAKE_C_FLAGS "''${CMAKE_C_FLAGS} -ffunction-sections -fdata-sections -fvisibility=hidden")' \
              --replace-fail 'set(CMAKE_CXX_FLAGS "''${CMAKE_CXX_FLAGS} -ffunction-sections -fdata-sections -fvisibility=hidden -fvisibility-inlines-hidden -flto=full")' 'set(CMAKE_CXX_FLAGS "''${CMAKE_CXX_FLAGS} -ffunction-sections -fdata-sections -fvisibility=hidden -fvisibility-inlines-hidden")' \
              --replace-fail 'set(CMAKE_SHARED_LINKER_FLAGS "''${CMAKE_SHARED_LINKER_FLAGS} -flto=full -Wl,--gc-sections -Wl,--icf=safe -Wl,-Bsymbolic")' 'set(CMAKE_SHARED_LINKER_FLAGS "''${CMAKE_SHARED_LINKER_FLAGS} -Wl,--gc-sections -Wl,-Bsymbolic")' \
              --replace-fail 'include(AndroidNdkModules)
    android_ndk_import_module_cpufeatures()' 'add_library(cpufeatures STATIC "''${ANDROID_NDK}/sources/android/cpufeatures/cpu-features.c")
    target_include_directories(cpufeatures PUBLIC "''${ANDROID_NDK}/sources/android/cpufeatures")
    set_target_properties(cpufeatures PROPERTIES POSITION_INDEPENDENT_CODE ON)'

            substituteInPlace TMessagesProj/jni/td/CMakeLists.txt \
              --replace-fail 'find_package(ZLIB)' 'set(ZLIB_FOUND 1)
    set(ZLIB_LIBRARIES z)'

            substituteInPlace TMessagesProj/jni/td/tdutils/CMakeLists.txt \
              --replace-fail 'find_package(ZLIB)' 'set(ZLIB_FOUND 1)
    set(ZLIB_LIBRARIES z)'

            # F-Droid prebuild: Telegram API credentials, F-Droid mode, NDK pin.
            # https://gitlab.com/fdroid/fdroiddata/-/blob/master/metadata/org.forkgram.messenger.yml
            echo "APP_ID=14577864" >> gradle.properties
            echo "APP_HASH=54d3ae230fd8f985ce9adccf08fbd9d6" >> gradle.properties
            substituteInPlace gradle.properties \
              --replace-fail "F_DROID=0" "F_DROID=1"

            echo "cmake.dir=${cmake}" >> local.properties
            echo "ndk.dir=${androidSdk}/share/android-sdk/ndk/27.2.12479018" >> local.properties
            echo "android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2" >> gradle.properties



            # F-Droid signing config references release.keystore; regenerate for build, re-sign externally.
            rm -f TMessagesProj/config/release.keystore
            keytool -genkey -v \
              -keystore TMessagesProj/config/release.keystore \
              -alias androidkey -keyalg RSA -keysize 2048 -validity 10000 \
              -storepass android -keypass android \
              -dname "CN=Forkgram Build"

            for f in TMessagesProj/jni/build_boringssl.sh \
                     TMessagesProj/jni/tde2e/build-tdlib.sh; do
              if [ ! -f "$f" ]; then continue; fi
              if grep -q "ANDROID_API=16" "$f" 2>/dev/null; then
                substituteInPlace "$f" --replace-fail "ANDROID_API=16" "ANDROID_API=21"
              fi
              if grep -q "android-16" "$f" 2>/dev/null; then
                substituteInPlace "$f" --replace-fail "android-16" "android-21"
              fi
              substituteInPlace "$f" \
                --replace-quiet "\''${TOOLS_PREFIX}ar" "\''${LLVM_BIN}/llvm-ar" \
                --replace-quiet "\''${TOOLS_PREFIX}ld" "\''${LLVM_BIN}/ld.lld" \
                --replace-quiet "\''${TOOLS_PREFIX}strip" "\''${LLVM_BIN}/llvm-strip" \
                --replace-quiet "\''${TOOLS_PREFIX}nm" "\''${LLVM_BIN}/llvm-nm"
            done


            # boringssl runs 'go run err_data_generate.go' with vendored golang.org/x/{crypto,net}.
            mkdir -p TMessagesProj/jni/boringssl/vendor/golang.org/x/crypto
            mkdir -p TMessagesProj/jni/boringssl/vendor/golang.org/x/net
            cat > TMessagesProj/jni/boringssl/vendor/modules.txt << 'EOF'
            # golang.org/x/crypto v0.0.0-20210513164829-c07d793c2f9a
            ## explicit; go 1.11
            # golang.org/x/net v0.0.0-20210614182718-04defd469f4e
            ## explicit; go 1.17
    EOF
  '';

  dontUseCmakeConfigure = true;
  dontUseNinjaBuild = true;
  dontUseMesonConfigure = true;

  env = {
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk/27.2.12479018";
    ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/27.2.12479018";
    GOFLAGS = "-mod=vendor";
  };

  preBuild = lib.optionalString stdenv.hostPlatform.isDarwin ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    export ANDROID_USER_HOME="$HOME/.android"
    export GRADLE_USER_HOME="$HOME/.gradle"
    mkdir -p "$ANDROID_USER_HOME" "$GRADLE_USER_HOME"
    export GRADLE_OPTS="''${GRADLE_OPTS:+$GRADLE_OPTS }-Duser.home=$HOME"
  '';

  gradleBuildFlagsArray = [ ":TMessagesProj_App:assembleAfatFd_v8aRelease" ];

  installPhase = ''
    runHook preInstall
    install -Dm644 TMessagesProj_App/build/outputs/apk/afatFd_v8a/release/*.apk "$out/forkgram.apk"
    runHook postInstall
  '';

  passthru.signScript = mkSignScript {
    name = "sign-forkgram";
    apkPath = "${placeholder "out"}/forkgram.apk";
    defaultOut = "forkgram-signed.apk";
  };
  meta = with lib; {
    description = "Telegram Android client fork (ForkGram)";
    homepage = "https://github.com/forkgram/TelegramAndroid";
    license = licenses.gpl2Plus;
    platforms = platforms.unix;
    mainApk = "forkgram.apk";
    appId = "org.forkgram.messenger";
    metadataYml = ''
      Categories:
        - Internet
      License: GPL-2.0-or-later
      SourceCode: https://github.com/forkgram/TelegramAndroid
      IssueTracker: https://github.com/forkgram/TelegramAndroid/issues
      AutoName: Forkgram
      Summary: Telegram client fork
      Description: |-
        Forkgram is a Telegram Android client fork.
    '';
  };
}
