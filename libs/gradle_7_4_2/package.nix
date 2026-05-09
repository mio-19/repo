{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  gradle-from-source,
  gradle_7_2,
}:
gradle-from-source {
  version = "7.4.2";
  hash = "sha256-nsbNw0tgpbPKtrLvOOuipXQxPa3YGrwuz77uxsPiMug=";
  lockFile = ./gradle.lock;
  defaultJava = jdk17_headless;
  buildJdk = jdk11_headless;
  avoidSingleUseDaemon = true;
  extraJavaOpts = [
    "-XX:-UseCompressedOops"
    "-XX:-UseCompressedClassPointers"
  ];
  forceSerialGradle = true;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_7_2;
  patches = [
    ./bootstrap-compat.patch
  ];
  postPatch = ''
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
