{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  jdk25_headless,
  gradle-from-source,
  gradle_9_6_1,
  mergeLock,
  stdenv,
  gradle-packages,
}:
if stdenv.isDarwin then
  (gradle-packages.mkGradle {
    version = "9.7.0";
    hash = "sha256-hPu6Rcf0xkq8d0YOHAD1Qen5YOPH7SU48e3hnqzYc64=";
    defaultJava = jdk21_headless;
  }).wrapped
else
  gradle-from-source {
    version = "9.7.0";
    hash = "sha256-B2Jnad66QTDzHmg5yNXUaJ7U/VVy9F25sPibTBv8MKk=";
    lockFile = mergeLock [
      ./gradle.lock
      ./more.gradle.lock
    ];
    defaultJava = jdk21_headless;
    buildJdk = jdk17_headless;
    # 9.7.0 requires a JDK 25 toolchain during the from-source build.
    javaToolchains = [
      jdk8_headless
      jdk11_headless
      jdk17_headless
      jdk21_headless
      jdk25_headless
    ];
    # nix run github:tadfisher/gradle2nix/v2 -- --gradle-wrapper=9.6.1
    bootstrapGradle = gradle_9_6_1;
    configureOnDemand = true;
    patches = [
      ./bootstrap-kotlin-build-logic-commons-settings.patch
      ./bootstrap-kotlin-build-logic-settings.patch
    ];
    postPatch = ''
      substituteInPlace gradle.properties \
        --replace-fail 'org.gradle.unsafe.isolated-projects=true' \
                       'org.gradle.unsafe.isolated-projects=false'
      substituteInPlace gradle.properties \
        --replace-fail 'org.gradle.configuration-cache=true' \
                       'org.gradle.configuration-cache=false'
      # bootstrap gradle_9_6_1 embeds Kotlin 2.3.21; force catalog Kotlin 2.4.0
      substituteInPlace build-logic-commons/build-platform/build.gradle.kts \
        --replace-fail 'strictly(embeddedKotlinVersion)' 'strictly("2.4.0")'
      substituteInPlace build-logic/uber-plugins/src/main/kotlin/gradlebuild.distribution-module.gradle.kts \
        --replace-fail 'strictly(embeddedKotlinVersion)' 'strictly("2.4.0")'
    '';
  }
