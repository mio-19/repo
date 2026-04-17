{
  fetchFromGitHub,
  gradle_3_0,
  jdk8_headless,
  makeWrapper,
  runtimeShell,
  stdenv,
  unzip,
}:
let
  gradleRunner = gradle_3_0;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "gradle";
  version = "3.5.1";

  src = fetchFromGitHub {
    owner = "gradle";
    repo = "gradle";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Z/l0RhNaWRWyUekvbh8+juAKgJjVbn175cA2vtrPIDU=";
  };

  gradleBuildTask = ":distributions:binZip";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  nativeBuildInputs = [
    gradleRunner
    jdk8_headless
    makeWrapper
    unzip
  ];

  patches = [ ./bootstrap-old-gradle-compat.patch ];
  patchFlags = [ "-p1" ];

  mitmCache = gradleRunner.fetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = ./deps.json;
    silent = false;
    useBwrap = false;
  };

  __darwinAllowLocalNetworking = true;

  env.JAVA_HOME = jdk8_headless.passthru.home;

  preBuild = ''
    export HOME="$PWD/.home"
    export GRADLE_USER_HOME="$HOME/.gradle"
    mkdir -p "$GRADLE_USER_HOME"
    cat > "$GRADLE_USER_HOME/gradle.properties" <<'EOF'
    org.gradle.daemon=false
    org.gradle.jvmargs=-Xmx1024m -Dfile.encoding=UTF-8
    EOF
  '';

  gradleFlags = [
    "-PfinalRelease=true"
    "-PbootstrapWithGradle3_0=true"
    "-DbootstrapWithGradle3_0=true"
    "-Dfile.encoding=UTF-8"
  ];

  postPatch = ''
    rm -f gradle/verification-metadata.xml
    rm -rf gradle/wrapper .teamcity/.mvn/wrapper
    find . -name "*.jar" -print0 | xargs -0 rm -f
  '';

  gradleUpdateScript = ''
    runHook preBuild
    tmpbin="$(mktemp -d)"
    tee > "$tmpbin/gradlecustom" <<EOF
    #!${runtimeShell}
    exec ${gradleRunner}/bin/gradle ''${gradleFlags[@]} ''${gradleFlagsArray[@]} "\$@"
    EOF
    chmod +x "$tmpbin/gradlecustom"
    export PATH="$tmpbin:$PATH"
    gradlecustom ${finalAttrs.gradleUpdateTask}
    runHook postGradleUpdate
  '';

  buildPhase = ''
    runHook preBuild
    tmpbin="$(mktemp -d)"
    tee > "$tmpbin/gradlecustom" <<EOF
    #!${runtimeShell}
    exec ${gradleRunner}/bin/gradle ''${gradleFlags[@]} ''${gradleFlagsArray[@]} "\$@"
    EOF
    chmod +x "$tmpbin/gradlecustom"
    export PATH="$tmpbin:$PATH"
    gradlecustom ${finalAttrs.gradleBuildTask}
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    distZip="$(find . -path '*/build/distributions/gradle-*-bin.zip' | head -n1)"
    test -n "$distZip"
    test -f "$distZip"

    mkdir dist-unpack
    unzip -q "$distZip" -d dist-unpack
    cd dist-unpack/gradle-*

    mkdir -p "$out/libexec/gradle" "$out/bin"
    mv lib "$out/libexec/gradle/"
    mv bin "$out/libexec/gradle/"

    makeWrapper "$out/libexec/gradle/bin/gradle" "$out/bin/gradle" \
      --set-default JAVA_HOME "${finalAttrs.env.JAVA_HOME}"

    runHook postInstall
  '';
})
