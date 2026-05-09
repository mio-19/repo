{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_4,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.5.0-RC1";
  hash = "sha256-UGzP4x2FaeMvh7XdT6zT2m4/fJJqd9LsP7Fo/+kVfK4=";
  lockFile = mergeLock [
    gradle_8_4.unwrapped.passthru.lockFile
    ./gradle.lock
  ];
  patches = [
    ./disable-dependency-verification.patch
  ];
  defaultJava = jdk21_headless;
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  gradleFlags = [
    "-PbuildKotlinVersion=1.9.20"
  ];
  bootstrapGradle = gradle_8_4;
}
