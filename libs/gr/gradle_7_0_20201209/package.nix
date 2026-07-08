{
  gradle_5_6_4,
  gradle_6_8_20201204,
  git,
  jdk11_headless,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  runtimeShell,
  unzip,
}:
let
  gradle = gradle_6_8_20201204;
  gradleFetchDeps = gradle_5_6_4.fetchDeps;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "gradle-unwrapped";
  version = "7.0-20201209";

  src = fetchFromGitHub {
    owner = "gradle";
    repo = "gradle";
    rev = "cf12e8a29a0";
    hash = "sha256-u3RWs8kLYEsUVb4ktQONLRSmAfHDF4Z+2xep7iaQRvA=";
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
    "-Dorg.gradle.internal.plugins.portal.url.override=https://plugins.gradle.org/m2/"
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

                substituteInPlace settings.gradle.kts \
                  --replace-fail \
                    '        gradlePluginPortal()' \
                    '        maven { url = uri("https://plugins.gradle.org/m2/") }
                        gradlePluginPortal()'
                substituteInPlace build-logic/settings.gradle.kts \
                  --replace-fail \
                    '        gradlePluginPortal()' \
                    '        maven { url = uri("https://plugins.gradle.org/m2/") }
                        gradlePluginPortal()'
            substituteInPlace build-logic/build-platform/build.gradle.kts \
              --replace-fail \
                'org.codehaus.groovy.modules.http-builder:http-builder:0.7.2' \
                'org.codehaus.groovy.modules.http-builder:http-builder:0.7.1'
            substituteInPlace build-logic/build-platform/build.gradle.kts \
              --replace-fail \
                'com.gradle.enterprise:test-distribution-gradle-plugin:1.1.2-rc-1' \
                'com.gradle.enterprise:test-distribution-gradle-plugin:1.1'
            substituteInPlace build-logic/jvm/build.gradle.kts \
              --replace-fail \
                'com.gradle.enterprise:test-distribution-gradle-plugin:1.2.2-rc-1' \
                'com.gradle.enterprise:test-distribution-gradle-plugin:1.2.1'
            substituteInPlace build-logic/dependency-modules/src/main/kotlin/gradlebuild/modules/extension/ExternalModulesExtension.kt \
              --replace-fail \
                'org.samba.jcifs:jcifs' \
                'jcifs:jcifs'
            substituteInPlace settings.gradle.kts \
              --replace-fail \
                'include("configuration-cache-report")' \
                ""
        substituteInPlace subprojects/configuration-cache/build.gradle.kts \
          --replace-fail \
            '    configurationCacheReportPath(project(":configuration-cache-report"))' \
            ""
        substituteInPlace subprojects/configuration-cache/build.gradle.kts \
          --replace-fail \
            '    from(configurationCacheReportPath) { into("org/gradle/configurationcache") }' \
            ""
            substituteInPlace build-logic/basics/src/main/kotlin/gradlebuild.repositories.gradle.kts \
              --replace-fail \
                'repositories {' \
                'repositories {
            mavenCentral()'
            substituteInPlace build-logic/basics/src/main/kotlin/gradlebuild.repositories.gradle.kts \
              --replace-fail \
                '        url = uri("https://repo.gradle.org/gradle/libs")' \
                '        url = uri("https://repo.gradle.org/gradle/libs")
                metadataSources {
                    artifact()
                }'
            for f in \
                  build-logic-commons/code-quality/build.gradle.kts \
                  build-logic-commons/gradle-plugin/build.gradle.kts
                do
                  substituteInPlace "$f" \
                    --replace-fail \
                      'kotlinDslPluginOptions.experimentalWarning.set(false)' \
                      'kotlinDslPluginOptions.experimentalWarning.set(false)

                tasks.matching { it.name == "compileKotlin" || it.name == "compileTestKotlin" }.configureEach {
                    val kotlinOptions = javaClass.methods.first { it.name == "getKotlinOptions" }.invoke(this)
                    @Suppress("UNCHECKED_CAST")
                    val freeCompilerArgs = kotlinOptions.javaClass.methods.first { it.name == "getFreeCompilerArgs" }.invoke(kotlinOptions) as MutableList<String>
                    freeCompilerArgs += "-Xskip-prerelease-check"
                }'
                done
                substituteInPlace build-logic/uber-plugins/src/main/kotlin/gradlebuild.kotlin-library.gradle.kts \
                  --replace-fail \
                    '"-Xskip-metadata-version-check"' \
                    '"-Xskip-metadata-version-check",
                        "-Xskip-prerelease-check"'
        substituteInPlace build-logic-commons/gradle-plugin/src/main/kotlin/gradlebuild.build-logic.kotlin-dsl-gradle-plugin.gradle.kts \
          --replace-fail \
            'ktlint {' \
            'tasks.matching { it.name == "compileKotlin" || it.name == "compileTestKotlin" }.configureEach {
        val kotlinOptions = javaClass.methods.first { it.name == "getKotlinOptions" }.invoke(this)
        @Suppress("UNCHECKED_CAST")
        val freeCompilerArgs = kotlinOptions.javaClass.methods.first { it.name == "getFreeCompilerArgs" }.invoke(kotlinOptions) as MutableList<String>
        freeCompilerArgs += "-Xskip-prerelease-check"
    }

    ktlint {'
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
