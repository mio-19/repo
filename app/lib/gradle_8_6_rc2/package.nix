{
  jdk17_headless,
  gradle-packages,
}:
# v8.6.0-RC2
(gradle-packages.mkGradle {
  version = "8.6-rc-2";
  hash = "";
  defaultJava = jdk17_headless;
}).wrapped

# nix-shell -p javaPackages.compiler.openjdk11-bootstrap
# nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.6-rc-1
