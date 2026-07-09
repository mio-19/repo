{
  jdk17_headless,
  jdk21_headless,
  gradle-from-source,
  gradle_9_5_0,
  mergeLock,
}:
gradle-from-source {
  version = "9.5.1";
  hash = "sha256-DJm/d9Kh860tEZsiPyyfkn04T5G+7lwBHoSQtZhH1ng=";
  lockFile = mergeLock [
    ../gradle_9_5_0/gradle.lock
    ../gradle_9_5_0/more.gradle.lock
  ];
  defaultJava = jdk21_headless;
  buildJdk = jdk17_headless;
  # nix run github:tadfisher/gradle2nix/v2 -- --gradle-wrapper=9.5.0
  bootstrapGradle = gradle_9_5_0;
  configureOnDemand = true;
  postPatch = ''
    substituteInPlace gradle.properties \
      --replace-fail 'org.gradle.unsafe.isolated-projects=true' \
                     'org.gradle.unsafe.isolated-projects=false'
  '';
}
