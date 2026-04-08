{
  callPackage,
  jdk17,
  jdk21,
  pkgs,
}:
(callPackage ../gradle-from-source/package.nix { }) {
  version = "9.3.1";
  tag = "v9.3.1";
  hash = "sha256-uDc2w+D/xxK/2rguf48eUZ9UPYtVpMePfnJOKh/NNCE=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21;
  buildJdk = jdk17;
  bootstrapGradle =
    (pkgs.gradle-packages.mkGradle {
      version = "9.3.1";
      hash = "sha256-smbV/2uQ6tptw7IMsJDjcxMC5VOifF0+TfHw12vq/wY=";
      defaultJava = jdk21;
    }).wrapped;
}
