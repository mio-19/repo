{
  apache_21,
  apache_32,
  apache_33,
  apache_31,
  annotations_23_0_0,
  antlr_2_7_7,
  aopalliance_1_0,
  asm_9_9,
  asm_analysis_9_9,
  auto_service_annotations_1_0_1,
  auto_parent_6,
  auto_value_annotations_1_6_2,
  auto_value_annotations_1_6_3,
  asm_commons_9_9,
  asm_tree_9_9,
  checker_qual_3_33_0,
  checker_qual_3_41_0,
  checker_qual_3_42_0,
  checker_qual_3_43_0,
  checker_qual_3_49_2,
  checker_qual_3_49_3,
  brotli_dec_0_1_2,
  dd_plist_1_21,
  dd_plist_1_27,
  checker_qual_3_37_0,
  error_prone_annotations_2_41_0,
  error_prone_annotations_2_1_3,
  error_prone_annotations_2_5_1,
  error_prone_annotations_2_11_0,
  error_prone_annotations_2_23_0,
  error_prone_annotations_2_3_2,
  error_prone_annotations_2_3_4,
  error_prone_annotations_2_26_1,
  error_prone_annotations_2_29_0,
  error_prone_annotations_2_31_0,
  error_prone_annotations_2_36_0,
  error_prone_annotations_2_37_0,
  error_prone_annotations_2_38_0,
  error_prone_annotations_2_42_0,
  commons_codec_1_2,
  commons_codec_1_10,
  commons_codec_1_11,
  commons_codec_1_13,
  commons_codec_1_15,
  commons_codec_1_17_1,
  commons_codec_1_19_0,
  commons_lang3_3_12_0,
  commons_lang3_3_16_0,
  commons_lang_2_6,
  commons_io_2_6,
  commons_io_2_11_0,
  commons_io_2_13_0,
  commons_io_2_14_0,
  commons_io_2_15_1,
  commons_io_2_16_1,
  commons_io_2_18_0,
  commons_io_2_20_0,
  commons_io_2_21_0,
  commons_logging_1_2,
  commons_parent_34,
  commons_parent_69,
  commons_parent_71,
  commons_parent_72,
  error_prone_annotations_2_15_0,
  error_prone_annotations_2_18_0,
  error_prone_annotations_2_3_1,
  error_prone_annotations_2_27_0,
  error_prone_annotations_2_28_0,
  error_prone_annotations_2_30_0,
  failureaccess_1_0_1,
  failureaccess_1_0_2,
  gson_2_9_0,
  gson_2_9_1,
  gson_2_10_1,
  gson_2_11_0,
  gson_2_8_6,
  gson_2_8_9,
  gson_2_12_1,
  gson_2_13_0,
  gson_2_13_1,
  gson_2_13_2,
  glide_5_0_5,
  flatbuffers_java_1_12_0,
  guava_31_1_android,
  guava_33_3_1_jre,
  httpcomponents_client_4_5_14,
  httpcomponents_core_4_4_16,
  istack_commons_runtime_3_0_8,
  javaparser_core_3_17_0,
  javaparser_core_3_18_0,
  javaparser_core_3_25_6,
  javax_servlet_api_3_1_0,
  java_diff_utils_4_16,
  javax_inject_1,
  javawriter_2_5_0,
  jakarta_activation_api_1_2_1,
  jakarta_xml_bind_api_2_3_2,
  javapoet_1_13_0,
  javapoet_1_10_0,
  j2objc_annotations_1_1,
  j2objc_annotations_1_3,
  j2objc_annotations_2_8,
  j2objc_annotations_3_0_0,
  j2objc_annotations_3_1,
  jcommander_1_35,
  jcommander_1_78,
  jcommander_1_82,
  jopt_simple_4_9,
  jdom2_2_0_6,
  jspecify_1_0_0,
  jsr305_3_0_2,
  juniversalchardet_1_0_3,
  kotlin_result_2_1_0,
  kotlin_retry_2_0_2,
  kotlinx_io_0_8_2,
  oss_parent_7,
  protobuf_bom_3_25_5,
  protobuf_parent_3_25_5,
  listenablefuture_1_0,
  listenablefuture_9999_0_empty_to_avoid_conflict_with_guava,
  slf4j_1_7_2,
  slf4j_1_7_10,
  slf4j_api_1_7_30,
  slf4j_api_1_7_36,
  slf4j_api_2_0_17,
  xz_java_1_6,
  xz_java_1_9,
  zxing_core_3_5_3,
  zxing_core_3_5_4,
  zoomimage_1_0_2,
  gradle_8_11,
  gradle_8_11_1,
  gradle_8_12_1,
  gradle_8_13,
  gradle_8_14,
  gradle_8_14_3,
  gradle_9_4_0,

  runCommand,
  zip,
}:
let
  mkGradleZip =
    gradle:
    runCommand "gradle-${gradle.version}-fromsource.zip"
      {
        nativeBuildInputs = [ zip ];
      }
      ''
        cd ${gradle}/libexec/gradle
        zip -r "$out" .
      '';
  mkMavenSourceJarOverride = artifactId: version: package: {
    "${artifactId}-${version}.jar" = _: "${package}/${artifactId}-${version}.jar";
    "${artifactId}-${version}.pom" = _: "${package}/${artifactId}-${version}.pom";
  };
in
{
  "antlr:antlr:2.7.7" = {
    "antlr-2.7.7.jar" = _: "${antlr_2_7_7}/antlr-2.7.7.jar";
    "antlr-2.7.7.pom" = _: "${antlr_2_7_7}/antlr-2.7.7.pom";
  };
  "aopalliance:aopalliance:1.0" = {
    "aopalliance-1.0.jar" = _: "${aopalliance_1_0}/aopalliance-1.0.jar";
    "aopalliance-1.0.pom" = _: "${aopalliance_1_0}/aopalliance-1.0.pom";
  };
  "gradle:gradle:8.11" = {
    "gradle-8.11.zip" = _: mkGradleZip gradle_8_11;
  };
  "gradle:gradle:8.11.1" = {
    "gradle-8.11.1.zip" = _: mkGradleZip gradle_8_11_1;
  };
  "gradle:gradle:8.12.1" = {
    "gradle-8.12.1.zip" = _: mkGradleZip gradle_8_12_1;
  };
  "gradle:gradle:8.13" = {
    "gradle-8.13.zip" = _: mkGradleZip gradle_8_13;
  };
  "gradle:gradle:8.14" = {
    "gradle-8.14.zip" = _: mkGradleZip gradle_8_14;
  };
  "gradle:gradle:8.14.3" = {
    "gradle-8.14.3.zip" = _: mkGradleZip gradle_8_14_3;
  };
  "gradle:gradle:9.4.0" = {
    "gradle-9.4.0.zip" = _: mkGradleZip gradle_9_4_0;
  };
  "com.google.auto.value:auto-value-annotations:1.6.2" = {
    "auto-value-annotations-1.6.2.jar" =
      _: "${auto_value_annotations_1_6_2}/auto-value-annotations-1.6.2.jar";
    "auto-value-annotations-1.6.2.pom" =
      _: "${auto_value_annotations_1_6_2}/auto-value-annotations-1.6.2.pom";
  };
  "com.google.auto.value:auto-value-annotations:1.6.3" = {
    "auto-value-annotations-1.6.3.jar" =
      _: "${auto_value_annotations_1_6_3}/auto-value-annotations-1.6.3.jar";
    "auto-value-annotations-1.6.3.pom" =
      _: "${auto_value_annotations_1_6_3}/auto-value-annotations-1.6.3.pom";
  };
  "com.google.auto.value:auto-value-parent:1.6.2" = {
    "auto-value-parent-1.6.2.pom" = _: "${auto_value_annotations_1_6_2}/auto-value-parent-1.6.2.pom";
  };
  "com.google.auto.value:auto-value-parent:1.6.3" = {
    "auto-value-parent-1.6.3.pom" = _: "${auto_value_annotations_1_6_3}/auto-value-parent-1.6.3.pom";
  };
  "com.google.auto:auto-parent:6" = {
    "auto-parent-6.pom" = _: "${auto_parent_6}/auto-parent-6.pom";
  };
  "com.google.auto.service:auto-service-aggregator:1.0.1" = {
    "auto-service-aggregator-1.0.1.pom" =
      _: "${auto_service_annotations_1_0_1}/auto-service-aggregator-1.0.1.pom";
  };
  "com.google.auto.service:auto-service-annotations:1.0.1" = {
    "auto-service-annotations-1.0.1.jar" =
      _: "${auto_service_annotations_1_0_1}/auto-service-annotations-1.0.1.jar";
    "auto-service-annotations-1.0.1.pom" =
      _: "${auto_service_annotations_1_0_1}/auto-service-annotations-1.0.1.pom";
  };
  "com.beust:jcommander:1.35" = mkMavenSourceJarOverride "jcommander" "1.35" jcommander_1_35;
  "com.beust:jcommander:1.78" = mkMavenSourceJarOverride "jcommander" "1.78" jcommander_1_78;
  "com.beust:jcommander:1.82" = mkMavenSourceJarOverride "jcommander" "1.82" jcommander_1_82;
  "com.github.javaparser:javaparser-core:3.17.0" =
    mkMavenSourceJarOverride "javaparser-core" "3.17.0"
      javaparser_core_3_17_0;
  "com.github.javaparser:javaparser-core:3.18.0" =
    mkMavenSourceJarOverride "javaparser-core" "3.18.0"
      javaparser_core_3_18_0;
  "com.github.javaparser:javaparser-core:3.25.6" =
    mkMavenSourceJarOverride "javaparser-core" "3.25.6"
      javaparser_core_3_25_6;
  "com.google.code.findbugs:jsr305:3.0.2" = {
    "jsr305-3.0.2.jar" = _: "${jsr305_3_0_2}/jsr305-3.0.2.jar";
    "jsr305-3.0.2.pom" = _: "${jsr305_3_0_2}/jsr305-3.0.2.pom";
  };
  "com.google.protobuf:protobuf-parent:3.25.5" = {
    "protobuf-parent-3.25.5.pom" = _: "${protobuf_parent_3_25_5}/protobuf-parent-3.25.5.pom";
  };
  "com.google.protobuf:protobuf-bom:3.25.5" = {
    "protobuf-bom-3.25.5.pom" = _: "${protobuf_bom_3_25_5}/protobuf-bom-3.25.5.pom";
  };

  "com.google.code.gson:gson:2.11.0" = {
    "gson-2.11.0.jar" = _: "${gson_2_11_0}/gson-2.11.0.jar";
    "gson-2.11.0.pom" = _: "${gson_2_11_0}/gson-2.11.0.pom";
  };
  "com.google.code.gson:gson:2.10.1" = {
    "gson-2.10.1.jar" = _: "${gson_2_10_1}/gson-2.10.1.jar";
    "gson-2.10.1.pom" = _: "${gson_2_10_1}/gson-2.10.1.pom";
  };
  "com.google.code.gson:gson:2.8.9" = {
    "gson-2.8.9.jar" = _: "${gson_2_8_9}/gson-2.8.9.jar";
    "gson-2.8.9.pom" = _: "${gson_2_8_9}/gson-2.8.9.pom";
  };
  "com.google.code.gson:gson:2.8.6" = {
    "gson-2.8.6.jar" = _: "${gson_2_8_6}/gson-2.8.6.jar";
    "gson-2.8.6.pom" = _: "${gson_2_8_6}/gson-2.8.6.pom";
  };
  "com.google.code.gson:gson:2.9.0" = {
    "gson-2.9.0.jar" = _: "${gson_2_9_0}/gson-2.9.0.jar";
    "gson-2.9.0.pom" = _: "${gson_2_9_0}/gson-2.9.0.pom";
  };
  "com.google.code.gson:gson:2.9.1" = {
    "gson-2.9.1.jar" = _: "${gson_2_9_1}/gson-2.9.1.jar";
    "gson-2.9.1.pom" = _: "${gson_2_9_1}/gson-2.9.1.pom";
  };
  "com.google.code.gson:gson:2.12.1" = {
    "gson-2.12.1.jar" = _: "${gson_2_12_1}/gson-2.12.1.jar";
    "gson-2.12.1.pom" = _: "${gson_2_12_1}/gson-2.12.1.pom";
  };
  "com.google.code.gson:gson:2.13.0" = {
    "gson-2.13.0.jar" = _: "${gson_2_13_0}/gson-2.13.0.jar";
    "gson-2.13.0.pom" = _: "${gson_2_13_0}/gson-2.13.0.pom";
  };
  "com.google.code.gson:gson:2.13.1" = {
    "gson-2.13.1.jar" = _: "${gson_2_13_1}/gson-2.13.1.jar";
    "gson-2.13.1.pom" = _: "${gson_2_13_1}/gson-2.13.1.pom";
  };
  "com.google.code.gson:gson:2.13.2" = {
    "gson-2.13.2.jar" = _: "${gson_2_13_2}/gson-2.13.2.jar";
    "gson-2.13.2.pom" = _: "${gson_2_13_2}/gson-2.13.2.pom";
  };
  "com.google.code.gson:gson-parent:2.11.0" = {
    "gson-parent-2.11.0.pom" = _: "${gson_2_11_0}/gson-parent-2.11.0.pom";
  };
  "com.google.code.gson:gson-parent:2.10.1" = {
    "gson-parent-2.10.1.pom" = _: "${gson_2_10_1}/gson-parent-2.10.1.pom";
  };
  "com.google.code.gson:gson-parent:2.8.6" = {
    "gson-parent-2.8.6.pom" = _: "${gson_2_8_6}/gson-parent-2.8.6.pom";
  };
  "com.google.code.gson:gson-parent:2.8.9" = {
    "gson-parent-2.8.9.pom" = _: "${gson_2_8_9}/gson-parent-2.8.9.pom";
  };
  "com.google.code.gson:gson-parent:2.9.0" = {
    "gson-parent-2.9.0.pom" = _: "${gson_2_9_0}/gson-parent-2.9.0.pom";
  };
  "com.google.code.gson:gson-parent:2.9.1" = {
    "gson-parent-2.9.1.pom" = _: "${gson_2_9_1}/gson-parent-2.9.1.pom";
  };
  "com.google.code.gson:gson-parent:2.12.1" = {
    "gson-parent-2.12.1.pom" = _: "${gson_2_12_1}/gson-parent-2.12.1.pom";
  };
  "com.google.code.gson:gson-parent:2.13.0" = {
    "gson-parent-2.13.0.pom" = _: "${gson_2_13_0}/gson-parent-2.13.0.pom";
  };
  "com.google.code.gson:gson-parent:2.13.1" = {
    "gson-parent-2.13.1.pom" = _: "${gson_2_13_1}/gson-parent-2.13.1.pom";
  };
  "com.google.code.gson:gson-parent:2.13.2" = {
    "gson-parent-2.13.2.pom" = _: "${gson_2_13_2}/gson-parent-2.13.2.pom";
  };
  "com.github.bumptech.glide:disklrucache:5.0.5" = {
    "disklrucache-5.0.5.aar" = _: "${glide_5_0_5}/disklrucache-5.0.5.aar";
    "disklrucache-5.0.5.module" = _: "${glide_5_0_5}/disklrucache-5.0.5.module";
    "disklrucache-5.0.5.pom" = _: "${glide_5_0_5}/disklrucache-5.0.5.pom";
  };
  "com.github.bumptech.glide:gifdecoder:5.0.5" = {
    "gifdecoder-5.0.5.aar" = _: "${glide_5_0_5}/gifdecoder-5.0.5.aar";
    "gifdecoder-5.0.5.module" = _: "${glide_5_0_5}/gifdecoder-5.0.5.module";
    "gifdecoder-5.0.5.pom" = _: "${glide_5_0_5}/gifdecoder-5.0.5.pom";
  };
  "com.github.bumptech.glide:glide:5.0.5" = {
    "glide-5.0.5.aar" = _: "${glide_5_0_5}/glide-5.0.5.aar";
    "glide-5.0.5.module" = _: "${glide_5_0_5}/glide-5.0.5.module";
    "glide-5.0.5.pom" = _: "${glide_5_0_5}/glide-5.0.5.pom";
  };
  "org.jetbrains:annotations:23.0.0" = {
    "annotations-23.0.0.jar" = _: "${annotations_23_0_0}/annotations-23.0.0.jar";
    "annotations-23.0.0.pom" = _: "${annotations_23_0_0}/annotations-23.0.0.pom";
  };
  "org.ow2.asm:asm:9.9" = {
    "asm-9.9.jar" = _: "${asm_9_9}/asm-9.9.jar";
    "asm-9.9.pom" = _: "${asm_9_9}/asm-9.9.pom";
  };
  "org.ow2.asm:asm-analysis:9.9" = {
    "asm-analysis-9.9.jar" = _: "${asm_analysis_9_9}/asm-analysis-9.9.jar";
    "asm-analysis-9.9.pom" = _: "${asm_analysis_9_9}/asm-analysis-9.9.pom";
  };
  "org.ow2.asm:asm-commons:9.9" = {
    "asm-commons-9.9.jar" = _: "${asm_commons_9_9}/asm-commons-9.9.jar";
    "asm-commons-9.9.pom" = _: "${asm_commons_9_9}/asm-commons-9.9.pom";
  };
  "org.ow2.asm:asm-tree:9.9" = {
    "asm-tree-9.9.jar" = _: "${asm_tree_9_9}/asm-tree-9.9.jar";
    "asm-tree-9.9.pom" = _: "${asm_tree_9_9}/asm-tree-9.9.pom";
  };
  "commons-io:commons-io:2.6" = {
    "commons-io-2.6.jar" = _: "${commons_io_2_6}/commons-io-2.6.jar";
    "commons-io-2.6.pom" = _: "${commons_io_2_6}/commons-io-2.6.pom";
  };
  "commons-io:commons-io:2.11.0" = mkMavenSourceJarOverride "commons-io" "2.11.0" commons_io_2_11_0;
  "commons-io:commons-io:2.13.0" = {
    "commons-io-2.13.0.jar" = _: "${commons_io_2_13_0}/commons-io-2.13.0.jar";
    "commons-io-2.13.0.pom" = _: "${commons_io_2_13_0}/commons-io-2.13.0.pom";
  };
  "commons-io:commons-io:2.14.0" = mkMavenSourceJarOverride "commons-io" "2.14.0" commons_io_2_14_0;
  "commons-io:commons-io:2.15.1" = mkMavenSourceJarOverride "commons-io" "2.15.1" commons_io_2_15_1;
  "commons-io:commons-io:2.16.1" = {
    "commons-io-2.16.1.jar" = _: "${commons_io_2_16_1}/commons-io-2.16.1.jar";
    "commons-io-2.16.1.pom" = _: "${commons_io_2_16_1}/commons-io-2.16.1.pom";
  };
  "commons-io:commons-io:2.18.0" = mkMavenSourceJarOverride "commons-io" "2.18.0" commons_io_2_18_0;
  "commons-io:commons-io:2.20.0" = mkMavenSourceJarOverride "commons-io" "2.20.0" commons_io_2_20_0;
  "commons-io:commons-io:2.21.0" = {
    "commons-io-2.21.0.jar" = _: "${commons_io_2_21_0}/commons-io-2.21.0.jar";
    "commons-io-2.21.0.pom" = _: "${commons_io_2_21_0}/commons-io-2.21.0.pom";
  };
  "commons-codec:commons-codec:1.2" = {
    "commons-codec-1.2.jar" = _: "${commons_codec_1_2}/commons-codec-1.2.jar";
    "commons-codec-1.2.pom" = _: "${commons_codec_1_2}/commons-codec-1.2.pom";
  };
  "commons-codec:commons-codec:1.10" = {
    "commons-codec-1.10.jar" = _: "${commons_codec_1_10}/commons-codec-1.10.jar";
    "commons-codec-1.10.pom" = _: "${commons_codec_1_10}/commons-codec-1.10.pom";
  };
  "commons-codec:commons-codec:1.11" = {
    "commons-codec-1.11.jar" = _: "${commons_codec_1_11}/commons-codec-1.11.jar";
    "commons-codec-1.11.pom" = _: "${commons_codec_1_11}/commons-codec-1.11.pom";
  };
  "commons-codec:commons-codec:1.13" = {
    "commons-codec-1.13.jar" = _: "${commons_codec_1_13}/commons-codec-1.13.jar";
    "commons-codec-1.13.pom" = _: "${commons_codec_1_13}/commons-codec-1.13.pom";
  };
  "commons-codec:commons-codec:1.15" = {
    "commons-codec-1.15.jar" = _: "${commons_codec_1_15}/commons-codec-1.15.jar";
    "commons-codec-1.15.pom" = _: "${commons_codec_1_15}/commons-codec-1.15.pom";
  };
  "commons-codec:commons-codec:1.17.1" = {
    "commons-codec-1.17.1.jar" = _: "${commons_codec_1_17_1}/commons-codec-1.17.1.jar";
    "commons-codec-1.17.1.pom" = _: "${commons_codec_1_17_1}/commons-codec-1.17.1.pom";
  };
  "commons-codec:commons-codec:1.19.0" = {
    "commons-codec-1.19.0.jar" = _: "${commons_codec_1_19_0}/commons-codec-1.19.0.jar";
    "commons-codec-1.19.0.pom" = _: "${commons_codec_1_19_0}/commons-codec-1.19.0.pom";
  };
  "commons-lang:commons-lang:2.6" = {
    "commons-lang-2.6.jar" = _: "${commons_lang_2_6}/commons-lang-2.6.jar";
    "commons-lang-2.6.pom" = _: "${commons_lang_2_6}/commons-lang-2.6.pom";
  };
  "org.apache.commons:commons-lang3:3.12.0" =
    mkMavenSourceJarOverride "commons-lang3" "3.12.0"
      commons_lang3_3_12_0;
  "org.apache.commons:commons-lang3:3.16.0" = {
    "commons-lang3-3.16.0.jar" = _: "${commons_lang3_3_16_0}/commons-lang3-3.16.0.jar";
    "commons-lang3-3.16.0.pom" = _: "${commons_lang3_3_16_0}/commons-lang3-3.16.0.pom";
  };
  "commons-logging:commons-logging:1.2" = {
    "commons-logging-1.2.jar" = _: "${commons_logging_1_2}/commons-logging-1.2.jar";
    "commons-logging-1.2.pom" = _: "${commons_logging_1_2}/commons-logging-1.2.pom";
  };
  "com.sun.istack:istack-commons:3.0.8" = {
    "istack-commons-3.0.8.pom" = _: "${istack_commons_runtime_3_0_8}/istack-commons-3.0.8.pom";
  };
  "com.sun.istack:istack-commons-runtime:3.0.8" = {
    "istack-commons-runtime-3.0.8.jar" =
      _: "${istack_commons_runtime_3_0_8}/istack-commons-runtime-3.0.8.jar";
    "istack-commons-runtime-3.0.8.pom" =
      _: "${istack_commons_runtime_3_0_8}/istack-commons-runtime-3.0.8.pom";
  };
  "jakarta.activation:jakarta.activation-api:1.2.1" = {
    "jakarta.activation-api-1.2.1.jar" =
      _: "${jakarta_activation_api_1_2_1}/jakarta.activation-api-1.2.1.jar";
    "jakarta.activation-api-1.2.1.pom" =
      _: "${jakarta_activation_api_1_2_1}/jakarta.activation-api-1.2.1.pom";
  };
  "jakarta.xml.bind:jakarta.xml.bind-api:2.3.2" = {
    "jakarta.xml.bind-api-2.3.2.jar" =
      _: "${jakarta_xml_bind_api_2_3_2}/jakarta.xml.bind-api-2.3.2.jar";
    "jakarta.xml.bind-api-2.3.2.pom" =
      _: "${jakarta_xml_bind_api_2_3_2}/jakarta.xml.bind-api-2.3.2.pom";
  };
  "jakarta.xml.bind:jakarta.xml.bind-api-parent:2.3.2" = {
    "jakarta.xml.bind-api-parent-2.3.2.pom" =
      _: "${jakarta_xml_bind_api_2_3_2}/jakarta.xml.bind-api-parent-2.3.2.pom";
  };
  "net.sf.jopt-simple:jopt-simple:4.9" = {
    "jopt-simple-4.9.jar" = _: "${jopt_simple_4_9}/jopt-simple-4.9.jar";
    "jopt-simple-4.9.pom" = _: "${jopt_simple_4_9}/jopt-simple-4.9.pom";
  };
  "org.jdom:jdom2:2.0.6" = {
    "jdom2-2.0.6.jar" = _: "${jdom2_2_0_6}/jdom2-2.0.6.jar";
    "jdom2-2.0.6.pom" = _: "${jdom2_2_0_6}/jdom2-2.0.6.pom";
  };
  "com.google.guava:guava:31.1-android" = {
    "guava-31.1-android.jar" = _: "${guava_31_1_android}/guava-31.1-android.jar";
    "guava-31.1-android.pom" = _: "${guava_31_1_android}/guava-31.1-android.pom";
  };
  "com.google.guava:guava-parent:31.1-android" = {
    "guava-parent-31.1-android.pom" = _: "${guava_31_1_android}/guava-parent-31.1-android.pom";
  };
  "com.google.guava:guava:33.3.1-jre" = {
    "guava-33.3.1-jre.jar" = _: "${guava_33_3_1_jre}/guava-33.3.1-jre.jar";
    "guava-33.3.1-jre.module" = _: "${guava_33_3_1_jre}/guava-33.3.1-jre.module";
    "guava-33.3.1-jre.pom" = _: "${guava_33_3_1_jre}/guava-33.3.1-jre.pom";
  };
  "com.google.guava:guava-parent:33.3.1-jre" = {
    "guava-parent-33.3.1-jre.pom" = _: "${guava_33_3_1_jre}/guava-parent-33.3.1-jre.pom";
  };
  "com.google.guava:failureaccess:1.0.1" = {
    "failureaccess-1.0.1.jar" = _: "${failureaccess_1_0_1}/failureaccess-1.0.1.jar";
    "failureaccess-1.0.1.pom" = _: "${failureaccess_1_0_1}/failureaccess-1.0.1.pom";
  };
  "com.google.guava:failureaccess:1.0.2" = {
    "failureaccess-1.0.2.jar" = _: "${failureaccess_1_0_2}/failureaccess-1.0.2.jar";
    "failureaccess-1.0.2.pom" = _: "${failureaccess_1_0_2}/failureaccess-1.0.2.pom";
  };
  "com.google.guava:listenablefuture:1.0" = {
    "listenablefuture-1.0.jar" = _: "${listenablefuture_1_0}/listenablefuture-1.0.jar";
    "listenablefuture-1.0.pom" = _: "${listenablefuture_1_0}/listenablefuture-1.0.pom";
  };
  "com.google.guava:listenablefuture:9999.0-empty-to-avoid-conflict-with-guava" = {
    "listenablefuture-9999.0-empty-to-avoid-conflict-with-guava.jar" =
      _:
      "${listenablefuture_9999_0_empty_to_avoid_conflict_with_guava}/listenablefuture-9999.0-empty-to-avoid-conflict-with-guava.jar";
    "listenablefuture-9999.0-empty-to-avoid-conflict-with-guava.pom" =
      _:
      "${listenablefuture_9999_0_empty_to_avoid_conflict_with_guava}/listenablefuture-9999.0-empty-to-avoid-conflict-with-guava.pom";
  };
  "com.google.flatbuffers:flatbuffers-java:1.12.0" = {
    "flatbuffers-java-1.12.0.jar" = _: "${flatbuffers_java_1_12_0}/flatbuffers-java-1.12.0.jar";
    "flatbuffers-java-1.12.0.pom" = _: "${flatbuffers_java_1_12_0}/flatbuffers-java-1.12.0.pom";
  };
  "com.squareup:javapoet:1.13.0" = {
    "javapoet-1.13.0.jar" = _: "${javapoet_1_13_0}/javapoet-1.13.0.jar";
    "javapoet-1.13.0.pom" = _: "${javapoet_1_13_0}/javapoet-1.13.0.pom";
  };
  "com.squareup:javapoet:1.10.0" = {
    "javapoet-1.10.0.jar" = _: "${javapoet_1_10_0}/javapoet-1.10.0.jar";
    "javapoet-1.10.0.pom" = _: "${javapoet_1_10_0}/javapoet-1.10.0.pom";
  };
  "com.googlecode.juniversalchardet:juniversalchardet:1.0.3" = {
    "juniversalchardet-1.0.3.jar" = _: "${juniversalchardet_1_0_3}/juniversalchardet-1.0.3.jar";
    "juniversalchardet-1.0.3.pom" = _: "${juniversalchardet_1_0_3}/juniversalchardet-1.0.3.pom";
  };
  "org.jspecify:jspecify:1.0.0" = {
    "jspecify-1.0.0.jar" = _: "${jspecify_1_0_0}/jspecify-1.0.0.jar";
    "jspecify-1.0.0.module" = _: "${jspecify_1_0_0}/jspecify-1.0.0.module";
    "jspecify-1.0.0.pom" = _: "${jspecify_1_0_0}/jspecify-1.0.0.pom";
  };
  "org.brotli:dec:0.1.2" = {
    "dec-0.1.2.jar" = _: "${brotli_dec_0_1_2}/dec-0.1.2.jar";
    "dec-0.1.2.pom" = _: "${brotli_dec_0_1_2}/dec-0.1.2.pom";
  };
  "org.brotli:parent:0.1.2" = {
    "parent-0.1.2.pom" = _: "${brotli_dec_0_1_2}/parent-0.1.2.pom";
  };
  "com.google.guava:guava-parent:26.0-android" = {
    "guava-parent-26.0-android.pom" = _: "${failureaccess_1_0_1}/guava-parent-26.0-android.pom";
  };
  "com.google.errorprone:error_prone_annotations:2.1.3" =
    mkMavenSourceJarOverride "error_prone_annotations" "2.1.3"
      error_prone_annotations_2_1_3;
  "com.google.errorprone:error_prone_annotations:2.27.0" = {
    "error_prone_annotations-2.27.0.jar" =
      _: "${error_prone_annotations_2_27_0}/error_prone_annotations-2.27.0.jar";
    "error_prone_annotations-2.27.0.pom" =
      _: "${error_prone_annotations_2_27_0}/error_prone_annotations-2.27.0.pom";
  };
  "com.google.errorprone:error_prone_annotations:2.28.0" = {
    "error_prone_annotations-2.28.0.jar" =
      _: "${error_prone_annotations_2_28_0}/error_prone_annotations-2.28.0.jar";
    "error_prone_annotations-2.28.0.pom" =
      _: "${error_prone_annotations_2_28_0}/error_prone_annotations-2.28.0.pom";
  };
  "com.google.errorprone:error_prone_parent:2.27.0" = {
    "error_prone_parent-2.27.0.pom" =
      _: "${error_prone_annotations_2_27_0}/error_prone_parent-2.27.0.pom";
  };
  "com.google.errorprone:error_prone_parent:2.28.0" = {
    "error_prone_parent-2.28.0.pom" =
      _: "${error_prone_annotations_2_28_0}/error_prone_parent-2.28.0.pom";
  };
  "com.google.errorprone:error_prone_annotations:2.26.1" =
    mkMavenSourceJarOverride "error_prone_annotations" "2.26.1"
      error_prone_annotations_2_26_1;
  "com.google.errorprone:error_prone_annotations:2.29.0" =
    mkMavenSourceJarOverride "error_prone_annotations" "2.29.0"
      error_prone_annotations_2_29_0;
  "com.google.errorprone:error_prone_annotations:2.31.0" =
    mkMavenSourceJarOverride "error_prone_annotations" "2.31.0"
      error_prone_annotations_2_31_0;
  "com.google.errorprone:error_prone_annotations:2.3.1" = {
    "error_prone_annotations-2.3.1.jar" =
      _: "${error_prone_annotations_2_3_1}/error_prone_annotations-2.3.1.jar";
    "error_prone_annotations-2.3.1.pom" =
      _: "${error_prone_annotations_2_3_1}/error_prone_annotations-2.3.1.pom";
  };
  "com.google.errorprone:error_prone_parent:2.3.1" = {
    "error_prone_parent-2.3.1.pom" = _: "${error_prone_annotations_2_3_1}/error_prone_parent-2.3.1.pom";
  };
  "com.google.errorprone:error_prone_annotations:2.3.2" = {
    "error_prone_annotations-2.3.2.jar" =
      _: "${error_prone_annotations_2_3_2}/error_prone_annotations-2.3.2.jar";
    "error_prone_annotations-2.3.2.pom" =
      _: "${error_prone_annotations_2_3_2}/error_prone_annotations-2.3.2.pom";
  };
  "com.google.errorprone:error_prone_parent:2.3.2" = {
    "error_prone_parent-2.3.2.pom" = _: "${error_prone_annotations_2_3_2}/error_prone_parent-2.3.2.pom";
  };
  "com.google.errorprone:error_prone_annotations:2.3.4" = {
    "error_prone_annotations-2.3.4.jar" =
      _: "${error_prone_annotations_2_3_4}/error_prone_annotations-2.3.4.jar";
    "error_prone_annotations-2.3.4.pom" =
      _: "${error_prone_annotations_2_3_4}/error_prone_annotations-2.3.4.pom";
  };
  "com.google.errorprone:error_prone_parent:2.3.4" = {
    "error_prone_parent-2.3.4.pom" = _: "${error_prone_annotations_2_3_4}/error_prone_parent-2.3.4.pom";
  };
  "com.google.errorprone:error_prone_annotations:2.5.1" = {
    "error_prone_annotations-2.5.1.jar" =
      _: "${error_prone_annotations_2_5_1}/error_prone_annotations-2.5.1.jar";
    "error_prone_annotations-2.5.1.pom" =
      _: "${error_prone_annotations_2_5_1}/error_prone_annotations-2.5.1.pom";
  };
  "com.google.errorprone:error_prone_parent:2.5.1" = {
    "error_prone_parent-2.5.1.pom" = _: "${error_prone_annotations_2_5_1}/error_prone_parent-2.5.1.pom";
  };
  "com.google.errorprone:error_prone_annotations:2.11.0" = {
    "error_prone_annotations-2.11.0.jar" =
      _: "${error_prone_annotations_2_11_0}/error_prone_annotations-2.11.0.jar";
    "error_prone_annotations-2.11.0.pom" =
      _: "${error_prone_annotations_2_11_0}/error_prone_annotations-2.11.0.pom";
  };
  "com.google.errorprone:error_prone_parent:2.11.0" = {
    "error_prone_parent-2.11.0.pom" =
      _: "${error_prone_annotations_2_11_0}/error_prone_parent-2.11.0.pom";
  };
  "com.google.errorprone:error_prone_annotations:2.15.0" = {
    "error_prone_annotations-2.15.0.jar" =
      _: "${error_prone_annotations_2_15_0}/error_prone_annotations-2.15.0.jar";
    "error_prone_annotations-2.15.0.pom" =
      _: "${error_prone_annotations_2_15_0}/error_prone_annotations-2.15.0.pom";
  };
  "com.google.errorprone:error_prone_parent:2.15.0" = {
    "error_prone_parent-2.15.0.pom" =
      _: "${error_prone_annotations_2_15_0}/error_prone_parent-2.15.0.pom";
  };
  "com.google.errorprone:error_prone_annotations:2.18.0" = {
    "error_prone_annotations-2.18.0.jar" =
      _: "${error_prone_annotations_2_18_0}/error_prone_annotations-2.18.0.jar";
    "error_prone_annotations-2.18.0.pom" =
      _: "${error_prone_annotations_2_18_0}/error_prone_annotations-2.18.0.pom";
  };
  "com.google.errorprone:error_prone_parent:2.18.0" = {
    "error_prone_parent-2.18.0.pom" =
      _: "${error_prone_annotations_2_18_0}/error_prone_parent-2.18.0.pom";
  };
  "com.google.errorprone:error_prone_annotations:2.23.0" = {
    "error_prone_annotations-2.23.0.jar" =
      _: "${error_prone_annotations_2_23_0}/error_prone_annotations-2.23.0.jar";
    "error_prone_annotations-2.23.0.pom" =
      _: "${error_prone_annotations_2_23_0}/error_prone_annotations-2.23.0.pom";
  };
  "com.google.errorprone:error_prone_parent:2.23.0" = {
    "error_prone_parent-2.23.0.pom" =
      _: "${error_prone_annotations_2_23_0}/error_prone_parent-2.23.0.pom";
  };
  "com.google.errorprone:error_prone_annotations:2.30.0" = {
    "error_prone_annotations-2.30.0.jar" =
      _: "${error_prone_annotations_2_30_0}/error_prone_annotations-2.30.0.jar";
    "error_prone_annotations-2.30.0.pom" =
      _: "${error_prone_annotations_2_30_0}/error_prone_annotations-2.30.0.pom";
  };
  "com.google.errorprone:error_prone_parent:2.30.0" = {
    "error_prone_parent-2.30.0.pom" =
      _: "${error_prone_annotations_2_30_0}/error_prone_parent-2.30.0.pom";
  };
  "com.google.errorprone:error_prone_annotations:2.36.0" = {
    "error_prone_annotations-2.36.0.jar" =
      _: "${error_prone_annotations_2_36_0}/error_prone_annotations-2.36.0.jar";
    "error_prone_annotations-2.36.0.pom" =
      _: "${error_prone_annotations_2_36_0}/error_prone_annotations-2.36.0.pom";
  };
  "com.google.errorprone:error_prone_parent:2.36.0" = {
    "error_prone_parent-2.36.0.pom" =
      _: "${error_prone_annotations_2_36_0}/error_prone_parent-2.36.0.pom";
  };
  "com.google.errorprone:error_prone_annotations:2.37.0" =
    mkMavenSourceJarOverride "error_prone_annotations" "2.37.0"
      error_prone_annotations_2_37_0;
  "com.google.errorprone:error_prone_annotations:2.38.0" =
    mkMavenSourceJarOverride "error_prone_annotations" "2.38.0"
      error_prone_annotations_2_38_0;
  "com.google.errorprone:error_prone_annotations:2.41.0" = {
    "error_prone_annotations-2.41.0.jar" =
      _: "${error_prone_annotations_2_41_0}/error_prone_annotations-2.41.0.jar";
    "error_prone_annotations-2.41.0.pom" =
      _: "${error_prone_annotations_2_41_0}/error_prone_annotations-2.41.0.pom";
  };
  "com.google.errorprone:error_prone_annotations:2.42.0" =
    mkMavenSourceJarOverride "error_prone_annotations" "2.42.0"
      error_prone_annotations_2_42_0;
  "com.google.errorprone:error_prone_parent:2.41.0" = {
    "error_prone_parent-2.41.0.pom" =
      _: "${error_prone_annotations_2_41_0}/error_prone_parent-2.41.0.pom";
  };
  "com.google.zxing:core:3.5.4" = {
    "core-3.5.4.jar" = _: "${zxing_core_3_5_4}/core-3.5.4.jar";
    "core-3.5.4.pom" = _: "${zxing_core_3_5_4}/core-3.5.4.pom";
  };
  "com.google.zxing:core:3.5.3" = {
    "core-3.5.3.jar" = _: "${zxing_core_3_5_3}/core-3.5.3.jar";
    "core-3.5.3.pom" = _: "${zxing_core_3_5_3}/core-3.5.3.pom";
  };
  "com.google.zxing:zxing-parent:3.5.3" = {
    "zxing-parent-3.5.3.pom" = _: "${zxing_core_3_5_3}/zxing-parent-3.5.3.pom";
  };
  "com.google.zxing:zxing-parent:3.5.4" = {
    "zxing-parent-3.5.4.pom" = _: "${zxing_core_3_5_4}/zxing-parent-3.5.4.pom";
  };
  "io.github.panpf.zoomimage:zoomimage-core-android:1.0.2" = {
    "zoomimage-core-android-1.0.2.aar" = _: "${zoomimage_1_0_2}/zoomimage-core-android-1.0.2.aar";
    "zoomimage-core-android-1.0.2.module" = _: "${zoomimage_1_0_2}/zoomimage-core-android-1.0.2.module";
    "zoomimage-core-android-1.0.2.pom" = _: "${zoomimage_1_0_2}/zoomimage-core-android-1.0.2.pom";
  };
  "io.github.panpf.zoomimage:zoomimage-core-glide:1.0.2" = {
    "zoomimage-core-glide-1.0.2.aar" = _: "${zoomimage_1_0_2}/zoomimage-core-glide-1.0.2.aar";
    "zoomimage-core-glide-1.0.2.module" = _: "${zoomimage_1_0_2}/zoomimage-core-glide-1.0.2.module";
    "zoomimage-core-glide-1.0.2.pom" = _: "${zoomimage_1_0_2}/zoomimage-core-glide-1.0.2.pom";
  };
  "io.github.panpf.zoomimage:zoomimage-view:1.0.2" = {
    "zoomimage-view-1.0.2.aar" = _: "${zoomimage_1_0_2}/zoomimage-view-1.0.2.aar";
    "zoomimage-view-1.0.2.module" = _: "${zoomimage_1_0_2}/zoomimage-view-1.0.2.module";
    "zoomimage-view-1.0.2.pom" = _: "${zoomimage_1_0_2}/zoomimage-view-1.0.2.pom";
  };
  "io.github.panpf.zoomimage:zoomimage-view-glide:1.0.2" = {
    "zoomimage-view-glide-1.0.2.aar" = _: "${zoomimage_1_0_2}/zoomimage-view-glide-1.0.2.aar";
    "zoomimage-view-glide-1.0.2.module" = _: "${zoomimage_1_0_2}/zoomimage-view-glide-1.0.2.module";
    "zoomimage-view-glide-1.0.2.pom" = _: "${zoomimage_1_0_2}/zoomimage-view-glide-1.0.2.pom";
  };
  "com.squareup:javawriter:2.5.0" = {
    "javawriter-2.5.0.jar" = _: "${javawriter_2_5_0}/javawriter-2.5.0.jar";
    "javawriter-2.5.0.pom" = _: "${javawriter_2_5_0}/javawriter-2.5.0.pom";
  };
  "io.github.java-diff-utils:java-diff-utils:4.16" = {
    "java-diff-utils-4.16.jar" = _: "${java_diff_utils_4_16}/java-diff-utils-4.16.jar";
    "java-diff-utils-4.16.pom" = _: "${java_diff_utils_4_16}/java-diff-utils-4.16.pom";
  };
  "io.github.java-diff-utils:java-diff-utils-parent:4.16" = {
    "java-diff-utils-parent-4.16.pom" = _: "${java_diff_utils_4_16}/java-diff-utils-parent-4.16.pom";
  };
  "com.googlecode.plist:dd-plist:1.21" = {
    "dd-plist-1.21.jar" = _: "${dd_plist_1_21}/dd-plist-1.21.jar";
    "dd-plist-1.21.pom" = _: "${dd_plist_1_21}/dd-plist-1.21.pom";
  };
  "com.googlecode.plist:dd-plist:1.27" = {
    "dd-plist-1.27.jar" = _: "${dd_plist_1_27}/dd-plist-1.27.jar";
    "dd-plist-1.27.pom" = _: "${dd_plist_1_27}/dd-plist-1.27.pom";
  };
  "javax.servlet:javax.servlet-api:3.1.0" = {
    "javax.servlet-api-3.1.0.jar" = _: "${javax_servlet_api_3_1_0}/javax.servlet-api-3.1.0.jar";
    "javax.servlet-api-3.1.0.pom" = _: "${javax_servlet_api_3_1_0}/javax.servlet-api-3.1.0.pom";
  };
  "com.michael-bull.kotlin-result:kotlin-result:2.1.0" = {
    "kotlin-result-2.1.0.module" = _: "${kotlin_result_2_1_0}/kotlin-result-2.1.0.module";
    "kotlin-result-2.1.0.pom" = _: "${kotlin_result_2_1_0}/kotlin-result-2.1.0.pom";
  };
  "com.michael-bull.kotlin-result:kotlin-result-jvm:2.1.0" = {
    "kotlin-result-jvm-2.1.0.jar" = _: "${kotlin_result_2_1_0}/kotlin-result-jvm-2.1.0.jar";
    "kotlin-result-jvm-2.1.0.module" = _: "${kotlin_result_2_1_0}/kotlin-result-jvm-2.1.0.module";
    "kotlin-result-jvm-2.1.0.pom" = _: "${kotlin_result_2_1_0}/kotlin-result-jvm-2.1.0.pom";
  };
  "com.michael-bull.kotlin-retry:kotlin-retry:2.0.2" = {
    "kotlin-retry-2.0.2.module" = _: "${kotlin_retry_2_0_2}/kotlin-retry-2.0.2.module";
    "kotlin-retry-2.0.2.pom" = _: "${kotlin_retry_2_0_2}/kotlin-retry-2.0.2.pom";
  };
  "com.michael-bull.kotlin-retry:kotlin-retry-jvm:2.0.2" = {
    "kotlin-retry-jvm-2.0.2.jar" = _: "${kotlin_retry_2_0_2}/kotlin-retry-jvm-2.0.2.jar";
    "kotlin-retry-jvm-2.0.2.module" = _: "${kotlin_retry_2_0_2}/kotlin-retry-jvm-2.0.2.module";
    "kotlin-retry-jvm-2.0.2.pom" = _: "${kotlin_retry_2_0_2}/kotlin-retry-jvm-2.0.2.pom";
  };
  "com.michael-bull.kotlin-retry:kotlin-retry-result:2.0.2" = {
    "kotlin-retry-result-2.0.2.module" = _: "${kotlin_retry_2_0_2}/kotlin-retry-result-2.0.2.module";
    "kotlin-retry-result-2.0.2.pom" = _: "${kotlin_retry_2_0_2}/kotlin-retry-result-2.0.2.pom";
  };
  "com.michael-bull.kotlin-retry:kotlin-retry-result-jvm:2.0.2" = {
    "kotlin-retry-result-jvm-2.0.2.jar" = _: "${kotlin_retry_2_0_2}/kotlin-retry-result-jvm-2.0.2.jar";
    "kotlin-retry-result-jvm-2.0.2.module" =
      _: "${kotlin_retry_2_0_2}/kotlin-retry-result-jvm-2.0.2.module";
    "kotlin-retry-result-jvm-2.0.2.pom" = _: "${kotlin_retry_2_0_2}/kotlin-retry-result-jvm-2.0.2.pom";
  };
  "org.jetbrains.kotlinx:kotlinx-io-core:0.8.2" = {
    "kotlinx-io-core-0.8.2.module" = _: "${kotlinx_io_0_8_2}/kotlinx-io-core-0.8.2.module";
    "kotlinx-io-core-0.8.2.pom" = _: "${kotlinx_io_0_8_2}/kotlinx-io-core-0.8.2.pom";
  };
  "org.jetbrains.kotlinx:kotlinx-io-core-jvm:0.8.2" = {
    "kotlinx-io-core-jvm-0.8.2.jar" = _: "${kotlinx_io_0_8_2}/kotlinx-io-core-jvm-0.8.2.jar";
    "kotlinx-io-core-jvm-0.8.2.module" = _: "${kotlinx_io_0_8_2}/kotlinx-io-core-jvm-0.8.2.module";
    "kotlinx-io-core-jvm-0.8.2.pom" = _: "${kotlinx_io_0_8_2}/kotlinx-io-core-jvm-0.8.2.pom";
  };
  "org.jetbrains.kotlinx:kotlinx-io-bytestring:0.8.2" = {
    "kotlinx-io-bytestring-0.8.2.module" = _: "${kotlinx_io_0_8_2}/kotlinx-io-bytestring-0.8.2.module";
    "kotlinx-io-bytestring-0.8.2.pom" = _: "${kotlinx_io_0_8_2}/kotlinx-io-bytestring-0.8.2.pom";
  };
  "org.jetbrains.kotlinx:kotlinx-io-bytestring-jvm:0.8.2" = {
    "kotlinx-io-bytestring-jvm-0.8.2.jar" =
      _: "${kotlinx_io_0_8_2}/kotlinx-io-bytestring-jvm-0.8.2.jar";
    "kotlinx-io-bytestring-jvm-0.8.2.module" =
      _: "${kotlinx_io_0_8_2}/kotlinx-io-bytestring-jvm-0.8.2.module";
    "kotlinx-io-bytestring-jvm-0.8.2.pom" =
      _: "${kotlinx_io_0_8_2}/kotlinx-io-bytestring-jvm-0.8.2.pom";
  };
  "javax.inject:javax.inject:1" = {
    "javax.inject-1.jar" = _: "${javax_inject_1}/javax.inject-1.jar";
    "javax.inject-1.pom" = _: "${javax_inject_1}/javax.inject-1.pom";
  };
  /*
    > Task :app:minifyReleaseWithR8 FAILED
    ERROR:/build/tmp.vu4FaAQiAv/caches/modules-2/files-2.1/com.google.j2objc/j2objc-annotations/1.1/4dbde2726acab552d9b73e0a5321196d497444fe/j2objc-annotations-1.1.jar: R8: java.lang.NullPointerException: Cannot invoke "String.length()" because "<parameter1>" is null
  */
  /*
    "com.google.j2objc:j2objc-annotations:1.1" =
      mkMavenSourceJarOverride "j2objc-annotations" "1.1"
        j2objc_annotations_1_1;
  */
  "com.google.j2objc:j2objc-annotations:1.3" =
    mkMavenSourceJarOverride "j2objc-annotations" "1.3"
      j2objc_annotations_1_3;
  "com.google.j2objc:j2objc-annotations:2.8" = {
    "j2objc-annotations-2.8.jar" = _: "${j2objc_annotations_2_8}/j2objc-annotations-2.8.jar";
    "j2objc-annotations-2.8.pom" = _: "${j2objc_annotations_2_8}/j2objc-annotations-2.8.pom";
  };
  "com.google.j2objc:j2objc-annotations:3.0.0" = {
    "j2objc-annotations-3.0.0.jar" = _: "${j2objc_annotations_3_0_0}/j2objc-annotations-3.0.0.jar";
    "j2objc-annotations-3.0.0.pom" = _: "${j2objc_annotations_3_0_0}/j2objc-annotations-3.0.0.pom";
  };
  "com.google.j2objc:j2objc-annotations:3.1" = {
    "j2objc-annotations-3.1.jar" = _: "${j2objc_annotations_3_1}/j2objc-annotations-3.1.jar";
    "j2objc-annotations-3.1.pom" = _: "${j2objc_annotations_3_1}/j2objc-annotations-3.1.pom";
  };
  "org.tukaani:xz:1.6" = {
    "xz-1.6.jar" = _: "${xz_java_1_6}/xz-1.6.jar";
    "xz-1.6.pom" = _: "${xz_java_1_6}/xz-1.6.pom";
  };
  "org.tukaani:xz:1.9" = {
    "xz-1.9.jar" = _: "${xz_java_1_9}/xz-1.9.jar";
    "xz-1.9.pom" = _: "${xz_java_1_9}/xz-1.9.pom";
  };
  "org.slf4j:slf4j-api:2.0.17" = {
    "slf4j-api-2.0.17.jar" = _: "${slf4j_api_2_0_17}/slf4j-api-2.0.17.jar";
    "slf4j-api-2.0.17.pom" = _: "${slf4j_api_2_0_17}/slf4j-api-2.0.17.pom";
  };
  "org.slf4j:slf4j-api:1.7.2" = {
    "slf4j-api-1.7.2.jar" = _: "${slf4j_1_7_2}/slf4j-api-1.7.2.jar";
    "slf4j-api-1.7.2.pom" = _: "${slf4j_1_7_2}/slf4j-api-1.7.2.pom";
  };
  "org.slf4j:slf4j-simple:1.7.10" = {
    "slf4j-simple-1.7.10.jar" = _: "${slf4j_1_7_10}/slf4j-simple-1.7.10.jar";
    "slf4j-simple-1.7.10.pom" = _: "${slf4j_1_7_10}/slf4j-simple-1.7.10.pom";
  };
  "org.slf4j:slf4j-parent:1.7.10" = {
    "slf4j-parent-1.7.10.pom" = _: "${slf4j_1_7_10}/slf4j-parent-1.7.10.pom";
  };
  "org.slf4j:slf4j-api:1.7.30" = {
    "slf4j-api-1.7.30.jar" = _: "${slf4j_api_1_7_30}/slf4j-api-1.7.30.jar";
    "slf4j-api-1.7.30.pom" = _: "${slf4j_api_1_7_30}/slf4j-api-1.7.30.pom";
  };
  "org.slf4j:slf4j-parent:1.7.30" = {
    "slf4j-parent-1.7.30.pom" = _: "${slf4j_api_1_7_30}/slf4j-parent-1.7.30.pom";
  };
  "org.slf4j:slf4j-api:1.7.36" = {
    "slf4j-api-1.7.36.jar" = _: "${slf4j_api_1_7_36}/slf4j-api-1.7.36.jar";
    "slf4j-api-1.7.36.pom" = _: "${slf4j_api_1_7_36}/slf4j-api-1.7.36.pom";
  };
  "org.slf4j:slf4j-parent:1.7.36" = {
    "slf4j-parent-1.7.36.pom" = _: "${slf4j_api_1_7_36}/slf4j-parent-1.7.36.pom";
  };
  "org.slf4j:slf4j-bom:2.0.17" = {
    "slf4j-bom-2.0.17.pom" = _: "${slf4j_api_2_0_17}/slf4j-bom-2.0.17.pom";
  };
  "org.slf4j:slf4j-parent:2.0.17" = {
    "slf4j-parent-2.0.17.pom" = _: "${slf4j_api_2_0_17}/slf4j-parent-2.0.17.pom";
  };
  "org.checkerframework:checker-qual:3.33.0" = {
    "checker-qual-3.33.0.jar" = _: "${checker_qual_3_33_0}/checker-qual-3.33.0.jar";
    "checker-qual-3.33.0.pom" = _: "${checker_qual_3_33_0}/checker-qual-3.33.0.pom";
  };
  "org.checkerframework:checker-qual:3.37.0" =
    mkMavenSourceJarOverride "checker-qual" "3.37.0"
      checker_qual_3_37_0;
  "org.checkerframework:checker-qual:3.41.0" =
    mkMavenSourceJarOverride "checker-qual" "3.41.0"
      checker_qual_3_41_0;
  "org.checkerframework:checker-qual:3.42.0" =
    mkMavenSourceJarOverride "checker-qual" "3.42.0"
      checker_qual_3_42_0;
  "org.checkerframework:checker-qual:3.43.0" = {
    "checker-qual-3.43.0.jar" = _: "${checker_qual_3_43_0}/checker-qual-3.43.0.jar";
    "checker-qual-3.43.0.pom" = _: "${checker_qual_3_43_0}/checker-qual-3.43.0.pom";
  };
  "org.checkerframework:checker-qual:3.49.2" =
    mkMavenSourceJarOverride "checker-qual" "3.49.2"
      checker_qual_3_49_2;
  "org.checkerframework:checker-qual:3.49.3" =
    mkMavenSourceJarOverride "checker-qual" "3.49.3"
      checker_qual_3_49_3;
  "org.apache.commons:commons-parent:34" = {
    "commons-parent-34.pom" = _: "${commons_parent_34}/commons-parent-34.pom";
  };
  "org.apache.commons:commons-parent:69" = {
    "commons-parent-69.pom" = _: "${commons_parent_69}/commons-parent-69.pom";
  };
  "org.apache.commons:commons-parent:71" = {
    "commons-parent-71.pom" = _: "${commons_parent_71}/commons-parent-71.pom";
  };
  "org.apache.commons:commons-parent:72" = {
    "commons-parent-72.pom" = _: "${commons_parent_72}/commons-parent-72.pom";
  };
  "org.apache:apache:21" = {
    "apache-21.pom" = _: "${apache_21}/apache-21.pom";
  };
  "org.apache:apache:31" = {
    "apache-31.pom" = _: "${apache_31}/apache-31.pom";
  };
  "org.apache:apache:32" = {
    "apache-32.pom" = _: "${apache_32}/apache-32.pom";
  };
  "org.apache:apache:33" = {
    "apache-33.pom" = _: "${apache_33}/apache-33.pom";
  };
  "org.apache.httpcomponents:httpcomponents-client:4.5.14" = {
    "httpcomponents-client-4.5.14.pom" =
      _: "${httpcomponents_client_4_5_14}/httpcomponents-client-4.5.14.pom";
  };
  "org.apache.httpcomponents:httpcomponents-core:4.4.16" = {
    "httpcomponents-core-4.4.16.pom" =
      _: "${httpcomponents_core_4_4_16}/httpcomponents-core-4.4.16.pom";
  };
  "org.sonatype.oss:oss-parent:7" = {
    "oss-parent-7.pom" = _: "${oss_parent_7}/oss-parent-7.pom";
  };
}
