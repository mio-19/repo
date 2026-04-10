# before commit https://github.com/gradle/gradle/commit/5d3c2b0efa0e8c4eb0951ec483ea13e550e7e35b
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_10_20240721,
  gradle-from-source,
  runCommand,
  jq,
  lib,
}:
gradle-from-source {
  version = "8.10-20240724";
  rev = "6058693c57c73206c870bce9b04cdd0e85fa171b";
  hash = "";
  lockFile = runCommand "merged-lock" { } ''
    ${lib.getExe jq} -s '.[0] * .[1]' ${gradle_8_10_20240721.unwrapped.passthru.lockFile} ${./more.gradle.lock} > $out
  '';
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_10_20240721;
}
