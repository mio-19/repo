{
  pkgs,
  androidSdkBuilder,
  gradle2nixBuilders,
}:

let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-35
    s.build-tools-35-0-0
    s.ndk-21-4-7075529
  ]);
in
gradle2nixBuilders.buildGradlePackage {
  pname = "forkgram";
  version = "12.5.1.0";

  src = pkgs.fetchFromGitHub {
    owner = "forkgram";
    repo = "TelegramAndroid";
    rev = "12.5.1.0";
    hash = "sha256-XvPUORn15ll6if8kDEd/EzyS2qQ4Ew7fkxC3nCewzzM=";
    fetchSubmodules = true;
  };

  lockFile = ./gradle.lock;

  buildJdk = pkgs.jdk21;

  nativeBuildInputs = [
    androidSdk
    pkgs.cmake
    pkgs.gperf
    pkgs.go
    pkgs.jdk21
    pkgs.meson
    pkgs.ninja
    pkgs.perl
    pkgs.python3
    pkgs.unzip
    pkgs.which
    pkgs.writableTmpDirAsHomeHook
  ]
  ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
    pkgs.darwin.system_cmds
  ];

  patches = [
    ./0001-Killergram.patch
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
      --replace-fail 'executable="/bin/bash"' 'executable="${pkgs.bash}/bin/bash"'

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
    echo "cmake.dir=${pkgs.cmake}" >> local.properties

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

  preBuild = pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
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

  meta = with pkgs.lib; {
    description = "Telegram Android client fork (ForkGram)";
    homepage = "https://github.com/forkgram/TelegramAndroid";
    license = licenses.gpl2Plus;
    platforms = platforms.unix;
  };
}
