{
  jdk17_headless,
  gradle-packages,
}:
(gradle-packages.mkGradle {
  version = "8.5";
  hash = "";
  defaultJava = jdk17_headless;
}).wrapped
