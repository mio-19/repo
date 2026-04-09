{
  jdk11_headless,
  jdk21_headless,
  gradle-packages,
  gradle-from-source,
}:
(gradle-packages.mkGradle {
  version = "8.14-milestone-8";
  hash = "sha256-a242N0+A0+VZTZ/acEC/ReHkYX7LlVKfT1yud9TGzY8=";
  defaultJava = jdk21_headless;
}).wrapped
# nix-shell -p jdk17
# nix run github:tadfisher/gradle2nix/53672d5e875235c34dee1a4c012b0269ba76e440  -- --gradle-wrapper=8.13
