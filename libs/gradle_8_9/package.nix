{
  gradle-packages,
  jdk21_headless,
}:
(gradle-packages.mkGradle {
  version = "8.9";
  hash = "sha256-1yXXB7+r1N/clYxiQAOzyArMwD9wN7USLEsdDvFc7Ks=";
  defaultJava = jdk21_headless;
}).wrapped
