{
  gradle-packages,
  jdk25_headless,
}:
(gradle-packages.mkGradle {
  version = "9.2.1";
  hash = "sha256-cvRMn468sa9Dg49F7lxKqcVESJizRoqz9K97YHbFvD8=";
  defaultJava = jdk25_headless;
}).wrapped
