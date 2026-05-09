# this is before gradle v8.0.0-M1. before commit https://github.com/gradle/gradle/commit/af509fd7e9ddcb85de364bf5b6d131673615935a
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_7_6_20220909,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.0.0-20220911";
  rev = "d528065a014f833d01cb45632bbd6cc381c3685e";
  hash = "sha256-mo+CZDabwNLDHRqCprq912nsQSpKvl+IdkLg+wPNdSc=";
  lockFile = mergeLock [
    gradle_7_6_20220909.unwrapped.passthru.lockFile
    ./gradle.lock
  ];
  defaultJava = jdk21_headless;
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  patches = [
    ./repository.patch
    ./fix-test-fixtures-artifact.patch
  ];
  # read https://github.com/tadfisher/gradle2nix/pull/88
  /*
    nix-shell -p jdk11_headless
    patch -p1 < repository.patch
    patch -p1 < fix-test-fixtures-artifact.patch
    rm gradle/verification-*
    nix run github:tadfisher/gradle2nix/6c0f9601ac41a1af04df09d8377ab706d07a4cf4  -- --gradle-wrapper=7.6-milestone-1
  */
  bootstrapGradle = gradle_7_6_20220909;
}
