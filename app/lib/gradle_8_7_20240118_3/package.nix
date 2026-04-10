# before https://github.com/gradle/gradle/commit/a2060320d463db9da8a431b0f9c88ce2ebd4d886
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_7_20240118_2,
  gradle-from-source,
  runCommand,
  jq,
  lib,
}:
gradle-from-source {
  version = "8.7.0-20240118-3";
  rev = "7fce522c0d57e78741975babadb286989f7c1f72";
  hash = "";
  lockFile = runCommand "merged-lock" { } ''
    ${lib.getExe jq} -s '.[0] * .[1]' ${gradle_8_7_20240118_2.unwrapped.passthru.lockFile} ${./more.gradle.lock} > $out
  '';
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_7_20240118_2;
}
