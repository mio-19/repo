{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_5_rc1,
  gradle-from-source,
  gradle-packages,
  stdenv,
}:
if stdenv.isDarwin then
  # use the existing Darwin binary-wrapper fallback
  (gradle-packages.mkGradle {
    version = "8.6-rc-2";
    hash = "sha256-OjbO3SXAIzXZkeNoTheYUjkVDiS3RKhRPUZlQwg8olA=";
    defaultJava = jdk21_headless;
  }).wrapped
else
  gradle-from-source {
    version = "8.6.0-RC2";
    hash = "sha256-cvOfz+HoG4rSjbeG8rPQXE7sRBIMog5/Q3K7juhLnHw=";
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
    # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.5-rc-1
    bootstrapGradle = gradle_8_5_rc1;
  }
