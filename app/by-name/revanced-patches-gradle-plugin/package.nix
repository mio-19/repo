{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle_9_3_1,
  jdk17,
  writableTmpDirAsHomeHook,
}:
let
  gradle = gradle_9_3_1;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "revanced-patches-gradle-plugin";
  version = "1.0.0-dev.10";

  src = fetchFromGitHub {
    owner = "ReVanced";
    repo = "revanced-patches-gradle-plugin";
    rev = "v${finalAttrs.version}";
    hash = "sha256-HWbj3tMWr0SSk/9IBGFz7Ia/mfDsfHyamvYuF9wD5Z4=";
  };

  gradleBuildTask = "publish";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    pname = "revanced-patches-gradle-plugin";
    pkg = finalAttrs.finalPackage;
    data = ./revanced-patches-gradle-plugin_deps.json;
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk17
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk17}" else "${jdk17}/lib/openjdk";
  };

  postUnpack = ''
        patch -d "$sourceRoot" -p1 < ${./revanced-patches-gradle-plugin-lazy-manifest.patch}

        substituteInPlace "$sourceRoot/build.gradle.kts" \
          --replace-fail '            maven {
                    name = "githubPackages"
                    url = uri("https://maven.pkg.github.com/revanced/revanced-patches-gradle-plugin")
                    credentials(PasswordCredentials::class)
                }' '            maven { url = uri("file://" + rootProject.projectDir.resolve("build/m2").absolutePath) }'

        substituteInPlace "$sourceRoot/build.gradle.kts" \
          --replace-fail '    signAllPublications()
        extensions.getByType<SigningExtension>().useGpgCmd()
    ' ""

        substituteInPlace "$sourceRoot/src/main/kotlin/app/revanced/patches/gradle/SettingsPlugin.kt" \
          --replace-fail '            maven { repository ->
                    repository.name = "githubPackages"
                    // A repository must be specified. "revanced" is a dummy.
                    repository.url = URI("https://maven.pkg.github.com/revanced/revanced")
                    repository.credentials(PasswordCredentials::class.java)
                }' '            maven { repository ->
                    repository.name = "revancedLocal"
                    repository.url = URI("file://" + (System.getenv("REVANCED_M2_REPO")
                        ?: settings.rootDir.resolve(".m2/repository").absolutePath))
                }'

        substituteInPlace "$sourceRoot/src/main/kotlin/app/revanced/patches/gradle/PatchesPlugin.kt" \
          --replace-fail '                publishingExtension.repositories.mavenLocal {
                        it.name = "DummyMavenLocal"
                    }' '                publishingExtension.repositories.maven {
                        it.name = "LocalBuildMaven"
                        it.url = uri("file://" + rootProject.projectDir.resolve("build/m2").absolutePath)
                    }'

        substituteInPlace "$sourceRoot/src/main/kotlin/app/revanced/patches/gradle/PatchesPlugin.kt" \
          --replace-fail '            extension.signAllPublications()
                extensions.getByType<SigningExtension>().useGpgCmd()
    ' ""
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
    description = "ReVanced patches Gradle plugin published to a local Maven repository";
    homepage = "https://github.com/ReVanced/revanced-patches-gradle-plugin";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
  };
})
