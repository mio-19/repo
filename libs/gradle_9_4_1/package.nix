{
  jdk17_headless,
  jdk21_headless,
  gradle-from-source,
  gradle_9_1_0,
  stdenv,
  gradle-packages,
}:
if stdenv.isDarwin then
  # darwin only: cannot build
  (gradle-packages.mkGradle {
    version = "9.4.1";
    hash = "";
    defaultJava = jdk21_headless;
  }).wrapped
else
  gradle-from-source {
    version = "9.4.1";
    hash = "sha256-eIdVEbRO1Q8RfZTN1oqw4iWPMImTR81UkT+xHZbn1xs=";
    lockFile = ./gradle.lock;
    defaultJava = jdk21_headless;
    buildJdk = jdk17_headless;
    # nix run github:tadfisher/gradle2nix/v2 -- --gradle-wrapper=9.1.0
    bootstrapGradle = gradle_9_1_0;
    configureOnDemand = true;
  }
