# this is before gradle v8.0.0-M1. before commit https://github.com/gradle/gradle/commit/af509fd7e9ddcb85de364bf5b6d131673615935a
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_7_6,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.0.0-20220911";
  rev = "d528065a014f833d01cb45632bbd6cc381c3685e";
  hash = "sha256-mo+CZDabwNLDHRqCprq912nsQSpKvl+IdkLg+wPNdSc=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  # read https://github.com/tadfisher/gradle2nix/pull/88
  /*
    nix-shell -p javaPackages.compiler.openjdk11-bootstrap
    sed -i '/gradlePluginPortal()/a\
        mavenCentral()' settings.gradle.kts
    sed -i '/mavenCentral()/a\
        maven { url = uri("https://oss.jfrog.org/artifactory/oss-release-local") }' settings.gradle.kts
    sed -i '/mavenCentral()/i\
    maven {\
        name = "JFrog OSS releases"\
        url = uri("https://oss.jfrog.org/artifactory/oss-release-local")\
    }\
    ' build-logic/basics/src/main/kotlin/gradlebuild.repositories.gradle.kts
    nix run github:tadfisher/gradle2nix/6c0f9601ac41a1af04df09d8377ab706d07a4cf4  -- --gradle-wrapper=7.6
  */
  bootstrapGradle = gradle_7_6;
}
