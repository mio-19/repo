{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle-packages,
  jdk25,
  androidSdkBuilder,
  writableTmpDirAsHomeHook,
  morphe-patches-gradle-plugin,
  morphe-library-m2,
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
    s.build-tools-34-0-0
    s.build-tools-35-0-0
  ]);

  gradle =
    (gradle-packages.mkGradle {
      version = "8.14.4";
      hash = "sha256-8XcSmKcPbbWina9iN4xOGKF/wzybprFDYuDN9AYQOA0=";
      defaultJava = jdk25;
    }).wrapped;

  arsclib-src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "ARSCLib";
    rev = "d003b5ff1ca91fb8c5105619cf1108b450387061";
    hash = "sha256-2UO6zDAFeURrt9U9f7gNDA8J5X3o8Ct96/rItUq644g=";
  };

in
stdenv.mkDerivation (finalAttrs: {
  pname = "brosssh-patches";
  version = "2.2.0";

  src = fetchFromGitHub {
    owner = "brosssh";
    repo = "morphe-patches";
    rev = "v${finalAttrs.version}";
    hash = "sha256-K5u/5S77ETBGZxGvHyuTyu7H/XZ13Yw+G39+Iv27kIc=";
  };

  gradleBuildTask = "generatePatchesList";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

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

    // Added by Nix build: include morphe-patcher as composite build
    val patcherDir = file("../morphe-patcher")
    if (patcherDir.exists()) {
        includeBuild(patcherDir) {
            dependencySubstitution {
                substitute(module("app.morphe:morphe-patcher")).using(project(":"))
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
                "Source" to "git@github.com:brosssh/morphe-patches.git",
                "Author" to "brosssh",
                "Contact" to "na",
                "Website" to "https://github.com/brosssh/morphe-patches",
                "License" to "GNU General Public License v3.0, with additional GPL section 7 requirements",
            )
        }
    }
    EOF
  '';

  # Use fetchDeps for gradle dependency caching - the deps file is copied to sourceRoot in postUnpack
  mitmCache = gradle.fetchDeps {
    pname = "brosssh-patches";
    pkg = finalAttrs.finalPackage;
    data = ./morphe-patches_deps.json;
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk25
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk25}" else "${jdk25}/lib/openjdk";
    ANDROID_HOME = "${androidSdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
    ANDROID_AAPT2_FROM_MAVEN_OVERRIDE = "${androidSdk}/share/android-sdk/build-tools/35.0.0/aapt2";
    MORPHE_PLUGIN_M2 = "${morphe-patches-gradle-plugin}";
    MORPHE_LIBRARY_M2 = "${morphe-library-m2}";
  };

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
    description = "Morphe Patches built from brosssh fork";
    homepage = "https://github.com/brosssh/morphe-patches";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
})
