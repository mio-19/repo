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
  version = "8.0.0-20220910";
  rev = "b3f27864ffa665f853c805b831c64b0e9446ce4f";
  hash = "";
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
    rm gradle/verification-*
    sed -i '/gradlePluginPortal()/a\
        maven { url = uri("https://releases.jfrog.io/artifactory/oss-releases/") }' settings.gradle.kts
    sed -i '/mavenCentral()/i\
    maven {\
        name = "JFrog OSS releases"\
        url = uri("https://releases.jfrog.io/artifactory/oss-releases/")\
    }\
    ' build-logic/basics/src/main/kotlin/gradlebuild.repositories.gradle.kts
    tee -a build-logic/performance-testing/build.gradle.kts >/dev/null <<'EOF'

    repositories {
        gradlePluginPortal()
        maven {
            name = "JFrog OSS releases"
            url = uri("https://releases.jfrog.io/artifactory/oss-releases/")
        }
        mavenCentral()
    }
    EOF
    tee -a build-logic/buildquality/build.gradle.kts >/dev/null <<'EOF'

    repositories {
        gradlePluginPortal()
        maven {
            name = "JFrog OSS releases"
            url = uri("https://releases.jfrog.io/artifactory/oss-releases/")
        }
        mavenCentral()
    }
    EOF
    nix run github:tadfisher/gradle2nix/6c0f9601ac41a1af04df09d8377ab706d07a4cf4  -- --gradle-wrapper=7.6
  */
  bootstrapGradle = gradle_7_6;
}
