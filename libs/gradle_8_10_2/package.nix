{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_10_rc1,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.10.2";
  hash = "sha256-KwpfhYAjroe7AnRjztyn00fXCxYYK0hXnTpWS7Hreaw=";
  lockFile = mergeLock [
    gradle_8_10_rc1.unwrapped.passthru.lockFile
    ../gradle_8_10/gradle.lock
    ../gradle_8_11_20240807/gradle.lock
  ];
  defaultJava = jdk21_headless;
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  # nix-shell -p javaPackages.compiler.openjdk11-bootstrap
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.10-rc-1
  bootstrapGradle = gradle_8_10_rc1;
  configureOnDemand = true;
}
