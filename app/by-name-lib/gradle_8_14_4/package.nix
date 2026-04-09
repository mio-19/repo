{
  jdk11_headless,
  jdk21_headless,
  gradle-packages,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.14.4";
  hash = "sha256-DzIJ4bPmyOj58GEpdAS9MZ4APmT5NKgNhiNp/UwZbhY=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  buildJdk = jdk11_headless;
  bootstrapGradle =
    (gradle-packages.mkGradle {
      version = "8.14.4";
      hash = "sha256-8XcSmKcPbbWina9iN4xOGKF/wzybprFDYuDN9AYQOA0=";
      defaultJava = jdk21_headless;
    }).wrapped;
}
