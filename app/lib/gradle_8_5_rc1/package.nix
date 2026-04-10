{
  jdk17_headless,
  gradle-packages,
}:
(gradle-packages.mkGradle {
  version = "8.5-rc-1";
  hash = "sha256-jHRGKx2D+LF8SDjJJfxMRtH7tEZ7GLihf1zaruRbfwk=";
  defaultJava = jdk17_headless;
}).wrapped
