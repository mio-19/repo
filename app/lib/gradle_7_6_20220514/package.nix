# before commit https://github.com/gradle/gradle/commit/2cef30561c9096eb6b410d4f64a06a238587d9ea
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk17_headless,
  gradle_7_5_rc1,
  gradle-from-source,
}:
gradle-from-source {
  version = "7.6.0-20220514";
  rev = "d2892b427be7c9438ea260c3aac331e318062c6b";
  hash = "sha256-pSv7aKwRDw8Mys48A3cIR+4e28m+SIX8aVEZgARlxZA=";
  lockFile = ./gradle.lock;
  defaultJava = jdk17_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  # read https://github.com/tadfisher/gradle2nix/pull/88
  #nix-shell -p javaPackages.compiler.openjdk11-bootstrap
  #patch -p1 < path/to/gradle2nix.patch
  #rm gradle/verification-*; nix run github:tadfisher/gradle2nix/6c0f9601ac41a1af04df09d8377ab706d07a4cf4  -- --gradle-wrapper=7.5-rc-1
  bootstrapGradle = gradle_7_5_rc1;
}
