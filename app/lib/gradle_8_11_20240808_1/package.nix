# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/370ef936bf8edd86bc881ad1f54229c164f2e67f
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_11_20240807,
  gradle-from-source,
  runCommand,
  jq,
  gradle_8_11_20240809,
}:
gradle-from-source {
  version = "8.11-20240808-1";
  rev = "e69fb10f926324a9f861515ddf0c80419b24b899";
  hash = "sha256-FBK/ROz5YmETf4M+vEVYrBxJiDo08lTW3bp3h4WgN3g=";
  # org.jetbrains.kotlinx:kotlinx-metadata-jvm:0.7.0 org.jetbrains.kotlinx:kotlinx-metadata-jvm:0.7.0 org.jetbrains.kotlin:kotlin-scripting-compiler-impl-embeddable:2.0.0
  lockFile =
    runCommand "merged-lock"
      {
        nativeBuildInputs = [ jq ];
      }
      ''
        jq -s '.[0] * .[1]' ${gradle_8_11_20240809.unwrapped.passthru.lockFile} ${./more.gradle.lock} > $out
      '';
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_11_20240807;
}
