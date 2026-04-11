{
  overrides-fromsrc-bare,
  commons_codec_1_6,
  commons_codec_1_10,
  commons_codec_1_11,
  commons_codec_1_13,
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

  # WS-2019-0379 https://github.com/apache/incubator-kie-issues/issues/1785 Apache commons-codec before version “commons-codec-1.13-RC1” is vulnerable to information disclosure due to Improper Input validation.
  "commons-codec:commons-codec:1.0" = {
    "commons-codec-1.0.jar" = _: "${commons_codec_1_13}/commons-codec-1.13.jar";
  };
  "commons-codec:commons-codec:1.1" = {
    "commons-codec-1.1.jar" = _: "${commons_codec_1_13}/commons-codec-1.13.jar";
  };
  "commons-codec:commons-codec:1.2" = {
    "commons-codec-1.2.jar" = _: "${commons_codec_1_13}/commons-codec-1.13.jar";
  };
  "commons-codec:commons-codec:1.3" = {
    "commons-codec-1.3.jar" = _: "${commons_codec_1_13}/commons-codec-1.13.jar";
  };
  "commons-codec:commons-codec:1.4" = {
    "commons-codec-1.4.jar" = _: "${commons_codec_1_13}/commons-codec-1.13.jar";
  };
  "commons-codec:commons-codec:1.5" = {
    "commons-codec-1.5.jar" = _: "${commons_codec_1_13}/commons-codec-1.13.jar";
  };
  "commons-codec:commons-codec:1.6" = {
    "commons-codec-1.6.jar" = _: "${commons_codec_1_13}/commons-codec-1.13.jar";
    "commons-codec-1.6.pom" = _: "${commons_codec_1_6}/commons-codec-1.6.pom";
  };
  "commons-codec:commons-codec:1.7" = {
    "commons-codec-1.7.jar" = _: "${commons_codec_1_13}/commons-codec-1.13.jar";
  };
  "commons-codec:commons-codec:1.8" = {
    "commons-codec-1.8.jar" = _: "${commons_codec_1_13}/commons-codec-1.13.jar";
  };
  "commons-codec:commons-codec:1.9" = {
    "commons-codec-1.9.jar" = _: "${commons_codec_1_13}/commons-codec-1.13.jar";
  };
  "commons-codec:commons-codec:1.10" = {
    "commons-codec-1.10.jar" = _: "${commons_codec_1_13}/commons-codec-1.13.jar";
    "commons-codec-1.10.pom" = _: "${commons_codec_1_10}/commons-codec-1.10.pom";
  };
  "commons-codec:commons-codec:1.11" = {
    "commons-codec-1.11.jar" = _: "${commons_codec_1_13}/commons-codec-1.13.jar";
    "commons-codec-1.11.pom" = _: "${commons_codec_1_11}/commons-codec-1.11.pom";
  };
  "commons-codec:commons-codec:1.12" = {
    "commons-codec-1.12.jar" = _: "${commons_codec_1_13}/commons-codec-1.13.jar";
  };

  # TODO: gson [2.2.3,2.8.9) CVE-2022-25647 https://nvd.nist.gov/vuln/detail/cve-2022-25647
}
