{
  gradle-packages,
  jdk17,
}:
(gradle-packages.mkGradle {
  version = "9.3.1";
  hash = "sha256-smbV/2uQ6tptw7IMsJDjcxMC5VOifF0+TfHw12vq/wY=";
  defaultJava = jdk17;
}).wrapped
