{
  pkgs,
  androidSdkBuilder,
  gradle2nixBuilders,
  mkSignScript,
}:

let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-35
    s.build-tools-35-0-0
    # NDK 27 gets past the initial Gradle pin mismatch, but Forkgram's bundled
    # native dependency scripts still assume the old NDK tool/bin layout and
    # libvpx configure currently fails to link against the newer sysroot setup.
    s.ndk-27-3-13750724
  ]);
in
gradle2nixBuilders.buildGradlePackage rec {
  pname = "forkgram";
  version = "12.5.2.0";

  src = pkgs.fetchFromGitHub {
    owner = "forkgram";
    repo = "TelegramAndroid";
    rev = version;
    hash = "sha256-HQ2vpSawHls68cztoTB+dkGGIOqx/MwVDrKFnsgm2lU=";
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
    substituteInPlace TMessagesProj/jni/build_dav1d_clang.sh \
      --replace-fail 'AR=''${TOOLS_PREFIX}ar' 'AR=''${LLVM_BIN}/llvm-ar' \
      --replace-fail 'STRIP=''${TOOLS_PREFIX}strip' 'STRIP=''${LLVM_BIN}/llvm-strip' \
      --replace-fail 'NM=''${TOOLS_PREFIX}nm' 'NM=''${LLVM_BIN}/llvm-nm'
    substituteInPlace TMessagesProj/jni/build_libvpx_clang.sh \
      --replace-fail 'export AR=''${TOOLS_PREFIX}ar' 'export AR=''${LLVM_BIN}/llvm-ar' \
      --replace-fail 'export STRIP=''${TOOLS_PREFIX}strip' 'export STRIP=''${LLVM_BIN}/llvm-strip' \
      --replace-fail 'export RANLIB=''${TOOLS_PREFIX}ranlib' 'export RANLIB=''${LLVM_BIN}/llvm-ranlib' \
      --replace-fail 'export NM=''${TOOLS_PREFIX}nm' 'export NM=''${LLVM_BIN}/llvm-nm' \
      --replace-fail 'export LDFLAGS="-L''${PLATFORM}/usr/lib"' 'export LDFLAGS="--sysroot=''${LLVM_PREFIX}/sysroot"'

    # Inject Telegram API credentials and enable F-Droid mode — taken from the F-Droid build recipe:
    # https://gitlab.com/fdroid/fdroiddata/-/blob/master/metadata/org.forkgram.messenger.yml
    # (prebuild_fdroid.sh args: APP_ID=$2 APP_HASH=$3, consistent across all versions)
    # F_DROID=1 sets SKIP_DNS_RESOLVER=true (normal system DNS), package org.forkgram.messenger,
    # and disables signing (storeFile null → unsigned APK for external signing).
    echo "APP_ID=14577864" >> gradle.properties
    echo "APP_HASH=54d3ae230fd8f985ce9adccf08fbd9d6" >> gradle.properties
    substituteInPlace gradle.properties \
      --replace-fail "F_DROID=0" "F_DROID=1"

    while IFS= read -r gradleFile; do
      substituteInPlace "$gradleFile" \
        --replace-fail '21.4.7075529' '27.3.13750724'
    done < <(printf '%s\n' \
      TMessagesProj/build.gradle \
      TMessagesProj_App/build.gradle \
      TMessagesProj_AppHuawei/build.gradle \
      TMessagesProj_AppStandalone/build.gradle \
      TMessagesProj_AppTests/build.gradle)
    substituteInPlace TMessagesProj/build.gradle \
      --replace-fail "commandLine 'python3', 'prepare.py', 'silent', 'ndk=' + ndkDir, 'arm', 'arm64'" \
        "commandLine 'python3', 'prepare.py', 'silent', 'ndk=' + ndkDir, 'arm64'"


    # Tell AGP where to find cmake (it looks for version 3.22.1 in the SDK by default)
    echo "sdk.dir=${androidSdk}/share/android-sdk" >> local.properties
    echo "ndk.dir=${androidSdk}/share/android-sdk/ndk/27.3.13750724" >> local.properties
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
    ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk/27.3.13750724";
    ANDROID_NDK_ROOT = "${androidSdk}/share/android-sdk/ndk/27.3.13750724";
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

  passthru.signScript = mkSignScript {
    name = "sign-forkgram";
    apkPath = "${placeholder "out"}/forkgram.apk";
    defaultOut = "forkgram-signed.apk";
  };
  meta = with pkgs.lib; {
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
