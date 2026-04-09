{
  jdk11_headless,
  jdk21_headless,
  gradle-packages,
  gradle-from-source,
}:
(gradle-packages.mkGradle {
  version = "8.13-milestone-2";
  hash = "sha256-6LBNVJGtZ7teLNajFoYx3em1q40Pr17R/TCBUmze0Oo=";
  defaultJava = jdk21_headless;
}).wrapped
# nix-shell -p javaPackages.compiler.openjdk17-bootstrap
# nix run github:tadfisher/gradle2nix/53672d5e875235c34dee1a4c012b0269ba76e440  -- --gradle-wrapper=8.13-milestone-1
