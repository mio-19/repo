{
  gradle_5_6_4,
  gradle_7_0_M1,
  git,
  temurin-bin-11,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  runtimeShell,
  unzip,
}:
let
  gradle = gradle_7_0_M1;
  gradleFetchDeps = gradle_5_6_4.fetchDeps;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "gradle-unwrapped";
  version = "7.0";

  src = fetchFromGitHub {
    owner = "gradle";
    repo = "gradle";
    tag = "v7.0.0";
    hash = "sha256-YX21LsRISQmayvSn9q6ivUydJ0qyskjCTIyabLaKV3A=";
  };

  gradleBuildTask = ":distributions-full:binDistributionZip";
  gradleUpdateTask = finalAttrs.gradleBuildTask;

  nativeBuildInputs = [
    gradle_5_6_4
    gradle
    git
    makeWrapper
    temurin-bin-11
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

  env.JAVA_HOME = temurin-bin-11.passthru.home;

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
    org.gradle.java.installations.auto-download=false
    org.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}
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
    "-Porg.gradle.java.installations.auto-download=false"
    "-Porg.gradle.java.installations.paths=${finalAttrs.env.JAVA_HOME}"
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
        substituteInPlace build-logic-commons/settings.gradle.kts \
          --replace-fail \
            '        gradlePluginPortal()' \
            '        maven { url = uri("https://plugins.gradle.org/m2/") }
                gradlePluginPortal()'
        substituteInPlace build-logic/build-platform/build.gradle.kts \
          --replace-fail \
            'org.codehaus.groovy.modules.http-builder:http-builder:0.7.2' \
            'org.codehaus.groovy.modules.http-builder:http-builder:0.7.1'
        substituteInPlace build-logic-commons/gradle-plugin/build.gradle.kts \
          --replace-fail \
            'org.gradle.kotlin.kotlin-dsl:org.gradle.kotlin.kotlin-dsl.gradle.plugin:2.1.4' \
            'org.gradle.kotlin.kotlin-dsl:org.gradle.kotlin.kotlin-dsl.gradle.plugin:2.0.0'
        substituteInPlace build-logic/dependency-modules/src/main/kotlin/gradlebuild/modules/extension/ExternalModulesExtension.kt \
          --replace-fail \
            'org.samba.jcifs:jcifs' \
            'jcifs:jcifs'
        substituteInPlace build-logic/jvm/src/main/kotlin/gradlebuild.unittest-and-compile.gradle.kts \
          --replace-fail \
            '        vendor.set(JvmVendorSpec.ADOPTOPENJDK)' \
            '        // vendor restriction disabled for source bootstrap'
        substituteInPlace build-logic/jvm/src/main/kotlin/gradlebuild.unittest-and-compile.gradle.kts \
          --replace-fail \
            '                "openjdk" -> vendor.set(JvmVendorSpec.ADOPTOPENJDK)' \
            '                "openjdk" -> {}'
        substituteInPlace build-logic/jvm/src/main/kotlin/gradlebuild.unittest-and-compile.gradle.kts \
          --replace-fail \
            '            jvmArgs(org.gradle.internal.jvm.JpmsConfiguration.GRADLE_DAEMON_JPMS_ARGS)' \
            '            jvmArgs(listOf("--add-opens", "java.base/java.util=ALL-UNNAMED"))
                jvmArgs(listOf("--add-opens", "java.base/java.lang=ALL-UNNAMED"))'
        substituteInPlace build-logic/basics/src/main/kotlin/gradlebuild/basics/util/KotlinSourceParser.kt \
          --replace-fail \
            'import org.jetbrains.kotlin.utils.JavaTypeEnhancementState' \
            ""
        substituteInPlace build-logic/basics/src/main/kotlin/gradlebuild/basics/util/KotlinSourceParser.kt \
          --replace-fail \
            '                    JvmAnalysisFlags.javaTypeEnhancementState to JavaTypeEnhancementState.STRICT,
                        JvmAnalysisFlags.jvmDefaultMode to JvmDefaultMode.ENABLE' \
            '                    JvmAnalysisFlags.jvmDefaultMode to JvmDefaultMode.ENABLE'
        substituteInPlace build-logic/binary-compatibility/src/main/groovy/gradlebuild/binarycompatibility/transforms/ExplodeZipAndFindJars.groovy \
          --replace-fail \
            "        try (ZipInputStream zin = new ZipInputStream(artifact.get().asFile.newInputStream())) {
                ZipEntry zipEntry
                while (zipEntry = zin.nextEntry) {
                    String shortName = zipEntry.name
                    if (shortName.contains('/')) {
                        shortName = shortName.substring(shortName.lastIndexOf('/') + 1)
                    }
                    if (shortName.endsWith('.jar')) {
                        def outputDir = shortName.startsWith('gradle-') ? gradleJars : dependencies
                        def out = new File(outputDir, shortName)
                        Files.copy(zin, out.toPath())
                        zin.closeEntry()
                    }
                }
            }" \
            "        ZipInputStream zin = new ZipInputStream(artifact.get().asFile.newInputStream())
            try {
                ZipEntry zipEntry
                while (zipEntry = zin.nextEntry) {
                    String shortName = zipEntry.name
                    if (shortName.contains('/')) {
                        shortName = shortName.substring(shortName.lastIndexOf('/') + 1)
                    }
                    if (shortName.endsWith('.jar')) {
                        def outputDir = shortName.startsWith('gradle-') ? gradleJars : dependencies
                        def out = new File(outputDir, shortName)
                        Files.copy(zin, out.toPath())
                        zin.closeEntry()
                    }
                }
            } finally {
                zin.close()
            }"
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
              'dependencies {' \
              'tasks.matching { it.name == "compileKotlin" || it.name == "compileTestKotlin" }.configureEach {
            val kotlinOptions = javaClass.methods.first { it.name == "getKotlinOptions" }.invoke(this)
            @Suppress("UNCHECKED_CAST")
            val freeCompilerArgs = kotlinOptions.javaClass.methods.first { it.name == "getFreeCompilerArgs" }.invoke(kotlinOptions) as MutableList<String>
            freeCompilerArgs += "-Xskip-prerelease-check"
        }

        dependencies {'
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
