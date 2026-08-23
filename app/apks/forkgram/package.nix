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
  writableTmpDirAsHomeHook,
  gradle_8_14_4,
}:

let
  version = "12.9.7.0";

  src = fetchFromGitHub {
    owner = "forkgram";
    repo = "TelegramAndroid";
    rev = version;
    hash = "sha256-3sPvwZm3w7k7IdvoEa6lRT1Bl98a2YMf9GnwB6VpX1Q=";
    fetchSubmodules = true;
  };

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-35
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
    hash = "sha256-XPagRmugqmrCYKVFvvOfGZ7Ew3qcpQizENcztbKQ1Zs=";
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
  ++ lib.optionals stdenv.isDarwin [
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
        patchShebangs TMessagesProj/jni/

        substituteInPlace TMessagesProj/jni/prepare.py \
          --replace-fail "return 'rm -rf ' + folder" "return 'true'" \
          --replace-fail 'executable="/bin/bash"' 'executable="bash"' \
          --replace-quiet "git submodule init && git submodule update" "" \
          --replace-quiet "cd boringssl && git reset --hard HEAD && cd .." "" \
          --replace-quiet "git reset HEAD tde2e/ && git checkout -- tde2e/" "" \
          --replace-quiet "cd tde2e_source && git reset --hard HEAD && cd .." "" \
          --replace-quiet "git checkout -- ffmpeg" "" \
          --replace-quiet "git checkout -- tlottie_lib" ""

        install -Dm644 ${tlottieArm64}/arm64-v8a/libtlottie.a \
          TMessagesProj/jni/tlottie_lib/arm64-v8a/libtlottie.a
        install -Dm644 ${tlottieArmv7}/armeabi-v7a/libtlottie.a \
          TMessagesProj/jni/tlottie_lib/armeabi-v7a/libtlottie.a
        substituteInPlace TMessagesProj/jni/prepare.py \
          --replace-fail './tlottie_lib/build.sh' 'test -f tlottie_lib/arm64-v8a/libtlottie.a && test -f tlottie_lib/armeabi-v7a/libtlottie.a'

        substituteInPlace TMessagesProj/jni/CMakeLists.txt \
          --replace-fail 'set(CMAKE_C_FLAGS "''${CMAKE_C_FLAGS} -ffunction-sections -fdata-sections -fvisibility=hidden -flto=full")' 'set(CMAKE_C_FLAGS "''${CMAKE_C_FLAGS} -ffunction-sections -fdata-sections -fvisibility=hidden")' \
          --replace-fail 'set(CMAKE_CXX_FLAGS "''${CMAKE_CXX_FLAGS} -ffunction-sections -fdata-sections -fvisibility=hidden -fvisibility-inlines-hidden -flto=full")' 'set(CMAKE_CXX_FLAGS "''${CMAKE_CXX_FLAGS} -ffunction-sections -fdata-sections -fvisibility=hidden -fvisibility-inlines-hidden")' \
          --replace-fail 'set(CMAKE_SHARED_LINKER_FLAGS "''${CMAKE_SHARED_LINKER_FLAGS} -flto=full -Wl,--gc-sections -Wl,--icf=safe -Wl,-Bsymbolic")' 'set(CMAKE_SHARED_LINKER_FLAGS "''${CMAKE_SHARED_LINKER_FLAGS} -Wl,--gc-sections -Wl,-Bsymbolic")' \
          --replace-fail 'include(AndroidNdkModules)
    android_ndk_import_module_cpufeatures()' '# AndroidNdkModules was added in NDK r23; for older NDKs add cpufeatures manually.
    if(EXISTS "''${ANDROID_NDK}/sources/android/cpufeatures/cpu-features.c")
      add_library(cpufeatures STATIC
        "''${ANDROID_NDK}/sources/android/cpufeatures/cpu-features.c")
      target_include_directories(cpufeatures PUBLIC
        "''${ANDROID_NDK}/sources/android/cpufeatures")
      set_target_properties(cpufeatures PROPERTIES POSITION_INDEPENDENT_CODE ON)
    else()
      include(AndroidNdkModules)
      android_ndk_import_module_cpufeatures()
    endif()'

        # F-Droid prebuild: Telegram API credentials, F-Droid mode, NDK pin.
        # https://gitlab.com/fdroid/fdroiddata/-/blob/master/metadata/org.forkgram.messenger.yml
        echo "APP_ID=14577864" >> gradle.properties
        echo "APP_HASH=54d3ae230fd8f985ce9adccf08fbd9d6" >> gradle.properties
        substituteInPlace gradle.properties \
          --replace-fail "F_DROID=0" "F_DROID=1"

        echo "cmake.dir=${cmake}" >> local.properties
        echo "ndk.dir=${androidSdk}/share/android-sdk/ndk/27.2.12479018" >> local.properties
        echo "android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2" >> gradle.properties

        substituteInPlace TMessagesProj/jni/tde2e/build-tdlib.sh \
          --replace-fail 'ANDROID_NDK_VERSION=''${2:-23.2.8568313}' 'ANDROID_NDK_VERSION=''${2:-27.2.12479018}' \
          --replace-fail 'source ./check-environment.sh || exit 1' 'true' \
          --replace-fail 'PATH=$ANDROID_SDK_ROOT/cmake/3.22.1/bin:$PATH' 'PATH=${cmake}/bin:$PATH'

        substituteInPlace TMessagesProj/jni/tde2e/build-tdlib.sh \
          --replace-fail '-DANDROID_PLATFORM=android-16 $TDLIB_INTERFACE_OPTION .. || exit 1' \
                         '-DCMAKE_MAKE_PROGRAM=ninja -DANDROID_LD=lld -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH -DANDROID_PLATFORM=android-21 $TDLIB_INTERFACE_OPTION .. || exit 1'

        substituteInPlace TMessagesProj/jni/tde2e_source/CMakeLists.txt \
          --replace-fail "if (NOT ZLIB_FOUND)
      message(WARNING \"Can't find zlib: stop TDLib building\")
      return()
    endif()" "if (NOT ZLIB_FOUND)
      if (ANDROID_NDK)
        set(ZLIB_INCLUDE_DIR \"''${CMAKE_SYSROOT}/usr/include\" CACHE PATH \"\" FORCE)
        set(ZLIB_LIBRARY \"z\" CACHE STRING \"\" FORCE)
        set(ZLIB_LIBRARIES \"z\")
        set(ZLIB_FOUND 1)
      elseif (NOT TD_GENERATE_SOURCE_FILES)
        message(WARNING \"Can't find zlib: stop TDLib building\")
        return()
      endif()
    endif()"

        substituteInPlace TMessagesProj/jni/tde2e_source/tdutils/CMakeLists.txt \
          --replace-fail "if (NOT ZLIB_FOUND AND TDUTILS_USE_EXTERNAL_DEPENDENCIES)
      find_package(ZLIB)
    endif()" "if (NOT ZLIB_FOUND AND TDUTILS_USE_EXTERNAL_DEPENDENCIES)
      if (ANDROID_NDK AND CMAKE_SYSROOT)
        set(ZLIB_INCLUDE_DIR \"''${CMAKE_SYSROOT}/usr/include\" CACHE PATH \"\" FORCE)
        set(ZLIB_LIBRARY \"z\" CACHE STRING \"\" FORCE)
        set(ZLIB_LIBRARIES \"z\")
        set(ZLIB_FOUND 1)
      else()
        find_package(ZLIB)
      endif()
    endif()"

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

  preBuild = lib.optionalString stdenv.isDarwin ''
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
