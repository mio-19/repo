{
  kotlin-stdlib_2_3_20,
  fetchFromGitHub,
  lib,
  libsUtils,
  jdk17_headless,
}:
kotlin-stdlib_2_3_20.overrideAttrs (
  finalAttrs: prevAttrs: {
    pname = "kotlin-stdlib-2.3.0";
    version = "2.3.0";
    jdk = jdk17_headless;
    src = fetchFromGitHub {
      owner = "JetBrains";
      repo = "kotlin";
      rev = "v${finalAttrs.version}";
      hash = "sha256-n3tMrvS6grDPWDBq9VwclWKwAOqw8JmGmtE3R1dhsZ4=";
    };
    postPatch = ''
      base_path=$(pwd)
      cd ../..
      chmod -R a+w .
      rm gradle/verification-metadata.xml
      rm -r gradle/wrapper
      snapshot_version=$(awk -F= '/^defaultSnapshotVersion=/{print $2}'  gradle.properties)
      substituteInPlace gradle.properties \
        --replace-fail "$snapshot_version" "${finalAttrs.version}" \
        --replace-fail "bootstrap.kotlin.default.version=2.3.0-Beta2-130" "bootstrap.kotlin.default.version=2.3.20-dev-7064"

      substituteInPlace repo/gradle-settings-conventions/settings.gradle.kts \
        --replace-fail '    id("org.gradle.toolchains.foojay-resolver-convention") version "0.9.0"' "" \
        --replace-fail '    id("com.gradle.develocity") version("3.19.2")' '    id("com.gradle.develocity") version("4.1.1")'

      substituteInPlace gradle/libs.versions.toml \
        --replace-fail 'gradle-custom-user-data = "2.3"' 'gradle-custom-user-data = "2.4.0"' \
        --replace-fail 'develocity = "3.19.2"' 'develocity = "4.1.1"' \
        --replace-fail 'shadow = "8.3.0"' 'shadow = "9.1.0"'

      # Force log4j version to match 2.3.20 deps
      substituteInPlace $(find . -name "*.gradle.kts" -o -name "*.gradle" -o -name "*.toml") \
        --replace-quiet "org.apache.logging.log4j:log4j-core:2.19.0" "org.apache.logging.log4j:log4j-core:2.25.1" \
        --replace-quiet "org.apache.logging.log4j:log4j-api:2.19.0" "org.apache.logging.log4j:log4j-api:2.25.1"

      sed -i 's/configurations = configurations + listOf(project.configurations\["embedded"\])/configurations.add(project.configurations["embedded"])/g' \
        repo/gradle-build-conventions/buildsrc-compat/src/main/kotlin/repoArtifacts.kt

      cp ${kotlin-stdlib_2_3_20.src}/repo/gradle-build-conventions/buildsrc-compat/src/main/kotlin/KotlinModuleMetadataVersionBasedSkippingTransformer.kt \
        repo/gradle-build-conventions/buildsrc-compat/src/main/kotlin/KotlinModuleMetadataVersionBasedSkippingTransformer.kt

      cp ${kotlin-stdlib_2_3_20.src}/libraries/reflect/build.gradle.kts libraries/reflect/build.gradle.kts
      substituteInPlace libraries/reflect/build.gradle.kts \
        --replace-fail 'javaLauncher.set(project.getToolchainLauncherFor(JdkMajorVersion.JDK_1_8))' \
                       'javaLauncher.set(project.getToolchainLauncherFor(chooseJdk_1_8ForJpsBuild(JdkMajorVersion.JDK_1_8)))'

      # Disable allWarningsAsErrors
      substituteInPlace $(find . -name "*.gradle.kts" -o -name "gradle.properties") \
        --replace-quiet "allWarningsAsErrors.set(true)" "allWarningsAsErrors.set(false)" \
        --replace-quiet "org.gradle.kotlin.dsl.allWarningsAsErrors=true" "org.gradle.kotlin.dsl.allWarningsAsErrors=false"

      substituteInPlace $(find . -name gradle.properties) $(find . -name pom.xml) \
        --replace-quiet "$snapshot_version" "${finalAttrs.version}"
      cd "$base_path"
    '';
    # Break recursion by using the pre-evaluated mitmCache from the base package
    mitmCache = kotlin-stdlib_2_3_20.mitmCache;

    gradleFlags = (prevAttrs.gradleFlags or [ ]) ++ [
      "--max-workers=1"
      "-Dorg.gradle.jvmargs=-Xmx2g"
    ];
    doInstallCheck = false;
    installCheckPhase = "";
    meta = prevAttrs.meta // {
      mavenProvides = { }; # Break recursion for now, compute later if needed
      mavenProvidesInternal =
        let
          postfixes = [
            ""
            "-js"
            "-wasm-js"
            "-wasm-wasi"
          ];
          name = postfix: "org.jetbrains.kotlin:kotlin-stdlib${postfix}:${finalAttrs.version}";
          value =
            postfix:
            {
              "kotlin-stdlib${postfix}-${finalAttrs.version}.module" =
                "$out/org/jetbrains/kotlin/kotlin-stdlib${postfix}/${finalAttrs.version}/kotlin-stdlib${postfix}-${finalAttrs.version}.module";
              "kotlin-stdlib${postfix}-${finalAttrs.version}.pom" =
                "$out/org/jetbrains/kotlin/kotlin-stdlib${postfix}/${finalAttrs.version}/kotlin-stdlib${postfix}-${finalAttrs.version}.pom";
              "kotlin-stdlib${postfix}-${finalAttrs.version}.spdx.json" =
                "$out/org/jetbrains/kotlin/kotlin-stdlib${postfix}/${finalAttrs.version}/kotlin-stdlib${postfix}-${finalAttrs.version}.spdx.json";
            }
            // lib.optionalAttrs (postfix == "") {
              "kotlin-stdlib${postfix}-${finalAttrs.version}.jar" =
                "$out/org/jetbrains/kotlin/kotlin-stdlib${postfix}/${finalAttrs.version}/kotlin-stdlib${postfix}-${finalAttrs.version}.jar";
              "kotlin-stdlib${postfix}-${finalAttrs.version}-all.jar" =
                "$out/org/jetbrains/kotlin/kotlin-stdlib${postfix}/${finalAttrs.version}/kotlin-stdlib${postfix}-${finalAttrs.version}-all.jar";
            }
            // lib.optionalAttrs (postfix != "") {
              "kotlin-stdlib${postfix}-${finalAttrs.version}.klib" =
                "$out/org/jetbrains/kotlin/kotlin-stdlib${postfix}/${finalAttrs.version}/kotlin-stdlib${postfix}-${finalAttrs.version}.klib";
            };
        in
        builtins.listToAttrs (
          map (postfix: {
            name = name postfix;
            value = value postfix;
          }) postfixes
        );
    };
  }
)
