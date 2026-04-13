# this is before gradle v8.5.0-RC1. before commit https://github.com/gradle/gradle/commit/45a8110a5603cd8ba79bc6d212e2f03e037655ad
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_7_6,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.5.0-20231004";
  rev = "54665332ccb0fda03456e34a899dbebbaa606260";
  hash = "";
  lockFile = { };
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.4-rc-2
  bootstrapGradle = gradle_7_6;
}
