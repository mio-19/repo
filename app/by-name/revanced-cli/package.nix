{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle_9_3_1,
  jdk17_headless,
  makeWrapper,
  writableTmpDirAsHomeHook,
  revanced-library-m2,
  revanced-patcher-m2,
}:
let
  gradle = gradle_9_3_1;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "revanced-cli";
  version = "6.0.0";

  src = fetchFromGitHub {
    owner = "ReVanced";
    repo = "revanced-cli";
    rev = "v${finalAttrs.version}";
    hash = "sha256-2PdEFEZk8HWJVPQ3n4O783B3w4S8RL+XYEgI4NgZVmk=";
  };

  gradleBuildTask = "shadowJar";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  mitmCache = gradle.fetchDeps {
    pname = "revanced-cli";
    pkg = finalAttrs.finalPackage;
    data = ./revanced-cli_deps.json;
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk17_headless
    makeWrapper
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk17_headless}" else "${jdk17_headless}/lib/openjdk";
  };

  postUnpack = ''
    mkdir -p "$sourceRoot/.m2/repository"
    cp -a ${revanced-library-m2}/* "$sourceRoot/.m2/repository/"
    chmod -R u+w "$sourceRoot/.m2/repository"
    cp -a ${revanced-patcher-m2}/* "$sourceRoot/.m2/repository/"
    chmod -R u+w "$sourceRoot/.m2/repository"

    substituteInPlace "$sourceRoot/settings.gradle.kts" \
      --replace-fail '            url = uri("https://maven.pkg.github.com/revanced/cli")' \
      '            url = uri("file://" + rootProject.projectDir.resolve(".m2/repository").absolutePath)'
    substituteInPlace "$sourceRoot/settings.gradle.kts" \
      --replace-fail '            credentials(PasswordCredentials::class)' ""

    printf '%s\n' 'tasks.withType<org.gradle.plugins.signing.Sign>().configureEach { enabled = false }' >> "$sourceRoot/build.gradle.kts"
  '';

  gradleFlags = [
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
  ];

  installPhase = ''
    runHook preInstall

    jar_path="$(find build/libs -name '*-all.jar' | head -n 1)"
    test -n "$jar_path"
    install -Dm644 "$jar_path" "$out/share/revanced-cli/revanced-cli.jar"

    makeWrapper ${jdk17_headless}/bin/java "$out/bin/revanced-cli" \
      --add-flags "-jar $out/share/revanced-cli/revanced-cli.jar"

    runHook postInstall
  '';

  meta = with lib; {
    description = "ReVanced CLI built from source";
    homepage = "https://github.com/ReVanced/revanced-cli";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
    mainProgram = "revanced-cli";
  };
})
