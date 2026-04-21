{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_3,
  gradle-packages,
  gradle-from-source,
  mergeLock,
}:
let
  bootstrapGradle =
    (gradle-packages.mkGradle {
      version = "8.4-rc-3";
      hash = "sha256-yxlF+nNVLd+ZzzLsL80GV3H8tr9KNmuUCOeflWFgGFM=";
      defaultJava = jdk21_headless;
    }).wrapped;
in
gradle-from-source {
  version = "8.4";
  hash = "sha256-RPDvx2Whyg5yY8aHmdjMAghpBe497/F4QOxUopqh97k=";
  lockFile = mergeLock [
    gradle_8_3.unwrapped.passthru.lockFile
    ./gradle.lock
  ];
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  # nix run .#gradle2nix -- --gradle-wrapper=8.4-rc-3
  bootstrapGradle = bootstrapGradle;
}
