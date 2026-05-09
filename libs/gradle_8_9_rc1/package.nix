{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle-from-source,
  gradle_8_9_20240529,
  mergeLock,
  jq,
  lib,
}:
gradle-from-source {
  version = "8.9.0-RC1";
  hash = "sha256-VnYpNXi/ztBSZiwdaWzRWajxZL1rHAXENvoE2ZHi+Yk=";
  # nix-shell -p javaPackages.compiler.openjdk11-bootstrap
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.9-rc-1
  # why generate lock file with different version? beacuse it is easier. it doesn't match bootstrapGradle.
  lockFile = mergeLock [
    gradle_8_9_20240529.unwrapped.passthru.lockFile
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
  bootstrapGradle = gradle_8_9_20240529;
}
