{
  jdk17_headless,
  jdk21_headless,
  gradle-from-source,
  gradle_9_4_1,
  mergeLock,
}:
gradle-from-source {
  version = "9.5.0";
  hash = "sha256-JRMrqvQoudcuQCBjgnt/79NVgSpNzn7TheEnJcHeI6E=";
  lockFile = mergeLock [
    ./gradle.lock
    ./more.gradle.lock
  ];
  defaultJava = jdk21_headless;
  buildJdk = jdk17_headless;
  # nix run github:tadfisher/gradle2nix/v2 -- --gradle-wrapper=9.4.1
  bootstrapGradle = gradle_9_4_1;
  configureOnDemand = true;
  postPatch = ''
    substituteInPlace gradle.properties \
      --replace-fail 'org.gradle.unsafe.isolated-projects=true' \
                     'org.gradle.unsafe.isolated-projects=false'
  '';
}
