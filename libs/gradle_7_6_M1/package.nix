{
  jdk8_headless,
  jdk11_headless,
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
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_7_6_20220916;
}
