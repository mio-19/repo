# this is before gradle_12_rc1. before commit https://github.com/gradle/gradle/commit/8fedfda9beb743506987e60df2e08c31017beb87
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_12_20241015,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.12-20241016-8914";
  rev = "8914d57e1d5a618f624aff602d54947dcf224350";
  hash = "";
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
  # nix run github:tadfisher/gradle2nix/effc6f3c8ba22e718eb4fb31f09219d0fcc75649  -- --gradle-home=/nix/store/2fqkjv8xnwcf495q2xnj112vh84ar01v-gradle-8.12-20241015/libexec/gradle
  bootstrapGradle = gradle_8_12_20241015;
}
