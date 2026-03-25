{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle-packages,
  jdk21,
  python3,
  androidSdkBuilder,
  writableTmpDirAsHomeHook,
  morphe-patches-gradle-plugin,
  morphe-library-m2,
  apktool-src,
  multidexlib2-src,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-33
    s.platforms-android-34
    s.platforms-android-35
    s.build-tools-34-0-0
    s.build-tools-35-0-0
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.14.4";
      hash = "sha256-8XcSmKcPbbWina9iN4xOGKF/wzybprFDYuDN9AYQOA0=";
      defaultJava = jdk21;
    }).wrapped;

  morphe-patcher-src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "morphe-patcher";
    rev = "v1.3.2";
    hash = "sha256-KxWdkgiRN4mFb4auibSpMKUydE7ZaAMPGhow7Pq5Y1A=";
  };

  arsclib-src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "ARSCLib";
    rev = "9696ffecda";
    hash = "sha256-DOMVxqbp9B11BhhJZ209oTLcSJv04uj2aMkK41TVFGQ=";
  };

in
stdenv.mkDerivation (finalAttrs: {
  pname = "morphe-patches";
  version = "1.21.1";

  src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "morphe-patches";
    rev = "v${finalAttrs.version}";
    hash = "sha256-l/R/ZH6dsSlcaOuiNUEse0mwG1a1gHnOCNnZBk3IlGo=";
  };

  gradleBuildTask = "generatePatchesList";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    pname = "morphe-patches";
    pkg = finalAttrs.finalPackage;
    data = ./morphe-patches_deps.json;
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk21
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk21}" else "${jdk21}/lib/openjdk";
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
    MORPHE_PLUGIN_M2 = "${morphe-patches-gradle-plugin}";
    MORPHE_LIBRARY_M2 = "${morphe-library-m2}";
  };

  postUnpack = ''
    root="$PWD"
    cp -a ${morphe-patcher-src} "$root/morphe-patcher"
    chmod -R u+w "$root/morphe-patcher"
    cp -a ${arsclib-src} "$root/ARSCLib"
    chmod -R u+w "$root/ARSCLib"
    cp -a ${apktool-src} "$root/Apktool"
    chmod -R u+w "$root/Apktool"

    cp -a ${multidexlib2-src} "$root/multidexlib2"
    chmod -R u+w "$root/multidexlib2"

    patch -d "$sourceRoot" -p0 < ${./morphe-patches-settings.patch}
    patch -d "$root/morphe-patcher" -p0 < ${./morphe-patcher.patch}
    patch -d "$root/morphe-patcher" -p0 < ${./morphe-patcher-settings.patch}

    cat >> "$sourceRoot/settings.gradle.kts" << 'EOF'

    // Added by Nix build: include ARSCLib as composite build.
    val arsclibDir = file("../ARSCLib")
    if (arsclibDir.exists()) {
        includeBuild(arsclibDir) {
            dependencySubstitution {
                substitute(module("com.github.MorpheApp:ARSCLib")).using(project(":"))
            }
        }
    }
    EOF

    cat >> "$sourceRoot/patches/build.gradle.kts" << 'EOF'

    tasks.withType<org.gradle.jvm.tasks.Jar>().configureEach {
        manifest {
            attributes(
                "Name" to "Morphe Patches",
                "Description" to "Patches for Morphe",
                "Version" to project.version.toString(),
                "Timestamp" to "0",
                "Source" to "git@github.com:MorpheApp/morphe-patches.git",
                "Author" to "MorpheApp",
                "Contact" to "na",
                "Website" to "https://morphe.software",
                "License" to "GNU General Public License v3.0, with additional GPL section 7 requirements",
            )
        }
    }
    EOF
  '';

  preConfigure = ''
    export ANDROID_USER_HOME="$HOME/.android"
    mkdir -p "$ANDROID_USER_HOME"
    echo "sdk.dir=${androidSdk}/share/android-sdk" > local.properties
  '';

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
    "-Dmaven.repo.local=build/m2"
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    install -Dm644 "patches/build/libs/patches-${finalAttrs.version}.mpp" \
      "$out/patches-${finalAttrs.version}.mpp"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Morphe Patches built from source";
    homepage = "https://github.com/MorpheApp/morphe-patches";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
})
