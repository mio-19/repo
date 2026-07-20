{
  jdk17_headless,
  jdk21_headless,
  gradle-from-source,
  gradle_9_5_1,
  mergeLock,
  stdenv,
  gradle-packages,
}:
if stdenv.isDarwin then
  (gradle-packages.mkGradle {
    version = "9.6.1";
    hash = "sha256-nA9/ruswbLFOQnmj4ITKa1lolAiaBjjmigfJRaMsnhQ=";
    defaultJava = jdk21_headless;
  }).wrapped
else
  gradle-from-source {
    version = "9.6.1";
    hash = "sha256-8p8NDm78Tw3MFNcxhyUpietjfTXoX25FUXf7+wjh0BE=";
    lockFile = mergeLock [
      ./gradle.lock
      ./more.gradle.lock
    ];
    defaultJava = jdk21_headless;
    buildJdk = jdk17_headless;
    # nix run github:tadfisher/gradle2nix/v2 -- --gradle-wrapper=9.5.1
    bootstrapGradle = gradle_9_5_1;
    configureOnDemand = true;
    postPatch = ''
      substituteInPlace gradle.properties \
        --replace-fail 'org.gradle.unsafe.isolated-projects=true' \
                       'org.gradle.unsafe.isolated-projects=false'
      substituteInPlace gradle.properties \
        --replace-fail 'org.gradle.configuration-cache=true' \
                       'org.gradle.configuration-cache=false'
    '';
  }
