{
  jdk11_headless,
  jdk17_headless,
  gradle-packages,
  gradle-from-source,
}:
(gradle-packages.mkGradle {
  version = "8.11.1";
  hash = "sha256-85eyhwI6zboen2/F6nLSLdY2adWe1KKJopsadu7hUcY=";
  defaultJava = jdk17_headless;
}).wrapped
