{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle-packages,
  jdk21,
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

  # https://github.com/crimera/piko/blob/e0d2a7be9bb92173825bb7043cd9ed92986132b9/gradle/libs.versions.toml#L2
  morphe-patcher-src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "morphe-patcher";
    rev = "v1.3.3";
    hash = "sha256-ehKW9/jlhhz2eGYEnioB6etq1gvH7eNroLw+yW8h3l0=";
  };

  arsclib-src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "ARSCLib";
    rev = "9696ffecda";
    hash = "sha256-DOMVxqbp9B11BhhJZ209oTLcSJv04uj2aMkK41TVFGQ=";
  };

in
stdenv.mkDerivation (finalAttrs: {
  pname = "piko-patches";
  version = "3.1.0-dev.4";

  src = fetchFromGitHub {
    owner = "crimera";
    repo = "piko";
    rev = "v${finalAttrs.version}";
    hash = "sha256-oyg1AitCu8su2bsyAzUH9+w4zzMuwY9OMgm6IsK0XAY=";
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

        substituteInPlace "$sourceRoot/settings.gradle.kts" \
          --replace-fail 'id("app.morphe.patches") version "1.1.1"' 'id("app.morphe.patches") version "1.2.0"' \
          --replace-fail '
            maven {
                name = "GitHubPackages"
                url = uri("https://maven.pkg.github.com/MorpheApp/registry")
                credentials {
                    username = providers.gradleProperty("gpr.user").getOrElse(System.getenv("GITHUB_ACTOR"))
                    password = providers.gradleProperty("gpr.key").getOrElse(System.getenv("GITHUB_TOKEN"))
                }
            }
    ' '
            maven { url = uri("file://" + System.getenv("MORPHE_PLUGIN_M2")) }
            maven { url = uri("file://" + System.getenv("MORPHE_LIBRARY_M2")) }
    '
        patch -d "$root/morphe-patcher" -p0 < ${./morphe-patcher.patch}
        patch -d "$root/morphe-patcher" -p0 < ${./morphe-patcher-settings.patch}

        printf '%s\n' \
          "" \
          '    // Added by Nix build: include ARSCLib as composite build.' \
          '    val arsclibDir = file("../ARSCLib")' \
          '    if (arsclibDir.exists()) {' \
          '        includeBuild(arsclibDir) {' \
          '            dependencySubstitution {' \
          '                substitute(module("com.github.MorpheApp:ARSCLib")).using(project(":"))' \
          '            }' \
          '        }' \
          '    }' \
          "" \
          '    // Added by Nix build: include morphe-patcher as composite build.' \
          '    val patcherDir = file("../morphe-patcher")' \
          '    if (patcherDir.exists()) {' \
          '        includeBuild(patcherDir) {' \
          '            dependencySubstitution {' \
          '                substitute(module("app.morphe:morphe-patcher")).using(project(":"))' \
          '            }' \
          '        }' \
          '    }' \
          >> "$sourceRoot/settings.gradle.kts"
  '';

  mitmCache = gradle.fetchDeps {
    pname = "piko-patches";
    pkg = finalAttrs.finalPackage;
    data = ./piko-patches_deps.json;
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
    description = "Piko Morphe patches for Twitter/X";
    homepage = "https://github.com/crimera/piko";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
})
