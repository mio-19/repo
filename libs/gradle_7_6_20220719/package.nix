# before commit https://github.com/gradle/gradle/commit/aeccddf345f564ecd3028ae852907af765aae898
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk17_headless,
  gradle_7_6_20220624,
  gradle_7_6,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "7.6.0-20220719";
  rev = "da4e5b63e398bf72dee9cd328077fb71d7d0d142";
  hash = "sha256-reCiizzoZvg1jHRWRapDUcSvRAyaiuf4iaZSYUecjcg=";
  lockFile = mergeLock [
    gradle_7_6_20220624.unwrapped.passthru.lockFile
    ./more.gradle.lock
  ];
  defaultJava = jdk17_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  patches = [
    ./fix-test-fixtures-artifact.patch
    ./fix-arch-test-dependency.patch
  ];
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  # read https://github.com/tadfisher/gradle2nix/pull/88
  /*
    nix-shell -p javaPackages.compiler.openjdk11-bootstrap
    rm gradle/verification-*
    nix run github:tadfisher/gradle2nix/6c0f9601ac41a1af04df09d8377ab706d07a4cf4  -- --gradle-wrapper=7.5-rc-1
  */
  bootstrapGradle = gradle_7_6;
}
