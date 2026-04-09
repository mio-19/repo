{
  jdk11_headless,
  jdk17_headless,
  gradle-packages,
  gradle-from-source,
}:
(gradle-packages.mkGradle {
  version = "8.12-rc-1";
  hash = "sha256-TZ161M+IQvJ5ZJIT0vh9j36aA651rEOJUXqldLFASyo=";
  defaultJava = jdk17_headless;
}).wrapped

# nix-shell -p javaPackages.compiler.openjdk17-bootstrap
# nix run github:tadfisher/gradle2nix/effc6f3c8ba22e718eb4fb31f09219d0fcc75649  -- --gradle-wrapper=8.11.1
