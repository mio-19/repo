# before https://github.com/gradle/gradle/commit/7f8365f4a6492eb0e8acbbb37be1f30352ebbaa6
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle-from-source,
  runCommand,
  jq,
  lib,
  gradle_8_9_20240420,
}:
gradle-from-source {
  version = "8.9.0-20240529";
  rev = "8a9cda36b91f1b7f66d0c2c27e5594a210bac8f3";
  hash = "sha256-IplC2CQp/ZWMn37fUByaHF9/X04Ey4Q4vfmFaPXCqQA=";
  lockFile = runCommand "merged-lock" { } ''
    ${lib.getExe jq} -s '.[0] * .[1]' ${gradle_8_9_20240420.unwrapped.passthru.lockFile} ${./more.gradle.lock} > $out
  '';
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_9_20240420;
}
