{
  gradle_5_6_4,
  gradle_6_7_1,
  git,
  jdk11_headless,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  runtimeShell,
  unzip,
}:
let
  gradle = gradle_6_7_1;
  gradleFetchDeps = gradle_5_6_4.fetchDeps;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "gradle-unwrapped";
  version = "6.8.3";

  src = fetchFromGitHub {
    owner = "gradle";
    repo = "gradle";
    tag = "v6.8.3";
    hash = "sha256-bAVL0dsS9PbHY+6rroK2v8QIf++cZ9dwBeS+9onuMNg=";
  };

  gradleBuildTask = ":distributions-full:binDistributionZip";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  nativeBuildInputs = [
    gradle_5_6_4
    gradle
    git
    makeWrapper
    jdk11_headless
    unzip
  ];

  patches = [
    ./bootstrap-disable-buildscan.patch
    ./bootstrap-disable-build-init-samples.patch
    ./bootstrap-disable-docs-samples.patch
    ./bootstrap-disable-validate-plugins.patch
    ./bootstrap-disable-installation-variants.patch
    ./bootstrap-gradle-6-6-runner-buildscan-watchfs.patch
    ./bootstrap-gradle-6-5-runner-shaded-jar.patch
    ./bootstrap-root-repositories.patch
    ./bootstrap-settings-plugins.patch
    ./bootstrap-disable-configuration-cache-report.patch
    ./bootstrap-kotlin-dsl-flatmap-inference.patch
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
    substituteInPlace buildSrc/subprojects/build-platform/build.gradle.kts \
      --replace-fail \
        'org.codehaus.groovy.modules.http-builder:http-builder:0.7.2' \
        'org.codehaus.groovy.modules.http-builder:http-builder:0.7.1'
    substituteInPlace buildSrc/subprojects/dependency-modules/src/main/kotlin/gradlebuild/modules/extension/ExternalModulesExtension.kt \
      --replace-fail \
        'val jcifs = "org.samba.jcifs:jcifs"' \
        'val jcifs = "jcifs:jcifs"'
    substituteInPlace buildSrc/subprojects/jvm/build.gradle.kts \
      --replace-fail \
        'com.gradle.enterprise:test-distribution-gradle-plugin:1.1.2-rc-1' \
        'com.gradle.enterprise:test-distribution-gradle-plugin:1.1'
    substituteInPlace buildSrc/subprojects/uber-plugins/src/main/kotlin/gradlebuild.kotlin-library.gradle.kts \
      --replace-fail \
        'kotlinOptions.allWarningsAsErrors = true' \
        'kotlinOptions.allWarningsAsErrors = false'
    substituteInPlace subprojects/configuration-cache/src/main/kotlin/org/gradle/configurationcache/serialization/codecs/DefaultResolvableArtifactCodec.kt \
      --replace-fail \
        'calculatedValueContainerFactory.create(Describables.of(artifactId), file)' \
        'calculatedValueContainerFactory.create(Describables.of(artifactId), java.util.function.Supplier { file })'
    substituteInPlace subprojects/configuration-cache/src/main/kotlin/org/gradle/configurationcache/serialization/codecs/transform/CalculateArtifactsCodec.kt \
      --replace-fail \
        'calculatedValueContainerFactory.create(Describables.of(artifactId), file)' \
        'calculatedValueContainerFactory.create(Describables.of(artifactId), java.util.function.Supplier { file })'
    substituteInPlace subprojects/configuration-cache/src/main/kotlin/org/gradle/configurationcache/serialization/codecs/transform/TransformedArtifactCodec.kt \
      --replace-fail \
        'calculatedValueContainerFactory.create(Describables.of(artifactId), file)' \
        'calculatedValueContainerFactory.create(Describables.of(artifactId), java.util.function.Supplier { file })'
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
