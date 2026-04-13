{
  jdk11_headless,
  jdk17_headless,
  gradle-packages,
  gradle-from-source,
}:
(gradle-packages.mkGradle {
  version = "7.2";
  hash = "sha256-9YFwmpw16cuS4W9YXSxLyZsrGl+F0rrb09xr/1nh5t0=";
  defaultJava = jdk17_headless;
}).wrapped

# nix-shell -p javaPackages.compiler.openjdk11-bootstrap
# rm gradle/verification-metadata.xml
# nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=7.1.1
