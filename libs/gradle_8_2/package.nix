{
  jdk11_headless,
  jdk17_headless,
  gradle-packages,
  gradle-from-source,
}:
(gradle-packages.mkGradle {
  version = "8.2";
  hash = "sha256-OPZs1u7yF7TDWFW7EepOn7xTWUzMy1+4Lf0xfvjCxaM=";
  defaultJava = jdk17_headless;
}).wrapped
