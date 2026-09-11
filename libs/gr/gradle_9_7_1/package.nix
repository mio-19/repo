{
  jdk21_headless,
  gradle-packages,
}:
# Binary distribution; from-source lock not yet generated for 9.7.1.
(gradle-packages.mkGradle {
  version = "9.7.1";
  hash = "sha256-rNU/HtrwLxqP+Zh5+KNLMCZhoFfZsGOunjW1UvgE0go=";
  defaultJava = jdk21_headless;
}).wrapped
