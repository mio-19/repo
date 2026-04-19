{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_0_M1,
  gradle-packages,
  gradle-from-source,
  mergeLock,
}:
let
  bootstrapGradle =
    (gradle-packages.mkGradle {
      version = "8.0-rc-5";
      hash = "sha256-wBtGBCFB0jrqI65bCaEkEKeZa6yMf982dUes0bPHctk=";
      defaultJava = jdk21_headless;
    }).wrapped;
in
gradle-from-source {
  version = "8.0";
  hash = "sha256-p9woCn+o3hkTMFg5d11jjtILS+iLdAmSeQB59t3+QzA=";
  lockFile = mergeLock [
    gradle_8_0_M1.unwrapped.passthru.lockFile
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
  bootstrapGradle = gradle_8_0_M1;
}
