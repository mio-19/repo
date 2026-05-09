# this is before gradle_12_rc1. before commit https://github.com/gradle/gradle/commit/864ddaf0a289b122e804046ab4a0e618dce9b8e7
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_11_M1,
  gradle-from-source,
  gradle-packages,
  stdenv,
}:
if stdenv.isDarwin then
  # use the existing Darwin binary-wrapper fallback
  (gradle-packages.mkGradle {
    version = "8.11.1";
    hash = "sha256-85eyhwI6zboen2/F6nLSLdY2adWe1KKJopsadu7hUcY=";
    defaultJava = jdk21_headless;
  }).wrapped
else
  gradle-from-source {
    version = "8.11.1";
    hash = "sha256-s9Fcf6zz0TTLEFeq0zGxovCppZGluIV3ux8XmcDdF2A=";
    lockFile = ./gradle.lock;
    defaultJava = jdk21_headless;
    # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
    buildJdk = jdk11_headless;
    javaToolchains = [
      jdk8_headless
      jdk11_headless
      jdk17_headless
    ];
    # nix-shell -p javaPackages.compiler.openjdk11-bootstrap
    # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.11-milestone-1
    bootstrapGradle = gradle_8_11_M1;
  }
