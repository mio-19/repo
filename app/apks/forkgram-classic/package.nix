{
  androidSdkBuilder,
  cmake,
  darwin,
  fetchFromGitHub,
  git,
  path,
  rustPlatform,
  go,
  overrides-fromsrc,
  buildGradlePackage,
  gperf,
  jdk21_headless,
  lib,
  mkSignScript,
  meson,
  ninja,
  perl,
  pkg-config,
  python3,
  stdenv,
  unzip,
  which,
  writableTmpDirAsHomeHook,
  gradle_8_14_4,
}:

let
  version = "12.10.2.0";

  src = fetchFromGitHub {
    owner = "forkgram";
    repo = "forkgram-classic";
    tag = version;
    hash = "sha256-Z1DGZRt/Og/KsQssZEjPjFH6VhCum52K7hcZHdGIoBQ=";
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
  pname = "forkgram-classic";
  version = "12.10.2.0";
  src = fetchFromGitHub {
    owner = "forkgram";
    repo = "forkgram-classic";
    tag = version;
    hash = "sha256-Z1DGZRt/Og/KsQssZEjPjFH6VhCum52K7hcZHdGIoBQ=";
    fetchSubmodules = true;
  };

  gradle = gradle_8_14_4;

  lockFile = ./gradle.lock;

  overrides = overrides-fromsrc;

  buildJdk = jdk21_headless;

  nativeBuildInputs = [
    androidSdk
    cmake
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
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.system_cmds
  ];

  patches = [
    ./0001-Killergram.patch
    ./native-build.patch
    ./fdroid.patch
  ];

  postPatch = ''

        find . -name "build.gradle" -type f -exec sed -i 's/androidx.annotation:annotation:/androidx.annotation:annotation-jvm:/g' {} +
        patchShebangs TMessagesProj/jni/

        substituteInPlace TMessagesProj/jni/prepare.py \
          --replace-quiet "git checkout -- tlottie_lib" "" \
          --replace-quiet './tlottie_lib/build.sh' 'test -f tlottie_lib/arm64-v8a/libtlottie.a && test -f tlottie_lib/armeabi-v7a/libtlottie.a'

        install -Dm644 ${tlottieArm64}/arm64-v8a/libtlottie.a \
          TMessagesProj/jni/tlottie_lib/arm64-v8a/libtlottie.a
        install -Dm644 ${tlottieArmv7}/armeabi-v7a/libtlottie.a \
          TMessagesProj/jni/tlottie_lib/armeabi-v7a/libtlottie.a


        substituteInPlace TMessagesProj/jni/prepare.py \
          --replace-fail "return 'rm -rf ' + folder" "return 'true'" \
          --replace-fail 'executable="/bin/bash"' 'executable="bash"' \
          --replace-quiet "git submodule init && git submodule update" "" \
          --replace-quiet "cd boringssl && git reset --hard HEAD && cd .." "" \
          --replace-quiet "git reset HEAD tde2e/ && git checkout -- tde2e/" "" \
          --replace-quiet "cd tde2e_source && git reset --hard HEAD && cd .." "" \
          --replace-quiet "git checkout -- ffmpeg" ""


        echo "APP_ID=14577864" >> gradle.properties
        echo "APP_HASH=54d3ae230fd8f985ce9adccf08fbd9d6" >> gradle.properties
        substituteInPlace gradle.properties \
          --replace-fail "F_DROID=0" "F_DROID=1"

        if [ "$(uname -s)" = "Darwin" ]; then
          substituteInPlace TMessagesProj/jni/tde2e/build-tdlib.sh \
            --replace-warn "linux-x86_64" "darwin-x86_64"
        fi

        cat >> build.gradle << 'EOF'
    allprojects {
        afterEvaluate {
            if (project.hasProperty("android")) {
                android.ndkVersion = "27.2.12479018"
            }
        }
    }
    EOF

        echo "cmake.dir=${cmake}" >> local.properties
        echo "ndk.dir=${androidSdk}/share/android-sdk/ndk/27.2.12479018" >> local.properties
        echo "android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2" >> gradle.properties

        rm -f TMessagesProj/config/release.keystore
        keytool -genkey -v \
          -keystore TMessagesProj/config/release.keystore \
          -alias androidkey -keyalg RSA -keysize 2048 -validity 10000 \
          -storepass android -keypass android \
          -dname "CN=Forkgram Classic Build"

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

  gradleFlags = [ "-Pandroid.ndkVersion=27.2.12479018" ];

  installPhase = ''
    runHook preInstall
    install -Dm644 TMessagesProj_App/build/outputs/apk/afatFd_v8a/release/*.apk "$out/forkgram-classic.apk"
    runHook postInstall
  '';

  passthru.signScript = mkSignScript {
    name = "sign-forkgram-classic";
    apkPath = "${placeholder "out"}/forkgram-classic.apk";
    defaultOut = "forkgram-classic-signed.apk";
  };
  meta = with lib; {
    description = "Telegram Android client fork (Forkgram Classic)";
    homepage = "https://github.com/forkgram/forkgram-classic";
    license = licenses.gpl2Plus;
    platforms = platforms.unix;
    mainApk = "forkgram-classic.apk";
    appId = "org.forkgram.classic";
    metadataYml = ''
      Categories:
        - Internet
      License: GPL-2.0-or-later
      SourceCode: https://github.com/forkgram/forkgram-classic
      IssueTracker: https://github.com/forkgram/forkgram-classic/issues
      AutoName: Forkgram Classic
      Summary: Telegram client fork (classic UI)
      Description: |-
        Forkgram Classic is a Telegram Android client fork with the classic UI.
    '';
  };
}
