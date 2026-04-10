{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle-from-source,
  gradle-packages,
}:
gradle-from-source {
  version = "8.9.0-RC1";
  hash = "sha256-VnYpNXi/ztBSZiwdaWzRWajxZL1rHAXENvoE2ZHi+Yk=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  # nix-shell -p javaPackages.compiler.openjdk11-bootstrap
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.9-rc-1
  bootstrapGradle =
    (gradle-packages.mkGradle {
      version = "8.9-rc-1";
      hash = "sha256-Ouf309Qzk2tUbBNQW7Va2653COcVv8TPNs/CJlDmqIE=";
      defaultJava = jdk21_headless;
    }).wrapped;
}
