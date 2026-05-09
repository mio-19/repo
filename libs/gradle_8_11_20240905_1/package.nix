# this is before gradle v8.11.0-M1. before commit https://github.com/gradle/gradle/commit/2f69db976de6317e79a8fdcb26be42928a8f90ab
{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  gradle_8_11_20240903,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "8.11-20240905-1";
  rev = "b94bbd90f6c3da3f5f10a60dd2b1f1d75b51dd83";
  hash = "sha256-FSWbdTtldrxRNq0lsXBNH+ZdrqmQLvpavcDOKjkM/MU=";
  lockFile = mergeLock [
    gradle_8_11_20240903.unwrapped.passthru.lockFile
  ];
  defaultJava = jdk21_headless;
  # gradle-from-source strips upstream Adoptium toolchain vendor requirements.
  buildJdk = jdk11_headless;
  javaToolchains = [
    jdk8_headless
    jdk11_headless
    jdk17_headless
  ];
  bootstrapGradle = gradle_8_11_20240903;
}
