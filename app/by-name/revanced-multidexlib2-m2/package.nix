{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle-packages,
  jdk17_headless,
  writableTmpDirAsHomeHook,
}:
let
  gradle =
    (gradle-packages.mkGradle {
      version = "8.2.1";
      hash = "sha256-A+wXbTiPKqmd78rcOsat+N0rzlFFoSlllTfAh03qWtE=";
      defaultJava = jdk17_headless;
    }).wrapped;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "revanced-multidexlib2-m2";
  version = "3.0.3.r3";

  src = fetchFromGitHub {
    owner = "ReVanced";
    repo = "multidexlib2";
    rev = "v${finalAttrs.version}";
    hash = "sha256-gu9a8hgpstMrhDMj8uN0Ly5IIjO0pQlZ+sjNdXt+Sqk=";
  };

  gradleBuildTask = "publish";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    pname = "revanced-multidexlib2";
    pkg = finalAttrs.finalPackage;
    data = ./revanced-multidexlib2_deps.json;
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk17_headless
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk17_headless}" else "${jdk17_headless}/lib/openjdk";
  };

  postUnpack = ''
        substituteInPlace "$sourceRoot/build.gradle" \
          --replace-fail 'publishing {
        publications {
            gpr(MavenPublication) {
                artifactId = mainArtifact
                from components.java
                pom {
                    name = artifactName
                    configurePom it
                }
            }
        }
    }' 'publishing {
        repositories {
            maven { url = uri(layout.buildDirectory.dir("m2")) }
        }
        publications {
            gpr(MavenPublication) {
                artifactId = mainArtifact
                from components.java
                pom {
                    name = artifactName
                    configurePom it
                }
            }
        }
    }'
  '';

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -a build/m2/. "$out/"
    runHook postInstall
  '';

  meta = with lib; {
    description = "ReVanced multidexlib2 artifacts published to a local Maven repository";
    homepage = "https://github.com/ReVanced/multidexlib2";
    license = licenses.gpl3Plus;
    platforms = platforms.unix;
  };
})
