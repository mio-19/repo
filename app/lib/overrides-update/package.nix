{
  overrides-fromsrc-bare,
  overrides-update-patch,
}:
# generally jar use newer version, pom keeps the same version.
overrides-update-patch
// {
  "com.google.code.gson:gson:2.10.1" = {
    "gson-2.10.1.jar" = overrides-fromsrc-bare."com.google.code.gson:gson:2.11.0"."gson-2.11.0.jar";
    "gson-2.10.1.pom" = overrides-fromsrc-bare."com.google.code.gson:gson:2.10.1"."gson-2.10.1.pom";
  };
  "commons-io:commons-io:2.13.0" = {
    "commons-io-2.13.0.jar" =
      overrides-fromsrc-bare."commons-io:commons-io:2.16.1"."commons-io-2.16.1.jar";
    "commons-io-2.13.0.pom" =
      overrides-fromsrc-bare."commons-io:commons-io:2.13.0"."commons-io-2.13.0.pom";
  };
  "commons-codec:commons-codec:1.10" = {
    "commons-codec-1.10.jar" =
      overrides-fromsrc-bare."commons-codec:commons-codec:1.17.1"."commons-codec-1.17.1.jar";
    "commons-codec-1.10.pom" =
      overrides-fromsrc-bare."commons-codec:commons-codec:1.10"."commons-codec-1.10.pom";
  };
  "commons-codec:commons-codec:1.15" = {
    "commons-codec-1.15.jar" =
      overrides-fromsrc-bare."commons-codec:commons-codec:1.17.1"."commons-codec-1.17.1.jar";
    "commons-codec-1.15.pom" =
      overrides-fromsrc-bare."commons-codec:commons-codec:1.15"."commons-codec-1.15.pom";
  };
  "org.checkerframework:checker-qual:3.33.0" = {
    "checker-qual-3.33.0.jar" =
      overrides-fromsrc-bare."org.checkerframework:checker-qual:3.43.0"."checker-qual-3.43.0.jar";
    "checker-qual-3.33.0.pom" =
      overrides-fromsrc-bare."org.checkerframework:checker-qual:3.33.0"."checker-qual-3.33.0.pom";
  };
  "com.google.errorprone:error_prone_annotations:2.3.1" = {
    "error_prone_annotations-2.3.1.jar" =
      overrides-fromsrc-bare."com.google.errorprone:error_prone_annotations:2.41.0"."error_prone_annotations-2.41.0.jar";
    "error_prone_annotations-2.3.1.pom" =
      overrides-fromsrc-bare."com.google.errorprone:error_prone_annotations:2.3.1"."error_prone_annotations-2.3.1.pom";
  };
  "com.google.errorprone:error_prone_annotations:2.15.0" = {
    "error_prone_annotations-2.15.0.jar" =
      overrides-fromsrc-bare."com.google.errorprone:error_prone_annotations:2.41.0"."error_prone_annotations-2.41.0.jar";
    "error_prone_annotations-2.15.0.pom" =
      overrides-fromsrc-bare."com.google.errorprone:error_prone_annotations:2.15.0"."error_prone_annotations-2.15.0.pom";
  };
  "com.google.errorprone:error_prone_annotations:2.18.0" = {
    "error_prone_annotations-2.18.0.jar" =
      overrides-fromsrc-bare."com.google.errorprone:error_prone_annotations:2.41.0"."error_prone_annotations-2.41.0.jar";
    "error_prone_annotations-2.18.0.pom" =
      overrides-fromsrc-bare."com.google.errorprone:error_prone_annotations:2.18.0"."error_prone_annotations-2.18.0.pom";
  };
  "com.google.errorprone:error_prone_annotations:2.27.0" = {
    "error_prone_annotations-2.27.0.jar" =
      overrides-fromsrc-bare."com.google.errorprone:error_prone_annotations:2.41.0"."error_prone_annotations-2.41.0.jar";
    "error_prone_annotations-2.27.0.pom" =
      overrides-fromsrc-bare."com.google.errorprone:error_prone_annotations:2.27.0"."error_prone_annotations-2.27.0.pom";
  };
  "com.google.errorprone:error_prone_annotations:2.28.0" = {
    "error_prone_annotations-2.28.0.jar" =
      overrides-fromsrc-bare."com.google.errorprone:error_prone_annotations:2.41.0"."error_prone_annotations-2.41.0.jar";
    "error_prone_annotations-2.28.0.pom" =
      overrides-fromsrc-bare."com.google.errorprone:error_prone_annotations:2.28.0"."error_prone_annotations-2.28.0.pom";
  };
  "com.google.errorprone:error_prone_annotations:2.30.0" = {
    "error_prone_annotations-2.30.0.jar" =
      overrides-fromsrc-bare."com.google.errorprone:error_prone_annotations:2.41.0"."error_prone_annotations-2.41.0.jar";
    "error_prone_annotations-2.30.0.pom" =
      overrides-fromsrc-bare."com.google.errorprone:error_prone_annotations:2.30.0"."error_prone_annotations-2.30.0.pom";
  };
  "org.slf4j:slf4j-api:1.7.30" = {
    "slf4j-api-1.7.30.jar" = overrides-fromsrc-bare."org.slf4j:slf4j-api:1.7.36"."slf4j-api-1.7.36.jar";
    "slf4j-api-1.7.30.pom" = overrides-fromsrc-bare."org.slf4j:slf4j-api:1.7.30"."slf4j-api-1.7.30.pom";
  };
  "com.google.j2objc:j2objc-annotations:3.0.0" = {
    "j2objc-annotations-3.0.0.jar" =
      overrides-fromsrc-bare."com.google.j2objc:j2objc-annotations:3.1"."j2objc-annotations-3.1.jar";
    "j2objc-annotations-3.0.0.pom" =
      overrides-fromsrc-bare."com.google.j2objc:j2objc-annotations:3.0.0"."j2objc-annotations-3.0.0.pom";
  };
  "com.google.guava:failureaccess:1.0.1" = {
    "failureaccess-1.0.1.jar" =
      overrides-fromsrc-bare."com.google.guava:failureaccess:1.0.2"."failureaccess-1.0.2.jar";
    "failureaccess-1.0.1.pom" =
      overrides-fromsrc-bare."com.google.guava:failureaccess:1.0.1"."failureaccess-1.0.1.pom";
  };
  "com.google.auto.value:auto-value-annotations:1.6.2" = {
    "auto-value-annotations-1.6.2.jar" =
      overrides-fromsrc-bare."com.google.auto.value:auto-value-annotations:1.6.3"."auto-value-annotations-1.6.3.jar";
    "auto-value-annotations-1.6.2.pom" =
      overrides-fromsrc-bare."com.google.auto.value:auto-value-annotations:1.6.2"."auto-value-annotations-1.6.2.pom";
  };
}
