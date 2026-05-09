# before commit https://github.com/gradle/gradle/commit/6eeed1d827d13a6918a8970ab18b4049545f1a27
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk17_headless,
  gradle_7_6_20220514,
  gradle-from-source,
  mergeLock,
}:
gradle-from-source {
  version = "7.6.0-20220622";
  rev = "82ec2431087d492694581b96c396d02a67392cac";
  hash = "sha256-WNhTKPB+7Vof0+iE3zzX9Ui3Ck7tQN8266OhW3i8Gso=";
  lockFile = mergeLock [
    gradle_7_6_20220514.unwrapped.passthru.lockFile
    # [id: 'com.gradle.enterprise', version: '3.10.2'] org.jsoup:jsoup:1.15.1 org.gradle:test-retry-gradle-plugin:1.4.0 com.gradle.publish:plugin-publish-plugin:1.0.0-rc-3 com.fasterxml.jackson.core:jackson-core:2.13.3
    ./more.gradle.lock
    # org.gradle.kotlin:gradle-kotlin-dsl-conventions:0.8.0
    ../gradle_8_6_rc2/gradle.lock
  ];
  postPatch = ''
    substituteInPlace settings.gradle.kts \
      --replace-fail 'id("com.gradle.enterprise.test-distribution").version("2.3.4-milestone-1")' 'id("com.gradle.enterprise.test-distribution").version("2.3.1")'
    substituteInPlace build-logic/build-platform/build.gradle.kts \
      --replace-fail 'api("com.gradle.enterprise:test-distribution-gradle-plugin:2.3.4-milestone-1")' 'api("com.gradle.enterprise:test-distribution-gradle-plugin:2.3.1")'
  '';
  defaultJava = jdk17_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  # read https://github.com/tadfisher/gradle2nix/pull/88
  #nix-shell -p javaPackages.compiler.openjdk11-bootstrap
  #patch -p1 < path/to/repository.patch
  #rm gradle/verification-*; nix run github:tadfisher/gradle2nix/6c0f9601ac41a1af04df09d8377ab706d07a4cf4  -- --gradle-home=/nix/store/qm4b12x9cg8hybf6xnqg0sk3d3sqyfvr-gradle-7.6.0-20220514/libexec/gradle
  bootstrapGradle = gradle_7_6_20220514;
}
