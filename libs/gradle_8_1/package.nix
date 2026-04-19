{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_0,
  gradle-packages,
  gradle-from-source,
  mergeLock,
}:
let
  bootstrapGradle =
    (gradle-packages.mkGradle {
      version = "8.1-rc-4";
      hash = "sha256-dcvKHDbzaV7BWzmsHyIQPlyEupSbZySX5w6amdwsoZU=";
      defaultJava = jdk21_headless;
    }).wrapped;
in
gradle-from-source {
  version = "8.1";
  hash = "sha256-+IBfbf43KyIxOhkJbuI8r3TughQrSzCdz6PcGIsF6Zg=";
  lockFile = mergeLock [
    gradle_8_0.unwrapped.passthru.lockFile
    ./more.gradle.lock
  ];
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = bootstrapGradle;
}
