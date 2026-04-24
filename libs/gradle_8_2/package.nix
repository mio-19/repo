{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_1,
  gradle-packages,
  gradle-from-source,
  mergeLock,
}:
let
  bootstrapGradle =
    (gradle-packages.mkGradle {
      version = "8.2-rc-3";
      hash = "sha256-NFOJpR4ux5axECwc5ROsj1cZeP1pjj+xC24EVwkbbtw=";
      defaultJava = jdk21_headless;
    }).wrapped;
in
gradle-from-source {
  version = "8.2";
  hash = "sha256-2s5MzKtluNLcZt86AWOawI+oIBp3Sa5K68JT9OYkDZ4=";
  lockFile = mergeLock [
    gradle_8_1.unwrapped.passthru.lockFile
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
