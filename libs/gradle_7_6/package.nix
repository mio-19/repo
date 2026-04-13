{
  jdk17_headless,
  gradle-packages,
}:
(gradle-packages.mkGradle {
  version = "7.6";
  hash = "sha256-e6aMVAKXkKtESznX4pPTI2smMmMftfLgErsotP9mnks=";
  defaultJava = jdk17_headless;
}).wrapped
