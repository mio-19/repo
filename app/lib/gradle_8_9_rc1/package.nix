{
  jdk11_headless,
  jdk17_headless,
  gradle-packages,
  gradle-from-source,
}:
# v8.9.0-RC1
(gradle-packages.mkGradle {
  version = "8.9-rc-1";
  hash = "sha256-Ouf309Qzk2tUbBNQW7Va2653COcVv8TPNs/CJlDmqIE=";
  defaultJava = jdk17_headless;
}).wrapped

# nix-shell -p javaPackages.compiler.openjdk11-bootstrap
# nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.8
