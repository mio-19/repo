# before https://github.com/gradle/gradle/commit/72fb053ee30fd022b06d31d11f72a01a660be8fb
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_7_20240126,
  gradle-from-source,
  runCommand,
  jq,
  lib,
}:
gradle-from-source {
  version = "8.7.0-20240213";
  rev = "acefc992467caf1e3a523b93bff767473f31c5ff";
  hash = "sha256-mW54AY+/nhx2UVD3ML6L0Zw0lmU8R3ln9TFZ+noBkUs=";
  lockFile = runCommand "merged-lock" { } ''
    ${lib.getExe jq} -s '.[0] * .[1]' ${gradle_8_7_20240126.unwrapped.passthru.lockFile} ${./more.gradle.lock} > $out
  '';
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_7_20240126;
}
