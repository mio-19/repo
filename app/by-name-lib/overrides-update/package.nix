{
  overrides-from-source,
}:
{
  "com.google.code.gson:gson:2.10.1" = {
    "gson-2.10.1.jar" = overrides-from-source."com.google.code.gson:gson:2.11.0"."gson-2.11.0.jar";
    "gson-2.10.1.pom" = overrides-from-source."com.google.code.gson:gson:2.11.0"."gson-2.11.0.pom";
  };
  "com.google.code.gson:gson-parent:2.10.1" = {
    "gson-parent-2.10.1.pom" =
      overrides-from-source."com.google.code.gson:gson-parent:2.11.0"."gson-parent-2.11.0.pom";
  };
  "commons-io:commons-io:2.13.0" = {
    "commons-io-2.13.0.jar" =
      overrides-from-source."commons-io:commons-io:2.16.1"."commons-io-2.16.1.jar";
    "commons-io-2.13.0.pom" =
      overrides-from-source."commons-io:commons-io:2.16.1"."commons-io-2.16.1.pom";
  };
  "commons-codec:commons-codec:1.10" = {
    "commons-codec-1.10.jar" =
      overrides-from-source."commons-codec:commons-codec:1.17.1"."commons-codec-1.17.1.jar";
    "commons-codec-1.10.pom" =
      overrides-from-source."commons-codec:commons-codec:1.17.1"."commons-codec-1.17.1.pom";
  };
  "commons-codec:commons-codec:1.15" = {
    "commons-codec-1.15.jar" =
      overrides-from-source."commons-codec:commons-codec:1.17.1"."commons-codec-1.17.1.jar";
    "commons-codec-1.15.pom" =
      overrides-from-source."commons-codec:commons-codec:1.17.1"."commons-codec-1.17.1.pom";
  };
  "org.checkerframework:checker-qual:3.33.0" = {
    "checker-qual-3.33.0.jar" =
      overrides-from-source."org.checkerframework:checker-qual:3.43.0"."checker-qual-3.43.0.jar";
    "checker-qual-3.33.0.pom" =
      overrides-from-source."org.checkerframework:checker-qual:3.43.0"."checker-qual-3.43.0.pom";
  };
}
