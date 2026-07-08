{
  gradle_5_6_4,
  gradle_6_3_0,
  jdk11_headless,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  runtimeShell,
  unzip,
}:
let
  gradle = gradle_6_3_0;
  gradleFetchDeps = gradle_5_6_4.fetchDeps;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "gradle-unwrapped";
  version = "6.4.1";

  src = fetchFromGitHub {
    owner = "gradle";
    repo = "gradle";
    tag = "v6.4.1";
    hash = "sha256-15FyAP7nzD8AoyNR9XJgaxlJS2kbackKLhrTGsB20uM=";
  };

  gradleBuildTask = ":distributions:binZip";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  nativeBuildInputs = [
    gradle_5_6_4
    gradle
    makeWrapper
    jdk11_headless
    unzip
  ];

  patches = [
    ./bootstrap-disable-buildscan.patch
    ./bootstrap-disable-docs-samples.patch
    ./bootstrap-disable-dist-docs.patch
    ./bootstrap-disable-precompiled-groovy-plugins.patch
    ./bootstrap-disable-validate-plugins.patch
    ./bootstrap-root-repositories.patch
    ./bootstrap-settings-plugins.patch
  ];
  patchFlags = [ "-p1" ];

  mitmCache = gradleFetchDeps {
    inherit (finalAttrs) pname;
    pkg = finalAttrs.finalPackage;
    data = ./deps.json;
    silent = false;
    useBwrap = false;
  };

  __darwinAllowLocalNetworking = true;

  env.JAVA_HOME = jdk11_headless.passthru.home;

  preBuild = ''
    export HOME="$PWD/.home"
    export GRADLE_USER_HOME="$HOME/.gradle"
    export LANG=C.UTF-8
    export LC_ALL=C.UTF-8
    mkdir -p "$GRADLE_USER_HOME"
    export GRADLE_OPTS="-Xmx4096m -XX:MaxMetaspaceSize=1024m -Dfile.encoding=UTF-8 -Dkotlin.compiler.execution.strategy=in-process -Dkotlin.daemon.enabled=false ''${GRADLE_OPTS:-}"
    cat > "$GRADLE_USER_HOME/gradle.properties" <<EOF
    org.gradle.daemon=false
    org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m -Dfile.encoding=UTF-8 -Dkotlin.compiler.execution.strategy=in-process -Dkotlin.daemon.enabled=false
    org.gradle.workers.max=1
    kotlin.compiler.execution.strategy=in-process
    kotlin.daemon.enabled=false
    kotlin.incremental=false
    EOF
  '';

  gradleFlags = [
    "-PfinalRelease=true"
    "--no-daemon"
    "--no-parallel"
    "--max-workers=1"
    "--no-build-cache"
    "--stacktrace"
    "-Dorg.gradle.vfs.watch=false"
    "-Dorg.gradle.java.installations.auto-download=false"
    "-Dorg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
  ];

  gradleUpdateScript = ''
    runHook preBuild
    tmpbin="$(mktemp -d)"
    tee > "$tmpbin/gradlecustom" <<EOF
    #!${runtimeShell}
    exec ${gradle}/bin/gradle ''${gradleFlags[@]} ''${gradleFlagsArray[@]} "\$@"
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
    exec ${gradle}/bin/gradle ''${gradleFlags[@]} ''${gradleFlagsArray[@]} "\$@"
    EOF
    chmod +x "$tmpbin/gradlecustom"
    export PATH="$tmpbin:$PATH"
    gradlecustom ${finalAttrs.gradleBuildTask}
    runHook postBuild
  '';

  postPatch = ''
    rm -f gradle/verification-metadata.xml
    rm -fr gradle/wrapper .teamcity/.mvn/wrapper
    find . -name "*.jar" -print0 | xargs -0 rm -f
    substituteInPlace buildSrc/settings.gradle.kts \
      --replace-fail \
        '        gradlePluginPortal()' \
        '        maven { url = uri("https://plugins.gradle.org/m2/") }
            gradlePluginPortal()'
    substituteInPlace buildSrc/build.gradle.kts \
      --replace-fail \
        '        gradlePluginPortal()' \
        '        mavenCentral()
            maven { url = uri("https://plugins.gradle.org/m2/") }
            gradlePluginPortal()'
    substituteInPlace buildSrc/subprojects/performance/performance.gradle.kts \
      --replace-fail \
        'org.codehaus.groovy.modules.http-builder:http-builder:0.7.2' \
        'org.codehaus.groovy.modules.http-builder:http-builder:0.7.1'
    substituteInPlace gradle/dependencies.gradle \
      --replace-fail \
        "libraries.jcifs =               [coordinates: 'org.samba.jcifs:jcifs', version: '1.3.17', license: \"LGPL 2.1\"]" \
        "libraries.jcifs =               [coordinates: 'jcifs:jcifs', version: '1.3.17', license: \"LGPL 2.1\"]"
  '';

  installPhase = ''
    runHook preInstall

    dist_zip="$(find . -path '*/build/distributions/gradle-*-bin.zip' | grep '/distributions/' | head -n1)"
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

  passthru = {
    inherit (finalAttrs) mitmCache;
    fetchDeps = gradleFetchDeps;
  };
})
