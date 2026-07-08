{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  gradle-from-source,
  gradle_7_5_rc1,
  mergeLock,
  stdenv,
  gradle-packages,
}:
if stdenv.isDarwin then
  (gradle-packages.mkGradle {
    version = "7.5";
    hash = "sha256-y4fyIsVYW9RoOK1Nt4RjpcXz0zbl4rmNx8DFhlJzUcI=";
    defaultJava = jdk17_headless;
  }).wrapped
else
  gradle-from-source {
    version = "7.5";
    hash = "sha256-WIlnfVoluIxceDz5HWd/bzfSGcS/ikPAA7fDaZT39Ls=";
    lockFile = mergeLock [
      gradle_7_5_rc1.unwrapped.passthru.lockFile
      ../gradle_7_6_20220622/more.gradle.lock
    ];
    defaultJava = jdk17_headless;
    relaxJavaVendor = true;
    buildJdk = jdk11_headless;
    javaToolchains = [
      jdk8_headless
      jdk11_headless
      jdk17_headless
    ];
    bootstrapGradle = gradle_7_5_rc1;
    # nix run github:tadfisher/gradle2nix/v2 -- --gradle-wrapper=7.5-rc-1
    patches = [
      ../gradle_7_5_rc1/repository.patch
      ../gradle_7_5_rc1/bootstrap-compat.patch
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
