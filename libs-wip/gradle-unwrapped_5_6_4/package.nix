{
  gradle_5_6_4,
  gradle_8_14_4,
  jdk11_headless,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  runtimeShell,
}:
let
  gradleRunner = gradle_5_6_4;
  gradleFetchDeps = gradle_8_14_4.fetchDeps;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "gradle-unwrapped";
  version = "5.6.4";

  src = fetchFromGitHub {
    owner = "gradle";
    repo = "gradle";
    rev = "v${finalAttrs.version}";
    hash = "sha256-sGLAyKn2PVIp4OBe1rvhU7Tact4cHvF9iaIlSZ4bGYE=";
  };

  gradleBuildTask = ":distributions-full:binDistributionZip";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  nativeBuildInputs = [
    gradleRunner
    makeWrapper
    jdk11_headless
  ];

  mitmCache = gradleFetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = ./deps.json;
    silent = false;
    useBwrap = false;
  };

  __darwinAllowLocalNetworking = true;

  env = {
    JAVA_HOME = if stdenv.isDarwin then "${jdk11_headless}" else "${jdk11_headless}/lib/openjdk";
  };

  preBuild = ''
    export HOME="$PWD/.home"
    mkdir -p "$HOME"
    echo "org.gradle.jvmargs=" >> gradle.properties
    export GRADLE_OPTS="-Dorg.gradle.jvmargs="
  '';

  gradleFlags = [
    "-PfinalRelease=true"
    "--no-daemon"
    "--no-build-cache"
    "-Dorg.gradle.vfs.watch=false"
    "-Dfile.encoding=UTF-8"
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
  ];

  postPatch = ''
    rm -f gradle/verification-metadata.xml
    rm -fr gradle/wrapper .teamcity/.mvn/wrapper
    find . -name "*.jar" -print0 | xargs -0 rm -f

    substituteInPlace subprojects/kotlin-dsl-plugins/src/main/kotlin/org/gradle/kotlin/dsl/plugins/dsl/KotlinDslCompilerPlugins.kt \
      --replace-fail \
      'fun KotlinCompile.applyExperimentalWarning(experimentalWarning: Boolean) {' \
      'fun KotlinCompile.applyExperimentalWarning(experimentalWarning: Boolean) {
    val taskLogger = logger as? ContextAwareTaskLogger ?: return'
    substituteInPlace subprojects/kotlin-dsl-plugins/src/main/kotlin/org/gradle/kotlin/dsl/plugins/dsl/KotlinDslCompilerPlugins.kt \
      --replace-fail \
      'KotlinCompilerWarningSubstitutingLogger(logger as ContextAwareTaskLogger, project.toString(), project.experimentalWarningLink)' \
      'KotlinCompilerWarningSubstitutingLogger(taskLogger, project.toString(), project.experimentalWarningLink)'
    substituteInPlace subprojects/kotlin-dsl-plugins/src/main/kotlin/org/gradle/kotlin/dsl/plugins/dsl/KotlinDslCompilerPlugins.kt \
      --replace-fail \
      'KotlinCompilerWarningSilencingLogger(logger as ContextAwareTaskLogger)' \
      'KotlinCompilerWarningSilencingLogger(taskLogger)'
  '';

  gradleUpdateScript = ''
    runHook preBuild
    tmpbin=$(mktemp -d)
    tee > "$tmpbin/gradlecustom" << EOF
    #! ${runtimeShell}
    exec ${gradleRunner}/bin/gradle ''${gradleFlags[@]} ''${gradleFlagsArray[@]} "\$@"
    EOF
    chmod +x "$tmpbin/gradlecustom"
    export PATH="$tmpbin:$PATH"
    gradlecustom ${finalAttrs.gradleUpdateTask}
    runHook postGradleUpdate
  '';

  buildPhase = ''
    runHook preBuild
    tmpbin=$(mktemp -d)
    tee > "$tmpbin/gradlecustom" << EOF
    #! ${runtimeShell}
    exec ${gradleRunner}/bin/gradle ''${gradleFlags[@]} ''${gradleFlagsArray[@]} "\$@"
    EOF
    chmod +x "$tmpbin/gradlecustom"
    export PATH="$tmpbin:$PATH"
    gradlecustom ${finalAttrs.gradleBuildTask}
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    dist_zip="$(find . -path '*/build/distributions/gradle-*-bin.zip' | grep '/distributions-full/' | head -n1)"
    test -n "$dist_zip"
    test -f "$dist_zip"

    mkdir dist-unpack
    unzip -q "$dist_zip" -d dist-unpack
    cd dist-unpack/gradle-*

    mkdir -p "$out/libexec/gradle" "$out/bin"
    mv lib "$out/libexec/gradle/"
    mv bin "$out/libexec/gradle/"

    makeWrapper "$out/libexec/gradle/bin/gradle" "$out/bin/gradle" \
      --set-default JAVA_HOME "${finalAttrs.env.JAVA_HOME}"

    runHook postInstall
  '';
})
