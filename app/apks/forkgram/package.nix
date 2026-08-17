{
  androidSdkBuilder,
  cmake,
  darwin,
  fetchFromGitHub,
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
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-35
    s.build-tools-35-0-0
    s.ndk-27-2-12479018
  ]);
in
buildGradlePackage rec {
  pname = "forkgram";
  version = "12.9.3.0";

  gradle = gradle_8_14_4;

  src = fetchFromGitHub {
    owner = "forkgram";
    repo = "TelegramAndroid";
    rev = version;
    hash = "sha256-ibzy3lCe1lK+G2lytLsHCqbfQ8/b3E/k5ZdwNDuv6qc=";
    fetchSubmodules = true;
  };

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
  ++ lib.optionals stdenv.isDarwin [
    darwin.system_cmds
  ];

  patches = [
    # TODO: consider https://github.com/DrKLO/Telegram/pull/1854
    ./0001-Killergram.patch
    # NOTE: The max account patch renders the application unusable.
    # It is kept here for reference only.
    # ./0002-max-account-count.patch
    ./native-build.patch
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
      --replace-quiet "git checkout -- ffmpeg" ""

    # F-Droid prebuild: Telegram API credentials, F-Droid mode, NDK pin.
    # https://gitlab.com/fdroid/fdroiddata/-/blob/master/metadata/org.forkgram.messenger.yml
    echo "APP_ID=14577864" >> gradle.properties
    echo "APP_HASH=54d3ae230fd8f985ce9adccf08fbd9d6" >> gradle.properties
    substituteInPlace gradle.properties \
      --replace-fail "F_DROID=0" "F_DROID=1"

    echo "cmake.dir=${cmake}" >> local.properties
    echo "ndk.dir=${androidSdk}/share/android-sdk/ndk/27.2.12479018" >> local.properties
    echo "android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2" >> gradle.properties

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
