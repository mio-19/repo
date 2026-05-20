{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  gradle-from-source,
  gradle_7_0,
  mergeLock,
  stdenv,
}:
if stdenv.isDarwin then
  gradle_7_0
else
  gradle-from-source {
    version = "7.2";
    hash = "sha256-W5lcqilYDT25LQEYZHAv+hBNeRm7s2/iamgajaDVf9o=";
    lockFile = mergeLock [
      ./gradle.lock
      ./source-bootstrap.gradle.lock
    ];
    defaultJava = jdk17_headless;
    # this version specifically ask for Temurin branded jdk.
    relaxJavaVendor = true;
    buildJdk = jdk11_headless;
    javaToolchains = [
      jdk8_headless
      jdk11_headless
      jdk17_headless
    ];
    bootstrapGradle = gradle_7_0;
    patches = [
      ./repository.patch
      ./configuration-cache-jdk11-compat.patch
    ];
    postPatch = ''
          # remove strict toolchain vendor and implementation requirements
          for f in \
            build-logic-commons/code-quality/build.gradle.kts \
            build-logic-commons/gradle-plugin/build.gradle.kts
          do
            substituteInPlace "$f" \
              --replace-fail \
                'org.gradle.kotlin.kotlin-dsl:org.gradle.kotlin.kotlin-dsl.gradle.plugin:2.1.6' \
                'org.gradle.kotlin.kotlin-dsl:org.gradle.kotlin.kotlin-dsl.gradle.plugin:2.1.4'
          done
          substituteInPlace build-logic/binary-compatibility/src/main/groovy/gradlebuild/binarycompatibility/rules/AcceptedRegressionsRulePostProcess.java \
            --replace-fail \
              'import org.gradle.util.internal.CollectionUtils;' \
              'import java.util.stream.Collectors;'
          substituteInPlace build-logic/binary-compatibility/src/main/groovy/gradlebuild/binarycompatibility/rules/AcceptedRegressionsRulePostProcess.java \
            --replace-fail \
              'String formattedLeft = CollectionUtils.join("\n", left);' \
              'String formattedLeft = left.stream().map(Object::toString).collect(Collectors.joining("\n"));'

          find . -name "*.gradle" -o -name "*.gradle.kts" -print0 | xargs -0 sed -i -E \
            -e 's/vendor = JvmVendorSpec.ADOPTOPENJDK/vendor = JvmVendorSpec.matching(".*")/g' \
            -e 's/vendor.set\(JvmVendorSpec.ADOPTOPENJDK\)/vendor.set(JvmVendorSpec.matching(".*"))/g' \
            -e 's/.*"oracle" -> vendor.set\(JvmVendorSpec.ORACLE\).*/"oracle" -> {}/g' \
            -e 's/.*"openjdk" -> vendor.set\(JvmVendorSpec.ADOPTOPENJDK\).*/"openjdk" -> {}/g' \
            -e 's/\.implementation\([^)]+\)//g' \
            -e 's/implementation = [^ ]+/implementation = null/g' \
            -e 's/implementation.set\([^)]+\)/implementation.set(null)/g' \
            -e '/java\.toolchain \{/,/\}/d' \
            -e 's/val launcher = javaToolchains.launcherFor\(java.toolchain\)/val launcher = javaToolchains.launcherFor { languageVersion.set(JavaLanguageVersion.of(8)) }/g'

          echo "kotlin.js.yarn.download=false" >> gradle.properties
          echo "kotlin.js.node.download=false" >> gradle.properties

          cat <<EOF >> settings.gradle.kts
      gradle.rootProject {
          allprojects {
              tasks.configureEach {
                  if (name == "browserProductionWebpack") {
                      actions.clear()
                      doLast {
                          val jsFile = file("build/distributions/configuration-cache-report.js")
                          jsFile.parentFile.mkdirs()
                          jsFile.writeText("")
                      }
                  } else if (name == "rootPackageJson" || name == "kotlinNodeJsSetup" || name == "kotlinNpmInstall" || name == "generateExternalsIntegrated" || name == "packageJson") {
                      enabled = false
                      onlyIf { false }
                  }
              }
          }
      }
      EOF
    '';
  }
