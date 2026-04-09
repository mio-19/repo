{
  javaPackages,
  jdk21_headless,
  gradle_8_13_rc1,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.13";
  hash = "sha256-VhV58GDtZRjlQFtG1knTbm7vJP2JrrSr5yD/3/+yTnM=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  buildJdk = javaPackages.compiler.openjdk11-bootstrap;
  # nix-shell -p javaPackages.compiler.openjdk11-bootstrap
  # nix run github:tadfisher/gradle2nix/53672d5e875235c34dee1a4c012b0269ba76e440  -- --gradle-wrapper=8.13-rc-1
  bootstrapGradle = gradle_8_13_rc1;
}
