# before commit https://github.com/gradle/gradle/commit/711e977fe186c4321738747490b3214fb74cf7ef
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk17_headless,
  gradle_7_6,
  gradle-from-source,
}:
gradle-from-source {
  version = "7.6.0-20220808";
  rev = "44e3ed832ab74da3b309f77d3d1f84b1d1f89731";
  hash = "";
  lockFile = ./gradle.lock;
  defaultJava = jdk17_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  # read https://github.com/tadfisher/gradle2nix/pull/88
  /*
    nix-shell -p javaPackages.compiler.openjdk11-bootstrap
    rm gradle/verification-*
    nix run github:tadfisher/gradle2nix/6c0f9601ac41a1af04df09d8377ab706d07a4cf4  -- --gradle-wrapper=7.5-rc-1
  */
  bootstrapGradle = gradle_7_6;
}
