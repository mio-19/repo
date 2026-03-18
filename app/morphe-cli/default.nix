{
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  writableTmpDirAsHomeHook,
  git,
  morphe-library-m2,
}:
let
  gradle =
    (gradle-packages.mkGradle {
      version = "8.14.3";
      hash = "sha256-vXEQIhNJMGCVbsIp2Ua+7lcVjb2J0OYrkbyg+ixfNTE=";
      defaultJava = jdk21;
    }).wrapped;

  # -- Dependency sources (all from GitHub) ----------------------------------

  morphe-patcher-src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "morphe-patcher";
    rev = "v1.2.0";
    hash = "sha256-xsdSxEGd77FANKqL/IvBu4UGTa88MOS2cu/J29YRp44=";
  };

  apktool-src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "Apktool";
    rev = "04517bc7c687a6cfdcd813abb02e3134487baa95"; # branch 2.11.2
    hash = "sha256-dgrjGXGJ86RDjBFB//1rOy7m1uxh3j3ZuXHRgRmLneQ=";
  };

  multidexlib2-src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "multidexlib2";
    rev = "41cccc644cf1804362f7aa2fae96a6ffe67ffd22";
    hash = "sha256-NBubLnNjkZbGFlSCkwbTdvjDeYdRn4xJBJUNCCs/ccU=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "morphe-cli";
  version = "1.5.0";

  src = fetchFromGitHub {
    owner = "MorpheApp";
    repo = "morphe-cli";
    rev = "v${finalAttrs.version}";
    hash = "sha256-00muzlayNnZnSKc+bPL9q7924uln6NLkfs+Mf3AfkCQ=";
  };

  gradleBuildTask = "shadowJar";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = ./morphe-cli_deps.json;
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk21
    makeWrapper
    writableTmpDirAsHomeHook
    git
  ];

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk21}" else "${jdk21}/lib/openjdk";
  };

  # Set up the workspace: arrange all dependency sources as sibling directories,
  # patch out all GitHub Packages repositories, and configure composite builds.
  postUnpack = ''
    root="$PWD"

    # Copy dependency sources as writable sibling directories.
    cp -a ${morphe-patcher-src} "$root/morphe-patcher"
    chmod -R u+w "$root/morphe-patcher"

    cp -a ${apktool-src} "$root/Apktool"
    chmod -R u+w "$root/Apktool"

    cp -a ${multidexlib2-src} "$root/multidexlib2"
    chmod -R u+w "$root/multidexlib2"

    # Set up local maven repo with pre-built morphe-library (from separate derivation).
    mkdir -p "$root/.m2/repository"
    cp -a ${morphe-library-m2}/* "$root/.m2/repository/"

    # ---- Patch GitHub Packages repos out of build.gradle files ----

    # morphe-cli: replace GitHub Packages with local maven repo
    substituteInPlace "$sourceRoot/build.gradle.kts" \
      --replace-fail '    maven {
        // A repository must be specified for some reason. "registry" is a dummy.
        url = uri("https://maven.pkg.github.com/MorpheApp/registry")
        credentials {
            username = project.findProperty("gpr.user") as String? ?: System.getenv("GITHUB_ACTOR")
            password = project.findProperty("gpr.key") as String? ?: System.getenv("GITHUB_TOKEN")
        }
    }' '    maven { url = uri("file://" + rootProject.projectDir.resolve("../.m2/repository").absolutePath) }'

    # morphe-patcher: replace GitHub Packages with local maven repo
    substituteInPlace "$root/morphe-patcher/build.gradle.kts" \
      --replace-fail '    maven {
        // A repository must be specified for some reason. "registry" is a dummy.
        url = uri("https://maven.pkg.github.com/MorpheApp/registry")
        credentials {
            username = project.findProperty("gpr.user") as String? ?: System.getenv("GITHUB_ACTOR")
            password = project.findProperty("gpr.key") as String? ?: System.getenv("GITHUB_TOKEN")
        }
    }' '    maven { url = uri("file://" + rootProject.projectDir.resolve("../.m2/repository").absolutePath) }'

    # ---- Fix morphe-patcher composite build for multidexlib2 ----
    substituteInPlace "$root/morphe-patcher/settings.gradle.kts" \
      --replace-fail '"multidexlib2" to "app.morphe:multidexlib"' \
                     '"multidexlib2" to "app.morphe:multidexlib2"'

    # ---- Add Apktool as composite build in morphe-patcher ----
    cat >> "$root/morphe-patcher/settings.gradle.kts" << 'APKTOOL_EOF'

    // Added by Nix build: include Apktool as composite build
    val apktoolDir = file("../Apktool")
    if (apktoolDir.exists()) {
        includeBuild(apktoolDir) {
            dependencySubstitution {
                substitute(module("app.morphe:apktool-lib")).using(project(":brut.apktool:apktool-lib"))
                substitute(module("app.morphe:brut.j.common")).using(project(":brut.j.common"))
                substitute(module("app.morphe:brut.j.util")).using(project(":brut.j.util"))
                substitute(module("app.morphe:brut.j.dir")).using(project(":brut.j.dir"))
                substitute(module("app.morphe:brut.j.xml")).using(project(":brut.j.xml"))
            }
        }
    }
    APKTOOL_EOF

    # ---- Remove morphe-library from composite builds (use pre-built m2 instead) ----
    # morphe-cli settings tries to include morphe-library as composite but KMP
    # JVM variant can't be substituted that way. Remove it.
    substituteInPlace "$sourceRoot/settings.gradle.kts" \
      --replace-fail '"morphe-library" to "app.morphe:morphe-library",' ""

    # ---- Disable signing tasks (no GPG in sandbox) ----
    echo 'tasks.withType<Sign> { enabled = false }' >> "$sourceRoot/build.gradle.kts"
    echo 'tasks.withType<Sign> { enabled = false }' >> "$root/morphe-patcher/build.gradle.kts"
  '';

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
  ];

  installPhase = ''
    runHook preInstall

    jar_path="$(find build/libs -name '*-all.jar' | head -n 1)"
    test -n "$jar_path" && test -f "$jar_path"
    install -Dm644 "$jar_path" "$out/share/morphe-cli/morphe-cli.jar"

    makeWrapper ${jdk21}/bin/java $out/bin/morphe-cli \
      --add-flags "-jar $out/share/morphe-cli/morphe-cli.jar"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Console / terminal patching tool for Android apps (built from source)";
    homepage = "https://github.com/MorpheApp/morphe-cli";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
    mainProgram = "morphe-cli";
  };
})
