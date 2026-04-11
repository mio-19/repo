{ self }:
# generally jar use newer version, pom keeps the same version.
{
  "com.google.code.gson:gson:2.10.1" = {
    "gson-2.10.1.jar" = self."com.google.code.gson:gson:2.11.0"."gson-2.11.0.jar";
  };
  "commons-io:commons-io:2.13.0" = {
    "commons-io-2.13.0.jar" = self."commons-io:commons-io:2.16.1"."commons-io-2.16.1.jar";
  };
  "commons-codec:commons-codec:1.10" = {
    "commons-codec-1.10.jar" = self."commons-codec:commons-codec:1.15"."commons-codec-1.15.jar";
  };
  "commons-codec:commons-codec:1.15" = {
    "commons-codec-1.15.jar" = self."commons-codec:commons-codec:1.17.1"."commons-codec-1.17.1.jar";
  };
  "org.checkerframework:checker-qual:3.33.0" = {
    "checker-qual-3.33.0.jar" =
      self."org.checkerframework:checker-qual:3.43.0"."checker-qual-3.43.0.jar";
  };
  "com.google.errorprone:error_prone_annotations:2.3.1" = {
    "error_prone_annotations-2.3.1.jar" =
      self."com.google.errorprone:error_prone_annotations:2.15.0"."error_prone_annotations-2.15.0.jar";
  };
  "com.google.errorprone:error_prone_annotations:2.15.0" = {
    "error_prone_annotations-2.15.0.jar" =
      self."com.google.errorprone:error_prone_annotations:2.18.0"."error_prone_annotations-2.18.0.jar";
  };
  "com.google.errorprone:error_prone_annotations:2.18.0" = {
    "error_prone_annotations-2.18.0.jar" =
      self."com.google.errorprone:error_prone_annotations:2.27.0"."error_prone_annotations-2.27.0.jar";
  };
  "com.google.errorprone:error_prone_annotations:2.27.0" = {
    "error_prone_annotations-2.27.0.jar" =
      self."com.google.errorprone:error_prone_annotations:2.28.0"."error_prone_annotations-2.28.0.jar";
  };
  "com.google.errorprone:error_prone_annotations:2.28.0" = {
    "error_prone_annotations-2.28.0.jar" =
      self."com.google.errorprone:error_prone_annotations:2.30.0"."error_prone_annotations-2.30.0.jar";
  };
  "com.google.errorprone:error_prone_annotations:2.30.0" = {
    "error_prone_annotations-2.30.0.jar" =
      self."com.google.errorprone:error_prone_annotations:2.41.0"."error_prone_annotations-2.41.0.jar";
  };
  "org.slf4j:slf4j-api:1.7.30" = {
    "slf4j-api-1.7.30.jar" = self."org.slf4j:slf4j-api:1.7.36"."slf4j-api-1.7.36.jar";
  };
  "com.google.j2objc:j2objc-annotations:3.0.0" = {
    "j2objc-annotations-3.0.0.jar" =
      self."com.google.j2objc:j2objc-annotations:3.1"."j2objc-annotations-3.1.jar";
  };
  "com.google.auto.value:auto-value-annotations:1.6.2" = {
    "auto-value-annotations-1.6.2.jar" =
      self."com.google.auto.value:auto-value-annotations:1.6.3"."auto-value-annotations-1.6.3.jar";
  };
}
