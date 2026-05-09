# before commit https://github.com/gradle/gradle/commit/b129f011f97278554fe76e47db659595b8513a90
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk17_headless,
  gradle-from-source,
  gradle_7_6_20220909,
  mergeLock,
}:
gradle-from-source {
  version = "7.6.0-20220916";
  rev = "17e9a03925c039524aa3079dccdb1f5d58e00fc0";
  hash = "sha256-9RLa0Hw+6L6DEFr+EwZgdkWRwy98PAheiCQx4SAs9kA=";
  lockFile = mergeLock [
    gradle_7_6_20220909.unwrapped.passthru.lockFile
    ./more.gradle.lock
  ];
  defaultJava = jdk17_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_7_6_20220909;
}
