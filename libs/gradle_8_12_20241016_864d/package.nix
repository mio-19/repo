# this is before gradle_12_rc1. https://github.com/gradle/gradle/commit/864ddaf0a289b122e804046ab4a0e618dce9b8e7
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_12_20241015,
  gradle-from-source,
  runCommand,
  jq,
  lib,
}:
gradle-from-source {
  version = "8.12-20241016-864d";
  rev = "864ddaf0a289b122e804046ab4a0e618dce9b8e7";
  hash = "sha256-BPB0LHdA5eMegwHRFfvPTgoFEwTMSLvU1xtxkYriVcY=";
  lockFile = runCommand "merged-lock" { } ''
    ${lib.getExe jq} -s '.[0] * .[1]' ${../gradle_8_12_20241015/gradle.lock} ${../gradle_8_12_1/gradle.lock} > $out
  '';
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-17;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_12_20241015;
}
