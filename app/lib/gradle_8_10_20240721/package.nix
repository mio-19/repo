# before commit https://github.com/gradle/gradle/commit/e29131a593f566a52356f47ab168b9702d3b3af3
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_10_20240711,
  gradle-from-source,
  runCommand,
  jq,
  lib,
}:
gradle-from-source {
  version = "8.10-20240721";
  rev = "bafc39a1a9df8e10de23549490dcaec72e02daa2";
  hash = "sha256-X86Z8OKAK3S57AXt7Y6p1kpvpgSq6LdQ3xPRrFlkUO8=";
  lockFile = runCommand "merged-lock" { } ''
    ${lib.getExe jq} -s '
      reduce .[] as $item ({}; . * $item)
    ' ${gradle_8_10_20240711.unwrapped.passthru.lockFile} ${../gradle_8_10_rc1/gradle.lock} ${./more.gradle.lock} > $out
  '';
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_10_20240711;
}
