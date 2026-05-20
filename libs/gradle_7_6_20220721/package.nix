# before commit https://github.com/gradle/gradle/commit/d936460bb181a20896ed476c42fde8f17089770f
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  gradle_7_6_20220719,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "7.6.0-20220721";
  rev = "4bfa5e826064f2791dceac3bab4c5aa754a17324";
  hash = "sha256-V4rpfRCAS7mXZCeBh/FY8j6Y0lMcdy6DZ1uMJC4a8TY=";
  lockFile = mergeLock [
    gradle_7_6_20220719.unwrapped.passthru.lockFile
  ];
  defaultJava = jdk17_headless;
  # this version specifically ask for Temurin branded jdk.
  relaxJavaVendor = true;
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  # read https://github.com/tadfisher/gradle2nix/pull/88
  /*
    nix-shell -p javaPackages.compiler.openjdk11-bootstrap
    rm gradle/verification-*
    nix run github:tadfisher/gradle2nix/6c0f9601ac41a1af04df09d8377ab706d07a4cf4  -- --gradle-wrapper=7.5-rc-1
  */
  bootstrapGradle = gradle_7_6_20220719;
}
