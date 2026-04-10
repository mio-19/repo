{
  jdk11_headless,
  jdk17_headless,
  gradle-packages,
  gradle-from-source,
}: # v8.11.0-M1
(gradle-packages.mkGradle {
  version = "8.11-milestone-1";
  hash = "sha256-LEBroQ6u1wG2nQHekk3682EG1HZOIJAXXRA7LnrLohE=";
  defaultJava = jdk17_headless;
}).wrapped

# nix-shell -p javaPackages.compiler.openjdk11-bootstrap
# nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.10.2
