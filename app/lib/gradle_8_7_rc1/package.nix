{
  jdk17_headless,
  gradle-packages,
}:
# v8.7.0-RC1
(gradle-packages.mkGradle {
  version = "8.7-rc-1";
  hash = "sha256-Q1S8bEbR8eHjfLNxt8MVVqRCfrP1fQPCPlquiqYGrts=";
  defaultJava = jdk17_headless;
}).wrapped

# nix-shell -p javaPackages.compiler.openjdk11-bootstrap
# nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.7-rc-1
