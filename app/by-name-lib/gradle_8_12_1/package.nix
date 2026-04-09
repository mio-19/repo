{
  jdk11_headless,
  jdk17_headless,
  gradle-packages,
  gradle-from-source,
}:
(gradle-packages.mkGradle {
  version = "8.12.1";
  hash = "sha256-jZepeYT2y9K4X+TGCnQ0QKNHVEvxiBgEjmEfUojUbJQ=";
  defaultJava = jdk17_headless;
}).wrapped
