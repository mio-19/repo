# this is before gradle_12_rc1. before commit https://github.com/gradle/gradle/commit/864ddaf0a289b122e804046ab4a0e618dce9b8e7
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_11_1,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.12-20241015";
  rev = "e5393154ccd434c2cb563a625f54d41802cbdece";
  hash = "sha256-rLaoPV1t8vjlW7hYt1p8IR62XtxsNFdW2hIMMoL3wGI=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-17;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  # nix-shell -p javaPackages.compiler.openjdk17-bootstrap
  # nix run github:tadfisher/gradle2nix/2ca058c5b7f3b37f0c11258a78bd0110a675caae  -- --gradle-wrapper=8.11.1
  bootstrapGradle = gradle_8_11_1;
}
