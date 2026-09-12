{
  jdk8_headless,
  jdk11_headless,
  jdk17_headless,
  jdk21_headless,
  jdk25_headless,
  gradle-from-source,
  gradle_9_7_0,
  mergeLock,
  stdenv,
  gradle-packages,
}:
if stdenv.isDarwin then
  (gradle-packages.mkGradle {
    version = "9.7.1";
    hash = "sha256-rNU/HtrwLxqP+Zh5+KNLMCZhoFfZsGOunjW1UvgE0go=";
    defaultJava = jdk21_headless;
  }).wrapped
else
  gradle-from-source {
    version = "9.7.1";
    hash = "sha256-zGjJLzb55gvxLW+Re1Hhimx16N5mNK7gIj2QBTYCKhQ=";
    lockFile = mergeLock [
      ./gradle.lock
      ./more.gradle.lock
    ];
    defaultJava = jdk21_headless;
    buildJdk = jdk17_headless;
    # 9.7.1 requires a JDK 25 toolchain during the from-source build.
    javaToolchains = [
      jdk8_headless
      jdk11_headless
      jdk17_headless
      jdk21_headless
      jdk25_headless
    ];
    # nix run github:tadfisher/gradle2nix/v2 -- --gradle-wrapper=9.7.0
    bootstrapGradle = gradle_9_7_0;
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
