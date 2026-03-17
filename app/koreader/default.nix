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

in
stdenv.mkDerivation (finalAttrs: {
  pname = "koreader-android";
  version = "2025.10";

  src = fetchFromGitHub {
    repo = "koreader";
    owner = "koreader";
    rev = "ccabe19ba77fdf4a32ea39c62bc8264949013fa1";
    fetchSubmodules = true;
    hash = "sha256-9tk2rJHivVJHcJGPVVpgjk9kIfZ2IzYqjpMyDYGrvgU=";
  };

  # Only enable mitmCache when the json exists. Otherwise we can just
  # run the update script manually.
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
        
        # Actually, CMake downloads without the quotes, let's use a simpler sed:
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            name: tarball:
            if tarball != null then
              ''
                find base/thirdparty -type f \( -name "CMakeLists.txt" -o -name "*.cmake" \) -print0 | xargs -0 sed -i 's|${depsJson.${name}.url}|file://'"$PWD"'/offline-tarballs/${name}-${
                  baseNameOf depsJson.${name}.url
                }|g'
              ''
            else
              ""
          ) fetchedDeps
        )}

        sed -i -e 's#\$(ANDROID_LAUNCHER_DIR)/gradlew#gradle#' make/android.mk

        # Prevent koenv.sh from actually running git clone or checkout.
        cat << 'EOFkoenv' >> base/thirdparty/cmake_modules/koenv.sh
    clone_git_repo() { (
        repo="''$1"
        mkdir -p "''${repo%/*}"
        if [ -d "''${repo}" ]; then return 0; fi
        cp -a "''$GIT_DEPS/''${project}" "''$repo"
        chmod -R u+w "''$repo"
    ); }

    checkout_git_repo() { (
        tree="''$1"
        repo="''$2"
        rm -rf "''$tree"
        cp -a "''$repo" "''$tree"
        chmod -R u+w "''$tree"
    ); }
    EOFkoenv

        cat << 'EOF' > base/meson-native.ini
    [binaries]
    c = 'cc'
    cpp = 'c++'
    ar = 'ar'
    strip = 'strip'
    pkgconfig = 'pkg-config'
    EOF

        sed -i -e "s|--wrap-mode=nodownload|--wrap-mode=nodownload --native-file=$PWD/base/meson-native.ini|g" base/cmake/CMakeLists.txt

        sed -i -e 's|HOSTCC|HOSTCC_IGNORE|g' base/thirdparty/luajit/CMakeLists.txt
        sed -i -e 's|assert_var_defined(HOSTCC_IGNORE)|set(HOSTCC "cc")|' base/thirdparty/luajit/CMakeLists.txt

        patchShebangs --build .
  '';

  # Wait, koreader Android build is 'ANDROID_FLAVOR=fdroid ./kodev release android-arm64'.
  buildPhase = ''
    runHook preBuild
    export TARGET=android
    export ANDROID_ARCH=arm64
    export ANDROID_FLAVOR=fdroid
    export GIT_DEPS=${gitDepsDir}
    patchShebangs ./kodev
    bash ./kodev release -i android-arm64
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
