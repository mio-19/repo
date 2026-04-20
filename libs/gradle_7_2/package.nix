{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk17_headless,
  gradle-packages,
  gradle-from-source,
}:
let
  bootstrapGradle =
    (gradle-packages.mkGradle {
      version = "7.2";
      hash = "sha256-9YFwmpw16cuS4W9YXSxLyZsrGl+F0rrb09xr/1nh5t0=";
      defaultJava = jdk17_headless;
    }).wrapped;
in
gradle-from-source {
  version = "7.2";
  hash = "sha256-W5lcqilYDT25LQEYZHAv+hBNeRm7s2/iamgajaDVf9o=";
  lockFile = ./gradle.lock;
  defaultJava = jdk17_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = bootstrapGradle;
  patches = [
    ./repository.patch
    ./configuration-cache-jdk11-compat.patch
  ];
  postPatch = ''
    # remove strict toolchain vendor and implementation requirements
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
