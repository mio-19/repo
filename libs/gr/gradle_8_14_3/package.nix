{
  jdk17_headless,
  jdk21_headless,
  gradle_8_14,
  gradle-from-source,
  mergeLock,
  stdenv,
  gradle-packages,
}:
if stdenv.isDarwin then
  # darwin only: Failed to extract plugin metadata from '/nix/store/lb8xqz9mh8ank7011dgcxglg9dnzb1lq-gradle-maven-repo/org/jetbrains/kotlin/kotlin-reflect/2.0.21/kotlin-reflect-2.0.21.jar'
  (gradle-packages.mkGradle {
    version = "8.14.3";
    hash = "sha256-vXEQIhNJMGCVbsIp2Ua+7lcVjb2J0OYrkbyg+ixfNTE=";
    defaultJava = jdk21_headless;
  }).wrapped
else
  gradle-from-source {
    version = "8.14.3";
    hash = "sha256-k9j9/w3HEBZc2z2dOgpAm+338hhIjh/WxvAE28viOVk=";
    lockFile = mergeLock [
      ../gradle_8_14/gradle.lock
      ../gradle_8_14_4/gradle.lock
    ];
    defaultJava = jdk21_headless;
    buildJdk = jdk17_headless;
    # nix run github:tadfisher/gradle2nix/53672d5e875235c34dee1a4c012b0269ba76e440  -- --gradle-wrapper=8.14
    bootstrapGradle = gradle_8_14;
  }
