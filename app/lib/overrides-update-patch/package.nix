{
  overrides-fromsrc-bare,
}:
# generally jar use newer version, pom keeps the same version.
{
  "com.google.zxing:core:3.5.3" = {
    "core-3.5.3.jar" = overrides-fromsrc-bare."com.google.zxing:core:3.5.4"."core-3.5.4.jar";
    "core-3.5.3.pom" = overrides-fromsrc-bare."com.google.zxing:core:3.5.3"."core-3.5.3.pom";
  };
  "com.google.guava:failureaccess:1.0.1" = {
    "failureaccess-1.0.1.jar" =
      overrides-fromsrc-bare."com.google.guava:failureaccess:1.0.2"."failureaccess-1.0.2.jar";
    "failureaccess-1.0.1.pom" =
      overrides-fromsrc-bare."com.google.guava:failureaccess:1.0.1"."failureaccess-1.0.1.pom";
  };
}
