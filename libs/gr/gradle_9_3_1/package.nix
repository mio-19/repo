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
    version = "9.3.1";
    hash = "sha256-smbV/2uQ6tptw7IMsJDjcxMC5VOifF0+TfHw12vq/wY=";
    defaultJava = jdk21_headless;
  }).wrapped
else
  gradle-from-source {
    version = "9.3.1";
    hash = "sha256-uDc2w+D/xxK/2rguf48eUZ9UPYtVpMePfnJOKh/NNCE=";
    lockFile = ./gradle.lock;
    defaultJava = jdk21_headless;
    buildJdk = jdk17_headless;
    # nix run github:tadfisher/gradle2nix/v2 -- --gradle-wrapper=9.1.0
    bootstrapGradle = gradle_9_1_0;
    configureOnDemand = true;
  }
