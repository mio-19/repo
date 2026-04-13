{
  jdk17_headless,
  gradle-packages,
}:
# 8.5.0-RC1
(gradle-packages.mkGradle {
  version = "8.5-rc-1";
  hash = "sha256-jHRGKx2D+LF8SDjJJfxMRtH7tEZ7GLihf1zaruRbfwk=";
  defaultJava = jdk17_headless;
}).wrapped

# nix-shell -p javaPackages.compiler.openjdk11-bootstrap
# nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.5-rc-1
