# before commit https://github.com/gradle/gradle/commit/b88dfd4e5c1aebc5dfa9c2e9c5663fd05c69b8ee
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk17_headless,
  gradle-from-source,
  gradle_7_6_20220831,
  mergeLock,
}:
gradle-from-source {
  version = "7.6.0-20220909";
  rev = "f8b0dfe64a1adb979d594102dac01435901444a4";
  hash = "sha256-5340t8B1eNPJNair9FC7fo5IL6FHPaiyMk3Yt8W7HM0=";
  lockFile = mergeLock [
    gradle_7_6_20220831.unwrapped.passthru.lockFile
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
  # read https://github.com/tadfisher/gradle2nix/pull/88
  /*
    nix-shell -p javaPackages.compiler.openjdk11-bootstrap
    rm gradle/verification-*
    nix run github:tadfisher/gradle2nix/6c0f9601ac41a1af04df09d8377ab706d07a4cf4  -- --gradle-wrapper=7.5-rc-1
  */
  bootstrapGradle = gradle_7_6_20220831;
}
