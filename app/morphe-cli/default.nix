{
  lib,
  jdk21,
  gradle-packages,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  writableTmpDirAsHomeHook,
}:
let
  gradle =
    (gradle-packages.mkGradle {
      version = "8.14.3";
      hash = "sha256-vXEQIhNJMGCVbsIp2Ua+7lcVjb2J0OYrkbyg+ixfNTE=";
      defaultJava = jdk21;
    }).wrapped;
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
    data = "morphe-cli_deps.json";
    silent = false;
    useBwrap = false;
  };

  nativeBuildInputs = [
    gradle
    jdk21
    makeWrapper
    writableTmpDirAsHomeHook
  ];

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk21}" else "${jdk21}/lib/openjdk";
  };

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
    description = "Console / terminal patching tool for Android apps";
    homepage = "https://github.com/MorpheApp/morphe-cli";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
    mainProgram = "morphe-cli";
  };
})
