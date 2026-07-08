{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  gradle-from-source,
  gradle_7_2,
  stdenv,
  gradle-packages,
}:
if stdenv.isDarwin then
  # facing nodejs related errors on darwin
  (gradle-packages.mkGradle {
    version = "7.4.2";
    hash = "sha256-KeSbEJhOWF2BGLfQvEUvlE44ZFjfJzcbSbSsHexLf9o=";
    defaultJava = jdk17_headless;
  }).wrapped
else
  gradle-from-source {
    version = "7.4.2";
    hash = "sha256-nsbNw0tgpbPKtrLvOOuipXQxPa3YGrwuz77uxsPiMug=";
    lockFile = ./gradle.lock;
    defaultJava = jdk17_headless;
    relaxJavaVendor = true;
    buildJdk = jdk11_headless;
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
