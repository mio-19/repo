# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/ae4c9bac254511e9e94c22b473fa0b746d6d2b4a
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_11_20240808_1,
  gradle-from-source,
  runCommand,
  jq,
}:
gradle-from-source {
  version = "8.11-20240808";
  rev = "c2454dd71782f1affb28858269f1360e96763033";
  hash = "sha256-tfMknJmlZ70ZtMgLf8J54nCSxuHz1fpgygiijsjJhh8=";
  lockFile = gradle_8_11_20240808_1.unwrapped.passthru.lockFile;
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_11_20240808_1;
}
