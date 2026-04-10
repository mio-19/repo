# before https://github.com/gradle/gradle/commit/ee220a1cdf46e77025ba5c9b1dac449cafeaab0f
{
  temurin-bin-8,
  temurin-bin-11,
  temurin-bin-17,
  jdk21_headless,
  gradle_8_9_20240411,
  gradle-from-source,
  runCommand,
  jq,
  lib,
}:
gradle-from-source {
  version = "8.9.0-20240420";
  rev = "b38358b3d929ef3f81110fa04a411c9782371760";
  hash = "sha256-r0Cn1OH5LVjQE8EsfxXTpEAuNsXTCSwFjabUd4LGht8=";
  lockFile = runCommand "merged-lock" { } ''
    ${lib.getExe jq} -s '
      reduce .[] as $item ({}; . * $item)
      | del(.["gradle:gradle:8.10.2"])
    ' ${gradle_8_9_20240411.unwrapped.passthru.lockFile} ${../gradle_8_9_rc1/gradle.lock} ${./more.gradle.lock} > $out
  '';
  defaultJava = jdk21_headless;
  # this version specifically ask for termurin branded jdk.
  buildJdk = temurin-bin-11;
  javaToolchains = [
    temurin-bin-8
    temurin-bin-11
    temurin-bin-17
  ];
  bootstrapGradle = gradle_8_9_20240411;
}
