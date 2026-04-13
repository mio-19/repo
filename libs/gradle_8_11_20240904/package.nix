# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/8514b39773c78e9dc278f1f94fa3096f93e3fdb6
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_11_20240903,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.11-20240904";
  rev = "fd52a2a45a3be1398c61bb6b279ba3966282c076";
  hash = "sha256-h8ta/ybf4ACrTh4dRv43RoRDKQTFC4gvocc7bEv7V1o=";
  lockFile = mergeLock [
    gradle_8_11_20240903.unwrapped.passthru.lockFile
  ];
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_11_20240903;
}
