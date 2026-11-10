{
  mk-apk-package,
  stdenv,
  bash,
  lib,
  fetchFromGitHub,
  fetchFromGitLab,
  buildGradlePackage,
  gradle_7_2,
  jdk11_headless,
  androidSdkBuilder,
  writableTmpDirAsHomeHook,
  gnumake,
  autoconf,
  automake,
  libtool,
  pkg-config,
  gettext,
  perl,
  python3,
  flex,
  bison,
  texinfo,
  rsync,
  which,
}:
let
  version = "0.5.0";
  src = fetchFromGitHub {
    owner = "wasdwasd0105";
    repo = "limbo_tensor";
    tag = "v${version}";
    hash = "sha256-lZdP8Z/0ncR8QniAZK53BlgPIaTBsaausG6PMNhYgas=";
  };

  # Upstream's README.developers describes these source inputs and the native
  # build. Keep the Android app and its QEMU runtime built from the same tag.
  qemu = fetchFromGitHub {
    owner = "qemu";
    repo = "qemu";
    tag = "v5.1.0";
    hash = "sha256-Wg/XX3ZSQjoCmNfk8QV1qC2MwsMvYZeCexpUHbfvIOU=";
  };
  keycodemapdb = fetchFromGitHub {
    owner = "qemu";
    repo = "keycodemapdb";
    rev = "6b3d716e2b6472eb7189d3220552280ef3d832ce";
    hash = "sha256-QsjldE+k2VQPOh7WsiNSaKUqVUZpzKtGNpDafrJxCow=";
  };
  dtc = fetchFromGitHub {
    owner = "qemu";
    repo = "dtc";
    rev = "85e5d839847af54efab170f2b1331b2a6421e647";
    hash = "sha256-lNI9Tf+Of8aQ4pwFJsJd15FGbbZuur7zUdSl2WfL3NM=";
  };
  slirp = fetchFromGitHub {
    owner = "qemu";
    repo = "libslirp";
    rev = "ce94eba2042d52a0ba3d9e252ebce86715e94275";
    hash = "sha256-zRxM5Xe6+1BN9rO1X6rFSbjcfUi+gdCpiS/pL0EK7GY=";
  };
  glib = fetchFromGitHub {
    owner = "GNOME";
    repo = "glib";
    tag = "2.56.1";
    hash = "sha256-GA3l+No/MPr+qGbDWwNY5yyGAIHVlW1NeEnJtGRBI58=";
  };
  libffi = fetchFromGitHub {
    owner = "libffi";
    repo = "libffi";
    tag = "v3.3";
    hash = "sha256-1lqbL/C+WtnOa5DxgT81CGiywzPzBf4pBCWjdI+5oQA=";
  };
  pixman = fetchFromGitLab {
    owner = "pixman";
    repo = "pixman";
    domain = "gitlab.freedesktop.org";
    rev = "pixman-0.40.0";
    hash = "sha256-IDI6cxhED+WbWpBrJWfWMAyyunQ3UZQLe5P/tus0UHg=";
  };
  sdl = fetchFromGitHub {
    owner = "libsdl-org";
    repo = "SDL";
    tag = "release-2.0.8";
    hash = "sha256-GNhbVrzXyVDVgpCuZ54Blf3mk4L8uGpU4hIRW1V9FRw=";
  };

  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-29
    s.build-tools-30-0-3
    s.ndk-26-3-11579264
  ]);
  ndk = "${androidSdk}/share/android-sdk/ndk/26.3.11579264";
  ndkHostTag = if stdenv.hostPlatform.isDarwin then "darwin-x86_64" else "linux-x86_64";
  sysroot = "${ndk}/toolchains/llvm/prebuilt/${ndkHostTag}/sysroot";
  gradle = gradle_7_2;

  nativeRuntime = stdenv.mkDerivation {
    pname = "limbo-tensor-native-runtime";
    inherit version src;
    sourceRoot = "${src.name}";

    __darwinAllowLocalNetworking = true;
    __noChroot = stdenv.hostPlatform.isDarwin;

    nativeBuildInputs = [
      androidSdk
      gnumake
      autoconf
      automake
      libtool
      pkg-config
      gettext
      perl
      python3
      flex
      bison
      texinfo
      rsync
      which
    ];

    postPatch = ''
      jni="$PWD/limbo-android-lib/src/main/jni"
      cp -R ${qemu}/. "$jni/qemu"
      chmod -R u+w "$jni/qemu"
      mkdir -p "$jni/qemu/ui/keycodemapdb"
      cp -R ${keycodemapdb}/. "$jni/qemu/ui/keycodemapdb"
      mkdir -p "$jni/qemu/dtc"
      cp -R ${dtc}/. "$jni/qemu/dtc"
      chmod -R u+w "$jni/qemu/dtc"
      mkdir -p "$jni/qemu/slirp"
      cp -R ${slirp}/. "$jni/qemu/slirp"
      chmod -R u+w "$jni/qemu/slirp"
      cp -R ${glib}/. "$jni/glib"
      cp -R ${libffi}/. "$jni/libffi"
      cp -R ${pixman}/. "$jni/pixman"
      cp -R ${sdl}/. "$jni/SDL2"
      chmod -R u+w "$jni/qemu" "$jni/glib" "$jni/libffi" "$jni/pixman" "$jni/SDL2"

      # Upstream Limbo Tensor (GPL-2.0-only):
      # https://github.com/wasdwasd0105/limbo_tensor
      substituteInPlace "$jni/android-limbo-build.mak" \
        --replace-fail 'SHELL := env PATH=$(PATH) /bin/bash' \
          'SHELL := env PATH=$(PATH) ${bash}/bin/bash'
      # GLib 2.56's pointer atomics trigger newer Clang's Android warning.
      substituteInPlace "$jni/android-config/android-device-config/android-generic.mak" \
        --replace-fail \
          '-Wno-error=declaration-after-statement -Wno-unused-variable' \
          '-Wno-error=declaration-after-statement -Wno-error=int-conversion -Wno-unused-variable'
      # This build uses NDK clang directly, not Limbo's -Wc flag wrapper.
      substituteInPlace "$jni/android-config/android-device-config/android-generic.mak" \
        --replace-fail 'ARCH_LD_CLANG_FLAGS += -Wc,-shared' \
          '# Shared library mode is selected by Autotools libtool.'
      # Limbo's old -Wc linker escapes target GCC; use NDK clang's native flags.
      substituteInPlace "$jni/android-config/android-device-config/android-armv8.mak" \
        --replace-fail \
          'TARGET_PREFIX = aarch64-none-linux-android' \
          'TARGET_PREFIX = aarch64-linux-android' \
        --replace-fail \
          'ARCH_LD_FLAGS += -Wc,-target -Wc,aarch64-none-linux-android$(NDK_PLATFORM_API)' \
          'ARCH_LD_FLAGS += -target aarch64-linux-android$(NDK_PLATFORM_API)' \
        --replace-fail \
          'ARCH_LD_FLAGS += -Wc,-gcc-toolchain -Wc,$(TOOLCHAIN_DIR)' \
          '# The legacy GCC toolchain is not shipped by current NDKs.'
      printf '%s\n' \
        'ac_cv_func__NSGetEnviron=no' \
        'ac_cv_func_fdwalk=no' >> "$jni/patches/android.cache"

      patch -d "$jni/qemu" -p1 < "$jni/patches/qemu-5.1.0.patch"
      # QEMU 5.1.0 Android basename declaration (GPL-2.0-or-later):
      # https://github.com/qemu/qemu/blob/v5.1.0/hw/vfio/pci.c
      patch -d "$jni/qemu" -p1 < ${./qemu-android-basename.patch}
      patch -d "$jni/glib" -p1 < "$jni/patches/glib-2.56.1.patch"
      # GLib 2.56 Android fd_set detection (LGPL-2.1-or-later):
      # https://github.com/GNOME/glib
      patch -d "$jni/glib" -p1 < ${./glib-select-mask.patch}
      patch -d "$jni/SDL2" -p1 < "$jni/patches/sdl2-2.0.8.patch"
      # SDL 2.0.8 Android GL signature compatibility (zlib license):
      # https://github.com/libsdl-org/SDL
      patch -d "$jni/SDL2" -p1 < ${./sdl-clang-compat.patch}
      # Pixman 0.40.0 Clang function-pointer compatibility (MIT license):
      # Pixman project source: https://gitlab.freedesktop.org/pixman/pixman/-/blob/pixman-0.40.0/pixman/pixman-bits-image.c
      # License reference: https://gitlab.freedesktop.org/pixman/pixman/-/blob/pixman-0.40.0/COPYING
      patch -d "$jni/pixman" -p1 < ${./pixman-clang-function-pointer.patch}
      # Limbo Tensor's libffi cross-compiler fix for Android NDK:
      # https://github.com/wasdwasd0105/limbo_tensor (GPL-2.0-only)
      patch -p1 < ${./libffi-android-clang.patch}
      # Invoke libffi's configured Android build directory directly because
      # its old multilib wrapper invents a host target for modern Autotools.
      substituteInPlace "$jni/Makefile" \
        --replace-fail \
          'cd $(LIMBO_JNI_ROOT)/libffi && $(MAKE) -j $(BUILD_THREADS)' \
          'cd $(LIMBO_JNI_ROOT)/libffi/$(GNU_HOST) && $(MAKE) -j $(BUILD_THREADS)'
      substituteInPlace "$jni/Makefile" \
        --replace-fail \
          './configure --host=$(GNU_HOST) --cache-file=android.cache' \
          './configure --disable-shared --enable-static --host=$(GNU_HOST) --cache-file=android.cache' \
        --replace-fail \
          'cp -f glib/glib/.libs/*.so' \
          'cp -f glib/glib/.libs/*.a'
      substituteInPlace "$jni/Makefile" \
        --replace-fail \
          './configure --host=$(GNU_HOST) --with-sysroot=$(SYSROOT)' \
          './configure --disable-shared --enable-static --host=$(GNU_HOST) --with-sysroot=$(SYSROOT)' \
        --replace-fail \
          'cp -f pixman/pixman/.libs/*.so' \
          'cp -f pixman/pixman/.libs/*.a'
      substituteInPlace "$jni/Makefile" \
        --replace-fail \
          "--include='libqemu-system-arm*.so'" \
          "--include='libqemu-system-x86*.so'"
      (cd "$jni/libffi" && autoreconf -fi)
      (cd "$jni/pixman" && autoreconf -fi)
      # Limbo Tensor compatibility fixes for modern Android NDK headers:
      # https://github.com/wasdwasd0105/limbo_tensor (GPL-2.0-only)
      patch -p1 < ${./limbo-compat-clang.patch}
    '';

    dontConfigure = true;
    buildPhase = ''
      runHook preBuild
      sysroot="${sysroot}"
      export ac_cv_c_bigendian=no
      # The upstream make install target syncs every architecture even when
      # only the arm module is included in this source archive.
      for arch in x86 ppc sparc; do
        mkdir -p "limbo-android-$arch/src/main/jniLibs" \
          "limbo-android-$arch/src/main/assets"
      done
      make -C limbo-android-lib/src/main/jni limbo \
        NDK_ROOT="${ndk}" \
        BUILD_HOST=arm64-v8a \
        BUILD_GUEST=x86_64-softmmu \
        NDK_PLATFORM_API=21 \
        SYSROOT="$sysroot" \
        NDK_INCLUDE="$sysroot/usr/include" \
        NDK_SYSROOT="$sysroot" \
        NDK_SYSROOT_INC="-I$sysroot/usr/include" \
        NDK_SYSROOT_ARCH_INC="-I$sysroot/usr/include/aarch64-linux-android" \
        BUILD_THREADS="$NIX_BUILD_CORES"
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -d "$out/jniLibs/arm64-v8a" "$out/assets"
      cp -R limbo-android-lib/src/main/jniLibs/arm64-v8a/. "$out/jniLibs/arm64-v8a/"
      cp -R limbo-android-arm/src/main/jniLibs/arm64-v8a/. "$out/jniLibs/arm64-v8a/"
      cp -R limbo-android-arm/src/main/assets/. "$out/assets/"
      runHook postInstall
    '';

    meta = {
      description = "Limbo Tensor QEMU runtime built from source";
      homepage = "https://github.com/wasdwasd0105/limbo_tensor";
      license = lib.licenses.gpl2Only;
      platforms = lib.platforms.unix;
    };
  };

  appPackage = buildGradlePackage (finalAttrs: {
    pname = "limbo-tensor";
    inherit version src gradle;

    __darwinAllowLocalNetworking = true;
    __noChroot = stdenv.hostPlatform.isDarwin;
    passthru = { inherit nativeRuntime; };
    sourceRoot = "${src.name}";
    gradleBuildFlags = [ ":limbo-android-arm:assembleRelease" ];
    nativeBuildInputs = [
      androidSdk
      gradle
      jdk11_headless
      writableTmpDirAsHomeHook
    ];
    env = {
      ANDROID_HOME = "${androidSdk}/share/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
      JAVA_HOME = jdk11_headless.passthru.home;
      ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/30.0.3/aapt2";
      ORG_GRADLE_PROJECT_android_aapt2FromMavenOverride = "${androidSdk}/share/android-sdk/build-tools/30.0.3/aapt2";
    };
    mitmCache = gradle.fetchDeps {
      pkg = finalAttrs.finalPackage.overrideAttrs (_: {
        preBuild = "";
      });
      data = ./limbo_tensor_deps.json;
    };

    postPatch = ''
            # Upstream Limbo Tensor (GPL-2.0-only):
            # https://github.com/wasdwasd0105/limbo_tensor
      substituteInPlace build.gradle \
        --replace-fail 'jcenter()' 'mavenCentral()'
      substituteInPlace limbo-android-arm/build.gradle \
        --replace-fail 'buildToolsVersion "29.0.3"' 'buildToolsVersion "30.0.3"'
      substituteInPlace limbo-android-lib/build.gradle \
        --replace-fail "buildToolsVersion '29.0.3'" "buildToolsVersion '30.0.3'"
      substituteInPlace limbo-android-lib/build.gradle \
        --replace-fail \
          "'com.android.support:multidex:1.0.3'" \
          "'androidx.multidex:multidex:2.0.0'"
            substituteInPlace limbo-android-arm/build.gradle \
              --replace-fail \
                '"armeabi-v7a","arm64-v8a", "x86", "x86_64"' \
                '"arm64-v8a"'
      if [ "''${IN_GRADLE_UPDATE_DEPS:-0}" = 1 ]; then
        gradleInitScript=${./init-deps.gradle}
        export gradleInitScript
      fi
    '';

    preBuild = ''
      if [ "''${IN_GRADLE_UPDATE_DEPS:-0}" != 1 ]; then
        mkdir -p limbo-android-arm/src/main/jniLibs
        cp -R ${nativeRuntime}/jniLibs/. limbo-android-arm/src/main/jniLibs/
        cp -R ${nativeRuntime}/assets/. limbo-android-arm/src/main/assets/
        chmod -R u+w limbo-android-arm/src/main/assets
      fi
    '';

    gradleFlags = [
      "-Dorg.gradle.java.home=${jdk11_headless.passthru.home}"
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk11_headless.passthru.home}"
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/30.0.3/aapt2"
      "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/30.0.3/aapt2"
      "--no-daemon"
      "--no-watch-fs"
      "-Dorg.gradle.vfs.watch=false"
    ];
    enableParallelBuilding = false;

    preConfigure = ''
      export ANDROID_USER_HOME="$HOME/.android"
      mkdir -p "$ANDROID_USER_HOME"
      echo "sdk.dir=$ANDROID_SDK_ROOT" > local.properties
    '';

    installPhase = ''
      runHook preInstall
      apkPath="$(find limbo-android-arm/build/outputs/apk/release -maxdepth 1 -type f -name '*.apk' -print -quit)"
      test -n "$apkPath"
      install -Dm644 "$apkPath" "$out/limbo-tensor.apk"
      runHook postInstall
    '';

    meta = with lib; {
      sourceProvenance = with sourceTypes; [ fromSource ];
      description = "QEMU and KVM virtual machine manager for Tensor devices, built from source";
      homepage = "https://github.com/wasdwasd0105/limbo_tensor";
      license = licenses.gpl2Only;
      platforms = platforms.unix;
    };
  });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "limbo-tensor.apk";
  signScriptName = "sign-limbo-tensor";
  fdroid = {
    appId = "com.limbo.emu.main.arm";
    metadataYml = ''
      Categories:
        - System
      License: GPL-2.0-only
      SourceCode: https://github.com/wasdwasd0105/limbo_tensor
      IssueTracker: https://github.com/wasdwasd0105/limbo_tensor/issues
      AutoName: Limbo Tensor
      Summary: QEMU and KVM virtual machines on Tensor devices
      Description: |-
        A Limbo QEMU virtual machine manager for Google Tensor devices.
        The Android app and QEMU 5.1.0 runtime are built from pinned source.
    '';
  };
}
