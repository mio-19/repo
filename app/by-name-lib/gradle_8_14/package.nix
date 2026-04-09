{
  jdk17_headless,
  jdk21_headless,
  gradle-from-source,
  gradle_8_14_M8,
}:
gradle-from-source {
  version = "8.14";
  hash = "sha256-Dbyx8ya7mxxQc8CV8lolifU5xzqDPqW2eHGUqpLODJM=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  buildJdk = jdk17_headless;
  # nix run github:tadfisher/gradle2nix/53672d5e875235c34dee1a4c012b0269ba76e440  -- --gradle-wrapper=8.14-milestone-8
  bootstrapGradle = gradle_8_14_M8;
}
