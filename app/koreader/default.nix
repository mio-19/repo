{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  fetchgit,
  androidSdkBuilder,
  gradle-packages,
  jdk17,
  git,
  cmake,
  ninja,
  pkg-config,
  autoconf,
  automake,
  libtool,
  gettext,
  m4,
  which,
  python3,
  apksigner,
  writableTmpDirAsHomeHook,
  unzip,
  util-linux,
  meson,
  curl,
  buildPackages,
  bash,
  buildFHSEnv,
}:

let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-34
    s.platforms-android-30
    s.build-tools-34-0-0
    s.ndk-26-1-10909125
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.14.3";
      hash = "sha256-vXEQIhNJMGCVbsIp2Ua+7lcVjb2J0OYrkbyg+ixfNTE=";
      defaultJava = jdk17;
    }).wrapped;

  depsJson = builtins.fromJSON (builtins.readFile ./koreader_deps.json);

  fetchedDeps = lib.mapAttrs (
    name: info:
    if info ? hash then
      fetchurl {
        inherit (info) url hash;
      }
    else
      null
  ) depsJson;

  gitDepsDir = stdenv.mkDerivation {
    name = "koreader-git-deps";
    buildCommand = ''
      mkdir -p $out
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: info: ''
          cp -a ${
            fetchgit {
              inherit (info) url rev;
              sha256 = info.hash;
              fetchSubmodules = true;
            }
          } $out/${name}
        '') (depsJson.git or { })
      )}
    '';
  };

  # Wrap the build in an FHS environment so that thirdparty build scripts
  # that use #!/usr/bin/env shebangs can find the standard /usr/bin/env.
  fhsEnv = buildFHSEnv {
    name = "koreader-build-env";
    targetPkgs =
      p: with p; [
        git
        cmake
        ninja
        pkg-config
        autoconf
        automake
        libtool
        gettext
        m4
        which
        python3
        unzip
        util-linux
        meson
        curl
        bash
        jdk17
        apksigner
        p7zip
        buildPackages.stdenv.cc
      ];
    runScript = "${bash}/bin/bash";
  };

in
stdenv.mkDerivation (finalAttrs: {
  pname = "koreader-android";
  version = "2026.03";

  # Source refresh steps:
  # 1. Keep `tag = "v${finalAttrs.version}"`.
  # 2. Set `hash = lib.fakeHash`, run:
  #      nix build .#packages.x86_64-linux.koreader
  #    then copy the reported "got:" hash here.
  src = fetchFromGitHub {
    repo = "koreader";
    owner = "koreader";
    tag = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-KWpWlFoBEAhVDuRTiF7yj1wlKLzYmvcngI9iWqsDuQY=";
  };

  # Gradle lock refresh:
  #   nix build --impure .#packages.x86_64-linux.koreader.mitmCache.updateScript
  # then run the produced fetch-deps.sh with `outPath` set to:
  #   /home/dev/Documents/repo/app/koreader/koreader_gradle_deps.json
  #
  # Thirdparty lock refresh:
  # - refresh URLs + hashes from current KOReader source:
  #     python app/koreader/refresh-thirdparty-lock.py \
  #       --create-if-missing \
  #       --source "$(nix eval --raw .#packages.x86_64-linux.koreader.src.outPath)"
  # - for git deps (depsJson.git), bump rev/hash entries manually as needed.
  mitmCache =
    if builtins.pathExists ./koreader_gradle_deps.json then
      gradle.fetchDeps {
        inherit (finalAttrs) pname;
        pkg = finalAttrs.finalPackage;
        data = "koreader_gradle_deps.json";
        silent = false;
        useBwrap = false;
      }
    else
      null;

  nativeBuildInputs = [
    git
    cmake
    ninja
    pkg-config
    autoconf
    automake
    libtool
    gettext
    m4
    which
    python3
    unzip
    gradle
    jdk17
    apksigner
    writableTmpDirAsHomeHook
    util-linux
    meson
    curl
    buildPackages.stdenv.cc
    bash
  ];

  dontUseCmakeConfigure = true;
  dontUseMesonConfigure = true;

  env = {
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk/26.1.10909125";
    JAVA_HOME = jdk17;
    CC_FOR_BUILD = "${buildPackages.stdenv.cc}/bin/cc";
    CXX_FOR_BUILD = "${buildPackages.stdenv.cc}/bin/c++";
    LD_FOR_BUILD = "${buildPackages.stdenv.cc}/bin/ld";
    AR_FOR_BUILD = "${buildPackages.stdenv.cc.bintools.bintools}/bin/ar";
    PKG_CONFIG_FOR_BUILD = "${buildPackages.pkg-config}/bin/pkg-config";
  };

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${jdk17}"
    "-Dorg.gradle.jvmargs=-Xmx4g"
    "-p"
    "platform/android/luajit-launcher"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
  ];

  gradleUpdateTask = "assemble";

  # The task wrapper calls ./gradlew inside luajit-launcher/Makefile.
  # We should patch it to call gradle directly.
  postPatch = ''
    # Many thirdparty build scripts use #!/usr/bin/env python3 shebangs.
    # buildFHSEnv in buildPhase provides /usr/bin/env for those scripts.
    mkdir -p offline-tarballs
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: tarball:
        if tarball != null then
          ''
            ln -s ${tarball} offline-tarballs/${name}-${baseNameOf depsJson.${name}.url}
          ''
        else
          ""
      ) fetchedDeps
    )}

    # Patch thirdparty download URLs to local offline tarballs.
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: tarball:
        if tarball != null then
          ''
            while IFS= read -r cmakeFile; do
              substituteInPlace "$cmakeFile" \
                --replace-fail \
                  '${depsJson.${name}.url}' \
                  'file://'"$PWD"'/offline-tarballs/${name}-${baseNameOf depsJson.${name}.url}'
            done < <(grep -rlF '${depsJson.${name}.url}' base/thirdparty --include='CMakeLists.txt' --include='*.cmake' || true)
          ''
        else
          ""
      ) fetchedDeps
    )}

    substituteInPlace make/android.mk \
      --replace-fail \
        '$(ANDROID_LAUNCHER_DIR)/gradlew' \
        'gradle'

    # Inject offline mitmCache local maven repos into gradle build files
    # so that gradle resolves all dependencies from the nix store.
    substituteInPlace platform/android/luajit-launcher/build.gradle \
      --replace-fail \
        'google()' \
        'maven { url = uri("${finalAttrs.mitmCache}/https/dl.google.com/dl/android/maven2") }
        maven { url = uri("${finalAttrs.mitmCache}/https/maven.google.com") }
        maven { url = uri("${finalAttrs.mitmCache}/https/repo.maven.apache.org/maven2") }
        google()'
    substituteInPlace platform/android/luajit-launcher/app/build.gradle \
      --replace-fail \
        'google()' \
        'maven { url = uri("${finalAttrs.mitmCache}/https/dl.google.com/dl/android/maven2") }
        maven { url = uri("${finalAttrs.mitmCache}/https/maven.google.com") }
        maven { url = uri("${finalAttrs.mitmCache}/https/repo.maven.apache.org/maven2") }
        google()'
    # Also add --offline to GRADLE_FLAGS so gradle won't try the network
    substituteInPlace make/android.mk \
      --replace-fail \
        '$(GRADLE_FLAGS)' \
        '$(GRADLE_FLAGS) --offline --no-daemon'

    # The Nix sandbox has no git history; replace git-based version commands
    # with hardcoded values matching the package version.
    substituteInPlace Makefile \
      --replace-fail \
        'VERSION := $(shell git describe HEAD)' \
        'VERSION := ${finalAttrs.version}'
    substituteInPlace make/android.mk \
      --replace-fail \
        'ANDROID_VERSION ?= $(shell git rev-list --count HEAD)' \
        'ANDROID_VERSION ?= 202603'
    substituteInPlace make/android.mk \
      --replace-fail \
        'cp $(ANDROID_LAUNCHER_BUILD)/outputs/apk/$(ANDROID_ARCH)$(ANDROID_FLAVOR)/$(if $(KODEBUG),debug,release)/NativeActivity.apk $(ANDROID_APK)' \
        'apk_path="$$(find $(ANDROID_LAUNCHER_BUILD)/outputs/apk -type f -path "*/arm64*/fdroid*/release/NativeActivity.apk" | head -n 1)"; if [ -z "$$apk_path" ]; then apk_path="$$(find $(ANDROID_LAUNCHER_BUILD)/outputs/apk -type f -name NativeActivity.apk | head -n 1)"; fi; test -n "$$apk_path"; cp "$$apk_path" $(ANDROID_APK)'

    # Prevent koenv.sh from actually running git clone or checkout.
    cat ${./koenv-git.sh} >> base/thirdparty/cmake_modules/koenv.sh

    cp ${./meson-native.ini} base/meson-native.ini

    substituteInPlace base/cmake/CMakeLists.txt \
      --replace-fail \
        '--wrap-mode=nodownload' \
        "--wrap-mode=nodownload --native-file=$PWD/base/meson-native.ini"

    # gen-hb-version.py tries to write hb-version.h back into the source
    # tree; if that copy fails the script exits non-zero and meson reports
    # "Could not execute command". Provide a patch that removes the copy-back
    # section, and register it in the PATCH_FILES list so apply_patches runs
    # "patch -p1" on the extracted harfbuzz source before meson configure.
    cp ${./harfbuzz-no-source-copy.patch} base/thirdparty/harfbuzz/harfbuzz-no-source-copy.patch
    substituteInPlace base/thirdparty/harfbuzz/CMakeLists.txt \
      --replace-fail \
        'no-subset.patch' \
        'no-subset.patch
    harfbuzz-no-source-copy.patch'

    # LuaJIT uses CROSS+CC for the cross-compiler (TARGET_CC), so CC must be
    # "clang" to form "aarch64-linux-android21-clang". But HOST_CC (used to
    # compile host tools minilua/buildvm) must be the native build compiler
    # since NDK's clang is an Android cross-compiler without Linux headers.
    substituteInPlace base/thirdparty/luajit/CMakeLists.txt \
      --replace-fail \
        'set(HOST_CC ''${HOSTCC})' \
        'if(DEFINED ENV{CC_FOR_BUILD})
      set(HOST_CC $ENV{CC_FOR_BUILD})
    else()
      set(HOST_CC ''${HOSTCC})
    endif()'

    # chmlib's ffs() is only included on __sun || __sgi; Android clang
    # fails with -Wimplicit-function-declaration. Add strings.h unconditionally.
    substituteInPlace base/thirdparty/kpvcrlib/crengine/thirdparty/chmlib/src/chm_lib.c \
      --replace-fail \
        '#if __sun || __sgi
#include <strings.h>
#endif' \
        '#include <strings.h>'

    # Guard menu container and tab-index accesses to avoid top-menu tap crashes.
    patch -p1 --input ${./readermenu-topbar-crash-guard.patch}

  '';

  # Wait, koreader Android build is 'ANDROID_FLAVOR=fdroid ./kodev release android-arm64'.
  buildPhase = ''
    runHook preBuild
    ${fhsEnv}/bin/koreader-build-env -c "
      set -e
      export TARGET=android
      export ANDROID_ARCH=arm64
      export ANDROID_FLAVOR=fdroid
      export GIT_DEPS=${gitDepsDir}
      export ANDROID_HOME=${androidSdk}/share/android-sdk
      export ANDROID_SDK_ROOT=${androidSdk}/share/android-sdk
      export ANDROID_NDK_HOME=${androidSdk}/share/android-sdk/ndk/26.1.10909125
      export JAVA_HOME=${jdk17}
      export CC_FOR_BUILD=${buildPackages.stdenv.cc}/bin/cc
      export CXX_FOR_BUILD=${buildPackages.stdenv.cc}/bin/c++
      export LD_FOR_BUILD=${buildPackages.stdenv.cc}/bin/ld
      export AR_FOR_BUILD=${buildPackages.stdenv.cc.bintools.bintools}/bin/ar
      export PKG_CONFIG_FOR_BUILD=${buildPackages.pkg-config}/bin/pkg-config
      export PATH=${androidSdk}/share/android-sdk/ndk/26.1.10909125/toolchains/llvm/prebuilt/linux-x86_64/bin:\$PATH
      cd $PWD
      bash ./kodev release -i android-arm64
    "
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 koreader-android-*.apk $out/koreader.apk
    runHook postInstall
  '';

  meta = with lib; {
    description = "KOReader for Android";
    homepage = "https://github.com/koreader/koreader";
    license = licenses.agpl3Only;
    platforms = platforms.unix;
  };

  passthru = {
    mitmCache = finalAttrs.mitmCache;
  };
})
