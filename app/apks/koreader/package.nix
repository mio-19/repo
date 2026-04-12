{
  mk-apk-package,
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  fetchgit,
  androidSdkBuilder,
  gradle_8_14_3,
  jdk17_headless,
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
  appPackage =
    let
      androidSdk = androidSdkBuilder (s: [
        s.cmdline-tools-latest
        s.platform-tools
        s.platforms-android-34
        s.platforms-android-30
        s.build-tools-34-0-0
        # Tried NDK 27.3.13750724 here, but KOReader's android-luajit-launcher
        # still uses ALooper_pollAll, which the newer headers mark unavailable,
        # so this stays on the baseline NDK until the native source is updated.
        s.ndk-26-1-10909125
      ]);

      gradle = gradle_8_14_3;

      androidArch = "arm64";
      androidFlavor = "Fdroid";
      androidNdkVersion = "26.1.10909125";
      androidVersionCode = "202603";
      androidReleaseEpoch = "2026-03-17 12:03:27 +0100";
      androidLauncherDir = "platform/android/luajit-launcher";
      androidGradleTask = "app:assemble${androidArch}${androidFlavor}Release";

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
            jdk17_headless

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
      #      nix build .#apk_koreader.src
      #    then copy the reported "got:" hash here.
      src = fetchFromGitHub {
        repo = "koreader";
        owner = "koreader";
        tag = "v${finalAttrs.version}";
        fetchSubmodules = true;
        hash = "sha256-KWpWlFoBEAhVDuRTiF7yj1wlKLzYmvcngI9iWqsDuQY=";
      };

      # Gradle lock refresh:
      #   nix build --impure .#apk_koreader.mitmCache.updateScript
      # then run the produced fetch-deps.sh with `outPath` set to:
      #   /home/dev/Documents/repo/app/by-name-apk/koreader/koreader_gradle_deps.json
      #
      # Thirdparty lock refresh:
      # - refresh URLs + hashes from current KOReader source:
      #     python app/by-name-apk/koreader/refresh-thirdparty-lock.py \
      #       --create-if-missing \
      #       --source "$(nix build .#apk_koreader.src --no-link --print-out-paths)"
      # - for git deps (depsJson.git), bump rev/hash entries manually as needed.
      mitmCache =
        if builtins.pathExists ./koreader_gradle_deps.json then
          gradle.fetchDeps {
            inherit (finalAttrs) pname;
            pkg = finalAttrs.finalPackage;
            data = ./koreader_gradle_deps.json;
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
        jdk17_headless

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
        ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk/${androidNdkVersion}";
        JAVA_HOME = jdk17_headless;
        CC_FOR_BUILD = "${buildPackages.stdenv.cc}/bin/cc";
        CXX_FOR_BUILD = "${buildPackages.stdenv.cc}/bin/c++";
        LD_FOR_BUILD = "${buildPackages.stdenv.cc}/bin/ld";
        AR_FOR_BUILD = "${buildPackages.stdenv.cc.bintools.bintools}/bin/ar";
        PKG_CONFIG_FOR_BUILD = "${buildPackages.pkg-config}/bin/pkg-config";
      };

      gradleFlags = [
        "-xlintVitalRelease"
        "-Dorg.gradle.java.installations.auto-download=false"
        "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
        "-Dorg.gradle.jvmargs=-Xmx4g"
        "-p"
        androidLauncherDir
        "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
      ];

      gradleUpdateTask = androidGradleTask;

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
            'pushd $(ANDROID_LAUNCHER_DIR); gradle'
        substituteInPlace make/android.mk \
          --replace-fail \
            "'app:assemble\$(ANDROID_ARCH)\$(ANDROID_FLAVOR)\$(if \$(KODEBUG),Debug,Release)'" \
            "'app:assemble\$(ANDROID_ARCH)\$(ANDROID_FLAVOR)\$(if \$(KODEBUG),Debug,Release)'; popd"

        # Inject offline mitmCache local maven repos into gradle build files
        # so that gradle resolves all dependencies from the nix store.
        substituteInPlace ${androidLauncherDir}/build.gradle \
          --replace-fail \
            'google()' \
            'maven { url = uri("${finalAttrs.mitmCache}/https/dl.google.com/dl/android/maven2") }
            maven { url = uri("${finalAttrs.mitmCache}/https/maven.google.com") }
            maven { url = uri("${finalAttrs.mitmCache}/https/repo.maven.apache.org/maven2") }
            google()'
        substituteInPlace ${androidLauncherDir}/app/build.gradle \
          --replace-fail \
            'google()' \
            'maven { url = uri("${finalAttrs.mitmCache}/https/dl.google.com/dl/android/maven2") }
            maven { url = uri("${finalAttrs.mitmCache}/https/maven.google.com") }
            maven { url = uri("${finalAttrs.mitmCache}/https/repo.maven.apache.org/maven2") }
            google()'
        substituteInPlace ${androidLauncherDir}/app/build.gradle \
          --replace-fail \
            "ndkVersion '23.2.8568313'" \
            "ndkVersion '${androidNdkVersion}'"
        echo >> ${androidLauncherDir}/gradle.properties
        echo 'org.gradle.jvmargs=-Xmx4g' >> ${androidLauncherDir}/gradle.properties
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
            'ANDROID_VERSION ?= ${androidVersionCode}'
        substituteInPlace make/android.mk \
          --replace-fail \
            "--epoch=\"\$\$(git show -s --format='%ci')\" " \
            '--epoch="${androidReleaseEpoch}" '

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

      '';

      # Keep `-i` here because `kodev release` otherwise updates the l10n
      # submodule over the network, which is not allowed in the Nix build.
      buildPhase = ''
        runHook preBuild
        ${fhsEnv}/bin/koreader-build-env -c "
          set -e
          export TARGET=android
          export ANDROID_ARCH=${androidArch}
          export ANDROID_FLAVOR=${androidFlavor}
          export GIT_DEPS=${gitDepsDir}
          export ANDROID_HOME=${androidSdk}/share/android-sdk
          export ANDROID_SDK_ROOT=${androidSdk}/share/android-sdk
          export ANDROID_NDK_HOME=${androidSdk}/share/android-sdk/ndk/${androidNdkVersion}
          export JAVA_HOME=${jdk17_headless}
          export CC_FOR_BUILD=${buildPackages.stdenv.cc}/bin/cc
          export CXX_FOR_BUILD=${buildPackages.stdenv.cc}/bin/c++
          export LD_FOR_BUILD=${buildPackages.stdenv.cc}/bin/ld
          export AR_FOR_BUILD=${buildPackages.stdenv.cc.bintools.bintools}/bin/ar
          export PKG_CONFIG_FOR_BUILD=${buildPackages.pkg-config}/bin/pkg-config
          export PATH=${androidSdk}/share/android-sdk/ndk/${androidNdkVersion}/toolchains/llvm/prebuilt/linux-x86_64/bin:\$PATH
          cd $PWD
          bash ./kodev release -i android-${androidArch}
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
    });
in
mk-apk-package {
  inherit appPackage;
  mainApk = "koreader.apk";
  signScriptName = "sign-koreader";
  fdroid = {
    appId = "org.koreader.launcher.fdroid";
    metadataYml = ''
      Categories:
        - Reading
      License: AGPL-3.0-only
      SourceCode: https://github.com/koreader/koreader
      IssueTracker: https://github.com/koreader/koreader/issues
      AutoName: KOReader
      Summary: Ebook reader optimized for e-ink and Android devices
      Description: |-
        KOReader is a document reader supporting EPUB, PDF, DJVU and more.
        This package is built from source.
    '';
  };
}
