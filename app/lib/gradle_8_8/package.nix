{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_7,
  gradle-from-source,
}:
gradle-from-source {
  version = "8.8";
  hash = "sha256-am+ns2YNuOQKLFlCbbOfK5ds2uXZg8IVFw/nId+wXxU=";
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
  # nix run github:tadfisher/gradle2nix/v2  -- --gradle-wrapper=8.7
  bootstrapGradle = gradle_8_7;
}
/*
  CANNOT BUILD
  gradle> 'lib/plugins/jatl-0.2.3.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/jatl-0.2.3.jar'
  gradle> 'lib/plugins/jcifs-1.3.17.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/jcifs-1.3.17.jar'
  gradle> 'lib/plugins/org.eclipse.jgit.ssh.apache-5.13.3.202401111512-r.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/org.eclipse.jgit.ssh.apache-5.13.3.202401111512-r
  .jar'
  gradle> 'lib/plugins/sshd-sftp-2.12.1.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/sshd-sftp-2.12.1.jar'
  gradle> 'lib/plugins/sshd-core-2.12.1.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/sshd-core-2.12.1.jar'
  gradle> 'lib/plugins/sshd-common-2.12.1.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/sshd-common-2.12.1.jar'
  gradle> 'lib/plugins/jcommander-1.78.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/jcommander-1.78.jar'
  gradle> 'lib/plugins/org.eclipse.jgit-5.13.3.202401111512-r.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/org.eclipse.jgit-5.13.3.202401111512-r.jar'
  gradle> 'lib/plugins/joda-time-2.12.2.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/joda-time-2.12.2.jar'
  gradle> 'lib/plugins/jsch-0.2.16.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/jsch-0.2.16.jar'
  gradle> 'lib/plugins/jsoup-1.15.3.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/jsoup-1.15.3.jar'
  gradle> 'lib/plugins/maven-builder-support-3.9.5.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/maven-builder-support-3.9.5.jar'
  gradle> 'lib/plugins/maven-model-3.9.5.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/maven-model-3.9.5.jar'
  gradle> 'lib/plugins/maven-repository-metadata-3.9.5.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/maven-repository-metadata-3.9.5.jar'
  gradle> 'lib/plugins/maven-settings-3.9.5.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/maven-settings-3.9.5.jar'
  gradle> 'lib/plugins/plexus-interpolation-1.26.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/plexus-interpolation-1.26.jar'
  gradle> 'lib/plugins/plexus-utils-3.5.1.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/plexus-utils-3.5.1.jar'
  gradle> 'lib/plugins/dd-plist-1.27.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/dd-plist-1.27.jar'
  gradle> 'lib/plugins/snakeyaml-2.0.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/snakeyaml-2.0.jar'
  gradle> 'lib/plugins/gradle-java-compiler-plugin-8.8.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/gradle-java-compiler-plugin-8.8.jar'
  gradle> 'lib/plugins/gradle-instrumentation-declarations-8.8.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/gradle-instrumentation-declarations-8.8.jar'
  gradle> 'lib/plugins/opencensus-api-0.31.1.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/opencensus-api-0.31.1.jar'
  gradle> 'lib/plugins/eddsa-0.3.0.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/eddsa-0.3.0.jar'
  gradle> 'lib/plugins/opentest4j-1.2.0.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/opentest4j-1.2.0.jar'
  gradle> 'lib/plugins/grpc-context-1.27.2.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/plugins/grpc-context-1.27.2.jar'
  gradle> 'lib/agents' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/agents'
  gradle> 'lib/agents/gradle-instrumentation-agent-8.8.jar' -> '/nix/store/88j4nfnsysjrv7lxc1pdmjx8cm6gymal-gradle-8.8/libexec/gradle/lib/agents/gradle-instrumentation-agent-8.8.jar'
  gradle> java.io.FileNotFoundException:  (No such file or directory)
  gradle>         at java.base/java.io.FileInputStream.open0(Native Method)
  gradle>         at java.base/java.io.FileInputStream.open(FileInputStream.java:213)
  gradle>         at java.base/java.io.FileInputStream.<init>(FileInputStream.java:152)
  gradle>         at jdk.jartool/sun.tools.jar.Main.run(Main.java:350)
  gradle>         at jdk.jartool/sun.tools.jar.Main.main(Main.java:1702)
*/
