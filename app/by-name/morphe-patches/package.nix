{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle_9_3_1,
  jdk21_headless,
  androidSdkBuilder,
  writableTmpDirAsHomeHook,
  morphe-patches-gradle-plugin_1_3_2,
  morphe-library-m2,
  morphe-patches-library-m2_1_0_4,
  apktool-src,
  multidexlib2-src,
  morphe-patcher-src,
}:
let
  androidSdk = androidSdkBuilder (s: [
    s.cmdline-tools-latest
    s.platform-tools
    s.platforms-android-33
    s.platforms-android-34
    s.platforms-android-35
    s.platforms-android-36
    s.build-tools-34-0-0
    s.build-tools-35-0-0
    s.build-tools-36-0-0
  ]);

  gradle = gradle_9_3_1;

  arsclib-src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "ARSCLib";
    rev = "d003b5ff1ca91fb8c5105619cf1108b450387061";
    hash = "sha256-2UO6zDAFeURrt9U9f7gNDA8J5X3o8Ct96/rItUq644g=";
  };

in
stdenv.mkDerivation (finalAttrs: {
  pname = "morphe-patches";
  version = "1.24.0";

  src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "morphe-patches";
    rev = "v${finalAttrs.version}";
    hash = "sha256-yL92TEcXh3IhtCRbqd+AkpZesqXtSp29iLpL8drs1co=";
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
    jdk21_headless
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = jdk21_headless.passthru.home;
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2";
    MORPHE_PLUGIN_M2 = "${morphe-patches-gradle-plugin_1_3_2}";
    MORPHE_LIBRARY_M2 = "${morphe-library-m2}";
    MORPHE_PATCHES_LIBRARY_M2 = "${morphe-patches-library-m2_1_0_4}";
  };

  postUnpack = ''
    root="$PWD"
    cp -a ${morphe-patcher-src} "$root/morphe-patcher"
    chmod -R u+w "$root/morphe-patcher"
    cp -a ${arsclib-src} "$root/ARSCLib"
    chmod -R u+w "$root/ARSCLib"
    cp -a ${apktool-src} "$root/Apktool"
    chmod -R u+w "$root/Apktool"
    patch -d "$root/Apktool" -p3 < ${../brosssh-patches/apktool-gradle-9.patch}

    cp -a ${multidexlib2-src} "$root/multidexlib2"
    chmod -R u+w "$root/multidexlib2"
    patch -d "$root/multidexlib2" -p3 < ${../brosssh-patches/multidexlib2-gradle-9.patch}

    patch -d "$sourceRoot" -p0 < ${./morphe-patches-settings.patch}

    cat >> "$sourceRoot/build.gradle.kts" << 'EOF'

    allprojects {
        repositories {
            mavenLocal()
            maven { url = rootProject.layout.buildDirectory.dir("m2").get().asFile.toURI() }
            mavenCentral()
            google()
            maven { url = uri("file://" + System.getenv("MORPHE_PLUGIN_M2")) }
            maven { url = uri("file://" + System.getenv("MORPHE_LIBRARY_M2")) }
            maven { url = uri("file://" + System.getenv("MORPHE_PATCHES_LIBRARY_M2")) }
            maven { url = uri("https://jitpack.io") }
        }
    }
    EOF

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
    "-Dandroid.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/share/android-sdk/build-tools/36.0.0/aapt2"
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
