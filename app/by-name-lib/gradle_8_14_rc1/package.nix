{
  jdk11_headless,
  jdk21_headless,
  gradle-packages,
  gradle-from-source,
}:
(gradle-packages.mkGradle {
  version = "8.14-rc-1";
  hash = "sha256-6offYgS7lKQyz1jZqRVAixWIqL8UZkOjR+Mfq9ew5ag=";
  defaultJava = jdk21_headless;
}).wrapped
# nix-shell -p jdk17
# nix run github:tadfisher/gradle2nix/53672d5e875235c34dee1a4c012b0269ba76e440  -- --gradle-wrapper=8.14-milestone-1
