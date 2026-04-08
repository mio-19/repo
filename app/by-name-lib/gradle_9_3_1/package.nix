{
  callPackage,
  jdk21,
  pkgs,
}:
(callPackage ../gradle-from-source/package.nix { }) {
  version = "9.3.1";
  tag = "v9.3.1";
  hash = "sha256-uDc2w+D/xxK/2rguf48eUZ9UPYtVpMePfnJOKh/NNCE=";
  deps = ./gradle_9_3_1_deps.json;
  defaultJava = jdk21;
  bootstrapGradle =
    (pkgs.gradle-packages.mkGradle {
      version = "9.3.1";
      hash = "sha256-smbV/2uQ6tptw7IMsJDjcxMC5VOifF0+TfHw12vq/wY=";
      defaultJava = jdk21;
    }).wrapped;
}
