# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/ea3f2b4ff4b17341830905cad9c7fa1b2db7f03b
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_11_20240826,
  gradle-from-source,
  runCommand,
  jq,
}:
gradle-from-source {
  version = "8.11-20240903";
  rev = "72bdc3250c2efab2d5113f47f49d4139ccd18ee5";
  hash = "sha256-G2kipnZ2F13xKPnpB8MtNA9qWFV818KUMgvgN3AUQG8=";
  lockFile =
    runCommand "merged-lock"
      {
        nativeBuildInputs = [ jq ];
      }
      ''
        jq -s '.[0] * .[1]' ${gradle_8_11_20240826.unwrapped.passthru.lockFile} ${./more.gradle.lock} > $out
      '';
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_11_20240826;
}
