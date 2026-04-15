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
  srcOnly,
  applyPatches,
}:
# https://github.com/NixOS/nixpkgs/blob/4ed2dff2b5c2970997ed3a12aae50181a352f719/doc/languages-frameworks/gradle.section.md
stdenv.mkDerivation (
  finalAttrs:
  let
    androidLauncherDir = "platform/android/luajit-launcher";
    repos = import ./repos.nix { inherit fetchgit; };
    repos-replace = repo: ''--replace-quiet "${repo.url}" "${repo}" '';
    androidSdk = androidSdkBuilder (s: [
      s.cmdline-tools-latest
      s.platform-tools
      s.platforms-android-34
      s.platforms-android-30
      s.build-tools-34-0-0
      s.ndk-26-1-10909125
    ]);
    # upstream use older 8.x : https://github.com/koreader/android-luajit-launcher/blob/dc24a50aae4f69dd3a9708e8eb8e141b5e1c1c03/gradle/wrapper/gradle-wrapper.properties
    gradle = gradle_8_14_3;
    androidNdkVersion = "26.1.10909125";
    androidArch = "arm64";
    androidFlavor = "Fdroid";
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
  {
    pname = "koreader";
    version = "2026.03";
    src = fetchFromGitHub {
      name = "koreader";
      owner = "koreader";
      repo = "koreader";
      tag = "v${finalAttrs.version}";
      leaveDotGit = true;
      hash = "sha256-Ww2DBPkr7Q5Is+HHrmjt9WfIordHRGdMuunFfB+G2hg=";
      fetchSubmodules = true;
    };
    sourceRoot = "${finalAttrs.src.name}";
    postPatch = ''
      substituteInPlace $(find . -name CMakeLists.txt) ${lib.concatMapStrings repos-replace repos}
    '';

    passthru.srcOnly = srcOnly finalAttrs.finalPackage;
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
    # $(nix build .#apk_koreader-wip.mitmCache.updateScript --no-link --print-out-paths)
    mitmCache = gradle.fetchDeps {
      inherit (finalAttrs) pname;
      pkg = finalAttrs.finalPackage;
      data = ./deps.json;
      silent = false;
      useBwrap = false;
    };
    dontUseCmakeConfigure = true;
    dontUseMesonConfigure = true;

    gradleFlags = [
      "-Dorg.gradle.java.installations.auto-download=false"
      "-Dorg.gradle.java.installations.paths=${jdk17_headless}"
      "-Dorg.gradle.jvmargs=-Xmx4g"
      "-p"
      androidLauncherDir
      "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
    ];

    gradleUpdateScript = ''
      runHook preBuild
      # gradle --write-verification-metadata sha256
      ${fhsEnv}/bin/koreader-build-env -c "
        set -e
        bash ./kodev release -i android-${androidArch}
      "
    '';

  }
)
