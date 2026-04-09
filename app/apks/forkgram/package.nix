{
  androidSdkBuilder,
  bash,
  cmake,
  darwin,
  fetchFromGitHub,
  go,
  overrides-from-source,
  gradle2nixBuilders,
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
}:

let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-35
    s.build-tools-35-0-0
    # Tried NDK 27.3.13750724 here, but Forkgram's bundled native dependency
    # scripts still assume older NDK tool/bin and sysroot layouts; dav1d was
    # patched forward, but libvpx still failed to link cleanly, so keep baseline.
    s.ndk-21-4-7075529
    # ndk-23-2-8568313 could not be realized under the pinned Android SDK packaging because auto-patchelf could not satisfy host libs like libsqlite3.so.0, libgdbm.so.3, libssl.so.1.0.0, and libffi.so.6.
  ]);
in
gradle2nixBuilders.buildGradlePackage rec {
  pname = "forkgram";
  version = "12.6.5.0";

  src = fetchFromGitHub {
    owner = "forkgram";
    repo = "TelegramAndroid";
    rev = version;
    hash = "sha256-7PdgGHfRAvBexm/TeMnxsepQwL1+y+3lSuSz/b76quY=";
    fetchSubmodules = true;
  };

  lockFile = ./gradle.lock;

  overrides = overrides-from-source;

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
    # TODO: consider https://github.com/DrKLO/Telegram/pull/1854
    ./0001-Killergram.patch
    #./0002-max-account-count.patch
    # Skip git submodule management (submodules pre-fetched by Nix)
    # and skip rm -rf of submodule dirs
    ./prepare.patch
    # Fix $(ANDROID_SDK) command-substitution bug (should be ${ANDROID_SDK})
    ./build_boringssl.patch
    # Remove PATH prepend for non-existent SDK cmake 3.22.1;
    # add CMAKE_MAKE_PROGRAM=ninja and BOTH find-root-path modes for OpenSSL/ZLIB
    ./build-tdlib.patch
    # Remove curl/wget check — not needed in Nix sandbox (no downloads)
    ./check-environment.patch
    # Fix ZLIB detection in tdutils: use NDK sysroot on Android, skip on host source-gen step
    ./tde2e-cmake-zlib.patch
    # Fix ZLIB detection in tdutils: use NDK sysroot so TD_HAVE_OPENSSL gets set
    ./tdutils-cmake-zlib.patch
    # Add cpufeatures as static library for NDK < r23 (AndroidNdkModules not available)
    ./jni-cmake-cpufeatures.patch
    # Remove jniLibs.srcDirs = ['./jni/'] — the source tree contains cmake intermediate
    # files (.o.tmp) that cause mergeJniLibFolders to fail; AGP's cmake build provides output
    ./jni-srcset.patch
    # F-Droid prebuild: remove Google Play/GMS deps; bump Java 17→21 (matches F-Droid recipe)
    ./fdroid-TMessagesProj.patch
    # F-Droid prebuild: bump Java 17→21 and fix storeFile null (unsigned APK) in App module
    ./fdroid-TMessagesProj_App.patch
  ];

  postPatch = ''
    patchShebangs TMessagesProj/jni/

    # Fix hardcoded /bin/bash in subprocess call (no /bin/bash in Nix sandbox)
    substituteInPlace TMessagesProj/jni/prepare.py \
      --replace-fail 'executable="/bin/bash"' 'executable="${bash}/bin/bash"'

    # Inject Telegram API credentials and enable F-Droid mode — taken from the F-Droid build recipe:
    # https://gitlab.com/fdroid/fdroiddata/-/blob/master/metadata/org.forkgram.messenger.yml
    # (prebuild_fdroid.sh args: APP_ID=$2 APP_HASH=$3, consistent across all versions)
    # F_DROID=1 sets SKIP_DNS_RESOLVER=true (normal system DNS), package org.forkgram.messenger,
    # and disables signing (storeFile null → unsigned APK for external signing).
    echo "APP_ID=14577864" >> gradle.properties
    echo "APP_HASH=54d3ae230fd8f985ce9adccf08fbd9d6" >> gradle.properties
    substituteInPlace gradle.properties \
      --replace-fail "F_DROID=0" "F_DROID=1"


    # Tell AGP where to find cmake (it looks for version 3.22.1 in the SDK by default)
    echo "cmake.dir=${cmake}" >> local.properties

    # Use aapt2 from the installed SDK instead of downloading from Maven
    echo "android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2" >> gradle.properties

    # The fdroid signing config (F_DROID=1) references release.keystore with default credentials.
    # Regenerate it so the build succeeds; output APK will be re-signed externally.
    rm -f TMessagesProj/config/release.keystore
    keytool -genkey -v \
      -keystore TMessagesProj/config/release.keystore \
      -alias androidkey -keyalg RSA -keysize 2048 -validity 10000 \
      -storepass android -keypass android \
      -dname "CN=Forkgram Build"

    # boringssl's CMake build runs 'go run err_data_generate.go'.
    # Set up a vendor dir so go doesn't try to download golang.org/x/{crypto,net}.
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
    GOFLAGS = "-mod=vendor";
  };

  preBuild = lib.optionalString stdenv.isDarwin ''
    # AGP writes SDK metadata under ~/.android; /var/empty is read-only on Darwin sandboxes.
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
