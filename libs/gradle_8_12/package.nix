{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_12_rc1,
  gradle-from-source,
  mergeLock,
  gradle-packages,
  stdenv,
}:
if stdenv.isDarwin then
  # use the existing Darwin binary-wrapper fallback
  (gradle-packages.mkGradle {
    version = "8.12";
    hash = "sha256-egDVH7kxR4Gaq3YCT+7OILa4TkIGlBAfJ2vpUuCL7wM=";
    defaultJava = jdk21_headless;
  }).wrapped
else
  gradle-from-source {
    version = "8.12";
    hash = "sha256-L20ZLLXJYb5HsEWJF1EB5NPsWOIimH1JQtd/yRPWO/s=";
    lockFile = mergeLock [
      gradle_8_12_rc1.unwrapped.passthru.lockFile
      ../gradle_8_12_1/gradle.lock
    ];
    defaultJava = jdk21_headless;
    # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
    buildJdk = jdk17_headless;
    javaToolchains = [
      jdk8_headless
      jdk11_headless
      jdk17_headless
    ];
    # nix-shell -p javaPackages.compiler.openjdk17-bootstrap
    # nix run github:tadfisher/gradle2nix/53672d5e875235c34dee1a4c012b0269ba76e440  -- --gradle-wrapper=8.12-rc-1
    bootstrapGradle = gradle_8_12_rc1;
  }
