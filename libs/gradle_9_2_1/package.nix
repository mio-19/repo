{
  jdk17_headless,
  jdk21_headless,
  jdk25_headless,
  gradle-from-source,
  gradle_9_1_0,
  mergeLock,
  stdenv,
  gradle-packages,
}:
if stdenv.isDarwin then
  (gradle-packages.mkGradle {
    version = "9.2.1";
    hash = "sha256-cvRMn468sa9Dg49F7lxKqcVESJizRoqz9K97YHbFvD8=";
    defaultJava = jdk25_headless;
  }).wrapped
else
  gradle-from-source {
    version = "9.2.1";
    hash = "sha256-lsyyEGmsiWclriC9v4f+ED7U9Tacmd07yuw9yV3WhfY=";
    lockFile = mergeLock [
      ../gradle_9_3_1/gradle.lock
      ../gradle_9_1_0/gradle.lock
      ./more.gradle.lock
    ];
    defaultJava = jdk25_headless;
    buildJdk = jdk17_headless;
    bootstrapGradle = gradle_9_1_0;
    # nix run github:tadfisher/gradle2nix/v2 -- --gradle-wrapper=9.1.0
    configureOnDemand = true;
  }
