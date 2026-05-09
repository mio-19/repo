# before commit https://github.com/gradle/gradle/commit/aeccddf345f564ecd3028ae852907af765aae898
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  gradle_7_6_20220622,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "7.6.0-20220719";
  rev = "da4e5b63e398bf72dee9cd328077fb71d7d0d142";
  hash = "sha256-reCiizzoZvg1jHRWRapDUcSvRAyaiuf4iaZSYUecjcg=";
  lockFile = mergeLock [
    gradle_7_6_20220622.unwrapped.passthru.lockFile
    ./more.gradle.lock
  ];
  defaultJava = jdk17_headless;
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  patches = [
    #./fix-test-fixtures-artifact.patch
    #./fix-arch-test-dependency.patch
  ];
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  # read https://github.com/tadfisher/gradle2nix/pull/88
  /*
    nix-shell -p javaPackages.compiler.openjdk11-bootstrap
    rm gradle/verification-*
    nix run github:tadfisher/gradle2nix/6c0f9601ac41a1af04df09d8377ab706d07a4cf4  -- --gradle-wrapper=7.5-rc-1
  */
  bootstrapGradle = gradle_7_6_20220622;
}
