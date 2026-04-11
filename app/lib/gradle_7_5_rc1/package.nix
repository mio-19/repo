{
  jdk17_headless,
  gradle-packages,
}:
(gradle-packages.mkGradle {
  version = "7.5-rc-1";
  hash = "sha256-i6V6N+HguMQV5NkXGNUQNSI6pzExz3GaUMlaKogmnrI=";
  defaultJava = jdk17_headless;
}).wrapped
