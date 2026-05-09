{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_7_rc1,
  gradle-from-source,
  gradle-packages,
  stdenv,
}:
if stdenv.isDarwin then
  # use the existing Darwin binary-wrapper fallback
  (gradle-packages.mkGradle {
    version = "8.7";
    hash = "sha256-VEw11r2Emuil7QvOo5umd9xA9J330YNVYVgtogCblh0=";
    defaultJava = jdk21_headless;
  }).wrapped
else
  gradle-from-source {
    version = "8.7";
    hash = "sha256-n1o4ZMbRNVfz6roPIERm9gIpWkqtDse/9C5inCqa2D8=";
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
    # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.7-rc-1
    bootstrapGradle = gradle_8_7_rc1;
  }
