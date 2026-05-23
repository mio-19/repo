{
  gradle-packages,
  jdk17_headless,
}:
(gradle-packages.mkGradle {
  version = "7.5";
  hash = "sha256-y4fyIsVYW9RoOK1Nt4RjpcXz0zbl4rmNx8DFhlJzUcI=";
  defaultJava = jdk17_headless;
}).wrapped
