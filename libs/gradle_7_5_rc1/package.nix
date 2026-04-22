{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk17_headless,
  gradle-from-source,
  gradle_7_4_2,
  mergeLock,
}:
gradle-from-source {
  version = "7.5.0-RC1";
  hash = "sha256-22eR97X9z6QhN4yMfaAzElErs1A/vCGqcRyfL4L2MwE=";
  lockFile = mergeLock [
    gradle_7_4_2.unwrapped.passthru.lockFile
    ./gradle.lock
  ];
  defaultJava = jdk17_headless;
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_7_4_2;
  patches = [
    ./repository.patch
    ./bootstrap-compat.patch
  ];
  postPatch = ''
        rm -f gradle/verification-keyring.keys gradle/verification-metadata.xml

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
