{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
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
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  gradleFlags = [
    "-PbuildKotlinVersion=1.9.20"
  ];
  bootstrapGradle = gradle_8_4;
}
