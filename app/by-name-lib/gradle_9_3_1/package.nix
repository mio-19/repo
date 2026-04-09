{
  jdk17_headless,
  jdk21_headless,
  gradle-packages,
  gradle-from-source,
}:
gradle-from-source {
  version = "9.3.1";
  tag = "v9.3.1";
  hash = "sha256-uDc2w+D/xxK/2rguf48eUZ9UPYtVpMePfnJOKh/NNCE=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  buildJdk = jdk17_headless;
  bootstrapGradle =
    (gradle-packages.mkGradle {
      version = "9.3.1";
      hash = "sha256-smbV/2uQ6tptw7IMsJDjcxMC5VOifF0+TfHw12vq/wY=";
      defaultJava = jdk21_headless;
    }).wrapped;
}
