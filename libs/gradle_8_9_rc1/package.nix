{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
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
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_9_20240529;
}
