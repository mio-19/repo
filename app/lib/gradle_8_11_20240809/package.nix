# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/61c49a2eeb032508adf2a2e22c90bfb9ac09d77e
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_11_20240808_2,
  gradle-from-source,
  runCommand,
  jq,
  lib,
}:
gradle-from-source {
  version = "8.11-20240809";
  rev = "d40cb09ed3c2f557ee731dd88dde0cae2f3f0ce1";
  hash = "sha256-xt5RLWbM1YAgg0IAl7OttqV1qjxpWzyRmQdGKjTXmr0=";
  # more.gradle.lock: org.gradle.kotlin.kotlin-dsl:org.gradle.kotlin.kotlin-dsl.gradle.plugin:5.1.0 org.jetbrains.kotlin:kotlin-gradle-plugin:2.0.10 org.jetbrains.kotlin:kotlin-util-io:2.0.10 org.jetbrains.kotlinx:kotlinx-metadata-jvm:0.7.0
  # ./refresh-hashes.sh more.gradle.lock
  lockFile = runCommand "merged-lock" { } ''
    ${lib.getExe jq} -s '
      reduce .[] as $item ({}; . * $item)
      | del(.["gradle:gradle:8.10.2"])
    ' ${gradle_8_11_20240808_2.unwrapped.passthru.lockFile} ${../gradle_8_11/gradle.lock} ${./more.gradle.lock} ${../gradle_8_11_1/gradle.lock} > $out
  '';
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_11_20240808_2;
}
