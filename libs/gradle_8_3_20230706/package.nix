{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_3_20230705,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.3.0-20230706";
  rev = "379ea598b9025616cce030ea23986545074cb0c9";
  hash = "sha256-ymgQinxzJ8of+gXsA2c38qdqOKPC6He2RTWpURVa1rU=";
  lockFile = mergeLock [
    gradle_8_3_20230705.unwrapped.passthru.lockFile
    ./gradle.lock
  ];
  defaultJava = jdk21_headless;
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_8_3_20230705;
}
