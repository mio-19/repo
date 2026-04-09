{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_13_rc1,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.13";
  hash = "sha256-VhV58GDtZRjlQFtG1knTbm7vJP2JrrSr5yD/3/+yTnM=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-17;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  # nix-shell -p javaPackages.compiler.openjdk17-bootstrap
  # nix run github:tadfisher/gradle2nix/53672d5e875235c34dee1a4c012b0269ba76e440  -- --gradle-wrapper=8.13-rc-1
  bootstrapGradle = gradle_8_13_rc1;
}
