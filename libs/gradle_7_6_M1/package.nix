{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk17_headless,
  gradle-from-source,
  gradle_7_6_20220916,
  mergeLock,
}:
gradle-from-source {
  version = "7.6.0-M1";
  hash = "sha256-UGvTtH2io/Pi3oJGjqyiYuzbE8n8hr7JHCNH6dpM3PA=";
  lockFile = mergeLock [
    gradle_7_6_20220916.unwrapped.passthru.lockFile
  ];
  defaultJava = jdk17_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_7_6_20220916;
}
