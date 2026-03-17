{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
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
  
  fetchedDeps = lib.mapAttrs (name: info: 
    if info ? hash then
      fetchurl {
        inherit (info) url hash;
      }
    else null
  ) depsJson;

in stdenv.mkDerivation (finalAttrs: {
  pname = "koreader-android";
  version = "2025.10";

  src = fetchFromGitHub {
    repo = "koreader";
    owner = "koreader";
    tag = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-uYKN5fgIdCVH+pXU2lmsGu7HxZbDld5EJVO9o7Tk8BA=";
  };

  # Only enable mitmCache when the json exists. Otherwise we can just
  # run the update script manually.
  mitmCache = if builtins.pathExists ./koreader_gradle_deps.json then gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = "koreader_gradle_deps.json";
    silent = false;
    useBwrap = false;
  } else null;

  nativeBuildInputs = [
    git cmake ninja pkg-config autoconf automake libtool gettext m4 which python3 unzip
    gradle jdk17 apksigner writableTmpDirAsHomeHook util-linux
  ];

  dontUseCmakeConfigure = true;

  env = {
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk/26.1.10909125";
    JAVA_HOME = jdk17;
  };

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${jdk17}"
    "-Dorg.gradle.jvmargs=-Xmx4g"
    "-p" "platform/android/luajit-launcher"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/34.0.0/aapt2"
  ];
  
  gradleUpdateTask = "assemble";

  # The task wrapper calls ./gradlew inside luajit-launcher/Makefile.
  # We should patch it to call gradle directly.
  postPatch = ''
    mkdir -p offline-tarballs
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: tarball: 
      if tarball != null then ''
        ln -s ${tarball} offline-tarballs/${name}-${baseNameOf depsJson.${name}.url}
      '' else ""
    ) fetchedDeps)}
    
    # Actually, CMake downloads without the quotes, let's use a simpler sed:
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: tarball: 
      if tarball != null then ''
        find base/thirdparty -type f \( -name "CMakeLists.txt" -o -name "*.cmake" \) -print0 | xargs -0 sed -i 's|${depsJson.${name}.url}|file://'"$PWD"'/offline-tarballs/${name}-${baseNameOf depsJson.${name}.url}|g'
      '' else ""
    ) fetchedDeps)}

    sed -i -e 's#\$(ANDROID_LAUNCHER_DIR)/gradlew#gradle#' make/android.mk

    patchShebangs .
  '';

  # Wait, koreader Android build is 'ANDROID_FLAVOR=fdroid ./kodev release android'.
  buildPhase = ''
    runHook preBuild
    export TARGET=android
    export ANDROID_ARCH=arm64
    export ANDROID_FLAVOR=fdroid
    ./kodev release android
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
