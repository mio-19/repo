# before https://github.com/gradle/gradle/commit/1ac201fb971f512686fd56ad2560f7ca5cf6771b
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_8,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.9.0-20240411";
  rev = "5198078ea54d85e33bfd6a1859762353530e1997";
  hash = "sha256-CxdSGHZaJN8tZgNsjb6Uufpx+cEgZd8DZ4ZpnSdBePA=";
  lockFile = ./gradle.lock;
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  # nix-shell -p javaPackages.compiler.openjdk11-bootstrap
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.8
  bootstrapGradle = gradle_8_8;
}
/*
  CANNOT COMPILE
  gradle> 'lib/plugins/google-http-client-apache-v2-1.42.2.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/plugins/google-http-client-apache-v2-1.42.2.jar'
  gradle> 'lib/plugins/google-http-client-1.42.2.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/plugins/google-http-client-1.42.2.jar'
  gradle> 'lib/plugins/httpclient-4.5.14.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/plugins/httpclient-4.5.14.jar'
  gradle> 'lib/plugins/gradle-wrapper-8.9.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/plugins/gradle-wrapper-8.9.jar'
  gradle> 'lib/plugins/opencensus-contrib-http-util-0.31.1.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/plugins/opencensus-contrib-http-util-0.31.1.jar'
  gradle> 'lib/plugins/httpcore-4.4.14.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/plugins/httpcore-4.4.14.jar'
  gradle> 'lib/plugins/maven-settings-builder-3.9.5.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/plugins/maven-settings-builder-3.9.5.jar'
  gradle> 'lib/plugins/plexus-sec-dispatcher-2.0.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/plugins/plexus-sec-dispatcher-2.0.jar'
  gradle> 'lib/plugins/plexus-cipher-2.0.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/plugins/plexus-cipher-2.0.jar'
  gradle> 'lib/plugins/ivy-2.5.2.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/plugins/ivy-2.5.2.jar'
  gradle> 'lib/plugins/jmespath-java-1.12.651.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/plugins/jmespath-java-1.12.651.jar'
  gradle> 'lib/plugins/jackson-core-2.16.1.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/plugins/jackson-core-2.16.1.jar'
  gradle> 'lib/plugins/jackson-databind-2.16.1.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/plugins/jackson-databind-2.16.1.jar'
  gradle> 'lib/plugins/jackson-annotations-2.16.1.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/plugins/jackson-annotations-2.16.1.jar'
  gradle> 'lib/plugins/jatl-0.2.3.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/plugins/jatl-0.2.3.jar'
  gradle> 'lib/gradle-installation-beacon-8.9.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/gradle-installation-beacon-8.9.jar'
  gradle> 'lib/gradle-api-metadata-8.9.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/gradle-api-metadata-8.9.jar'
  gradle> 'lib/gradle-launcher-8.9.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/gradle-launcher-8.9.jar'
  gradle> 'lib/groovy-console-3.0.21.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/groovy-console-3.0.21.jar'
  gradle> 'lib/groovy-test-3.0.21.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/groovy-test-3.0.21.jar'
  gradle> 'lib/groovy-swing-3.0.21.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/groovy-swing-3.0.21.jar'
  gradle> 'lib/groovy-3.0.21.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/groovy-3.0.21.jar'
  gradle> 'lib/gson-2.10.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/gson-2.10.jar'
  gradle> 'lib/h2-2.2.220.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/h2-2.2.220.jar'
  gradle> 'lib/junit-4.13.2.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/junit-4.13.2.jar'
  gradle> 'lib/hamcrest-core-1.3.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/hamcrest-core-1.3.jar'
  gradle> 'lib/HikariCP-4.0.3.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/HikariCP-4.0.3.jar'
  gradle> 'lib/javax.inject-1.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/javax.inject-1.jar'
  gradle> 'lib/jansi-1.18.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/jansi-1.18.jar'
  gradle> 'lib/jcl-over-slf4j-1.7.36.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/jcl-over-slf4j-1.7.36.jar'
  gradle> 'lib/gradle-declarative-dsl-core-8.9.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/gradle-declarative-dsl-core-8.9.jar'
  gradle> 'lib/kotlin-compiler-embeddable-1.9.23.jar' -> '/nix/store/m9hchd3rag3q7xc1kdbkhxg5nh290dgj-gradle-8.9.0-20240411/libexec/gradle/lib/kotlin-compiler-embeddable-1.9.23.jar'
  gradle> java.io.FileNotFoundException:  (No such file or directory)
  gradle>         at java.base/java.io.FileInputStream.open0(Native Method)
  gradle>         at java.base/java.io.FileInputStream.open(FileInputStream.java:213)
  gradle>         at java.base/java.io.FileInputStream.<init>(FileInputStream.java:152)
  gradle>         at jdk.jartool/sun.tools.jar.Main.run(Main.java:350)
  gradle>         at jdk.jartool/sun.tools.jar.Main.main(Main.java:1702)
*/
