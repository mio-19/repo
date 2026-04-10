{
  jdk11_headless,
  jdk17_headless,
  gradle-packages,
  gradle-from-source,
}:
# v8.10.0-RC1
(gradle-packages.mkGradle {
  version = "8.10-rc-1";
  hash = "sha256-3irTsknYmvABzj2s5Uj4FJZ1xpLvi8zycURJhbWQ0oQ=";
  defaultJava = jdk17_headless;
}).wrapped

# nix-shell -p javaPackages.compiler.openjdk11-bootstrap
# nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.9
