{
  jdk17_headless,
  jdk21_headless,
  gradle_8_14_4,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.14.5";
  hash = "sha256-AhJYJcZLXkY6H+z6QUQJU27morTH8nnDjV38D+H8VGE=";
  lockFile = mergeLock [
    ../gradle_8_14_4/gradle.lock
    ../gradle_9_4_1/gradle.lock
    ../gradle_9_5_0/more.gradle.lock
  ];
  defaultJava = jdk21_headless;
  buildJdk = jdk17_headless;
  # nix run github:tadfisher/gradle2nix/v2 -- --gradle-wrapper=8.14.4
  bootstrapGradle = gradle_8_14_4;
}
