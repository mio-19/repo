{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_7_rc1,
  gradle-from-source,
  gradle-packages,
  stdenv,
}:
if stdenv.isDarwin then
  # no termurin-bin-* on darwin
  (gradle-packages.mkGradle {
    version = "8.7";
    hash = "";
    defaultJava = jdk21_headless;
  }).wrapped
else
  gradle-from-source {
    version = "8.7";
    hash = "sha256-n1o4ZMbRNVfz6roPIERm9gIpWkqtDse/9C5inCqa2D8=";
    lockFile = ./gradle.lock;
    defaultJava = jdk21_headless;
    # this version specifically ask for termurin branded jdk.
    buildJdk = temurin-bin-11;
    javaToolchains = [
      temurin-bin-8
      temurin-bin-11
      temurin-bin-17
    ];
    # nix-shell -p javaPackages.compiler.openjdk11-bootstrap
    # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.7-rc-1
    bootstrapGradle = gradle_8_7_rc1;
  }
