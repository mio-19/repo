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
  pname = "forkgram-classic";
  version = "12.9.1.0";

  gradle = gradle_8_14_4;

  src = fetchFromGitHub {
    owner = "forkgram";
    repo = "forkgram-classic";
    tag = version;
    hash = "sha256-T49kB4GH3y79gEaGkNWd+vRQ3pxvY6PdxiziQhpVw9w=";
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
    writableTmpDirAsHomeHook
  ]
  ++ lib.optionals stdenv.isDarwin [
    darwin.system_cmds
  ];

  patches = [
    ./0001-Killergram.patch
    ./prepare.patch
    ./native-build.patch
    ./fdroid.patch
    ./ndk27.patch
  ];

  postPatch = ''
        patchShebangs TMessagesProj/jni/

        echo "APP_ID=14577864" >> gradle.properties
        echo "APP_HASH=54d3ae230fd8f985ce9adccf08fbd9d6" >> gradle.properties
        substituteInPlace gradle.properties \
          --replace-fail "F_DROID=0" "F_DROID=1"

        if [ "$(uname -s)" = "Darwin" ]; then
          substituteInPlace TMessagesProj/jni/build_dav1d_clang.sh \
            TMessagesProj/jni/build_ffmpeg_clang.sh \
            TMessagesProj/jni/build_libvpx_clang.sh \
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

  preBuild = lib.optionalString stdenv.isDarwin ''
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
