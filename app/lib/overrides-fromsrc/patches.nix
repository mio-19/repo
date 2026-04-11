{ self }:
# generally jar use newer version, pom keeps the same version.
{
  "com.google.zxing:core:3.5.3"."core-3.5.3.jar" =
    self."com.google.zxing:core:3.5.4"."core-3.5.4.jar";
  "com.google.guava:failureaccess:1.0.1"."failureaccess-1.0.1.jar" =
    self."com.google.guava:failureaccess:1.0.2"."failureaccess-1.0.2.jar";
  "org.slf4j:slf4j-api:1.7.28"."slf4j-api-1.7.28.jar" =
    self."org.slf4j:slf4j-api:1.7.29"."slf4j-api-1.7.29.jar";
  "org.slf4j:slf4j-api:1.7.29"."slf4j-api-1.7.29.jar" =
    self."org.slf4j:slf4j-api:1.7.30"."slf4j-api-1.7.30.jar";
  "org.slf4j:slf4j-api:1.7.30"."slf4j-api-1.7.30.jar" =
    self."org.slf4j:slf4j-api:1.7.31"."slf4j-api-1.7.31.jar";
  "org.slf4j:slf4j-api:1.7.31"."slf4j-api-1.7.31.jar" =
    self."org.slf4j:slf4j-api:1.7.32"."slf4j-api-1.7.32.jar";
  "org.slf4j:slf4j-api:1.7.32"."slf4j-api-1.7.32.jar" =
    self."org.slf4j:slf4j-api:1.7.33"."slf4j-api-1.7.33.jar";
  "org.slf4j:slf4j-api:1.7.33"."slf4j-api-1.7.33.jar" =
    self."org.slf4j:slf4j-api:1.7.34"."slf4j-api-1.7.34.jar";
  "org.slf4j:slf4j-api:1.7.34"."slf4j-api-1.7.34.jar" =
    self."org.slf4j:slf4j-api:1.7.35"."slf4j-api-1.7.35.jar";
  "org.slf4j:slf4j-api:1.7.35"."slf4j-api-1.7.35.jar" =
    self."org.slf4j:slf4j-api:1.7.36"."slf4j-api-1.7.36.jar";

  # WS-2019-0379 https://github.com/apache/incubator-kie-issues/issues/1785 Apache commons-codec before version “commons-codec-1.13-RC1” is vulnerable to information disclosure due to Improper Input validation.
  "commons-codec:commons-codec:1.0"."commons-codec-1.0.jar" =
    self."commons-codec:commons-codec:1.1"."commons-codec-1.1.jar";
  "commons-codec:commons-codec:1.1"."commons-codec-1.1.jar" =
    self."commons-codec:commons-codec:1.2"."commons-codec-1.2.jar";
  "commons-codec:commons-codec:1.2"."commons-codec-1.2.jar" =
    self."commons-codec:commons-codec:1.3"."commons-codec-1.3.jar";
  "commons-codec:commons-codec:1.3"."commons-codec-1.3.jar" =
    self."commons-codec:commons-codec:1.4"."commons-codec-1.4.jar";
  "commons-codec:commons-codec:1.4"."commons-codec-1.4.jar" =
    self."commons-codec:commons-codec:1.5"."commons-codec-1.5.jar";
  "commons-codec:commons-codec:1.5"."commons-codec-1.5.jar" =
    self."commons-codec:commons-codec:1.6"."commons-codec-1.6.jar";
  "commons-codec:commons-codec:1.6"."commons-codec-1.6.jar" =
    self."commons-codec:commons-codec:1.7"."commons-codec-1.7.jar";
  "commons-codec:commons-codec:1.7"."commons-codec-1.7.jar" =
    self."commons-codec:commons-codec:1.8"."commons-codec-1.8.jar";
  "commons-codec:commons-codec:1.8"."commons-codec-1.8.jar" =
    self."commons-codec:commons-codec:1.9"."commons-codec-1.9.jar";
  "commons-codec:commons-codec:1.9"."commons-codec-1.9.jar" =
    self."commons-codec:commons-codec:1.10"."commons-codec-1.10.jar";
  "commons-codec:commons-codec:1.10"."commons-codec-1.10.jar" =
    self."commons-codec:commons-codec:1.11"."commons-codec-1.11.jar";
  "commons-codec:commons-codec:1.11"."commons-codec-1.11.jar" =
    self."commons-codec:commons-codec:1.12"."commons-codec-1.12.jar";
  "commons-codec:commons-codec:1.12"."commons-codec-1.12.jar" =
    self."commons-codec:commons-codec:1.13"."commons-codec-1.13.jar";

  # gson [2.2.3,2.8.9) CVE-2022-25647 https://nvd.nist.gov/vuln/detail/cve-2022-25647
  "com.google.code.gson:gson:2.8.1"."gson-2.8.1.jar" =
    self."com.google.code.gson:gson:2.8.2"."gson-2.8.2.jar";
  "com.google.code.gson:gson:2.8.2"."gson-2.8.2.jar" =
    self."com.google.code.gson:gson:2.8.3"."gson-2.8.3.jar";
  "com.google.code.gson:gson:2.8.3"."gson-2.8.3.jar" =
    self."com.google.code.gson:gson:2.8.4"."gson-2.8.4.jar";
  "com.google.code.gson:gson:2.8.4"."gson-2.8.4.jar" =
    self."com.google.code.gson:gson:2.8.5"."gson-2.8.5.jar";
  "com.google.code.gson:gson:2.8.5"."gson-2.8.5.jar" =
    self."com.google.code.gson:gson:2.8.6"."gson-2.8.6.jar";
  "com.google.code.gson:gson:2.8.6"."gson-2.8.6.jar" =
    self."com.google.code.gson:gson:2.8.7"."gson-2.8.7.jar";
  "com.google.code.gson:gson:2.8.7"."gson-2.8.7.jar" =
    self."com.google.code.gson:gson:2.8.8"."gson-2.8.8.jar";
  "com.google.code.gson:gson:2.8.8"."gson-2.8.8.jar" =
    self."com.google.code.gson:gson:2.8.9"."gson-2.8.9.jar";

  # TODO: guava CVE-2023-2976 https://nvd.nist.gov/vuln/detail/cve-2023-2976 Even though the security vulnerability is fixed in version 32.0.0, we recommend using version 32.0.1 as version 32.0.0 breaks some functionality under Windows.
}
