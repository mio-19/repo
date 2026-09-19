{
  asm_9_9,
  brotli_dec_0_1_2,
  buildMavenRepository,
  commons_codec_1_17_1,
  commons_compress_common,
  commons_io_2_16_1,
  commons_lang3_3_16_0,
  xz_java_1_9,
}:

let
  # Optional compile-time JNI dep for zstd compressor support.
  optionalRepo = buildMavenRepository {
    pathMap = baseNameOf;
    dependencies = {
      "com/github/luben/zstd-jni/1.5.6-4/zstd-jni-1.5.6-4.jar" = {
        layout = "com/github/luben/zstd-jni/1.5.6-4/zstd-jni-1.5.6-4.jar";
        url = "https://repo.maven.apache.org/maven2/com/github/luben/zstd-jni/1.5.6-4/zstd-jni-1.5.6-4.jar";
        hash = "sha256-eTyoc0qhVofn5kVk6ri2rp7icg6uJ6pmMHRoIUSxw4Y=";
      };
    };
  };
in
commons_compress_common {
  version = "1.27.1";
  tag = "rel/commons-compress-1.27.1";
  hash = "sha256-BiFnXh/oyBiarxot7WNKV9UZN3H9ytZCYF6Zzo7ZUQw=";
  classpathJars = [
    "${brotli_dec_0_1_2}/dec-${brotli_dec_0_1_2.version}.jar"
    "${xz_java_1_9}/xz-${xz_java_1_9.version}.jar"
    "${commons_codec_1_17_1}/commons-codec-${commons_codec_1_17_1.version}.jar"
    "${commons_io_2_16_1}/commons-io-${commons_io_2_16_1.version}.jar"
    "${commons_lang3_3_16_0}/commons-lang3-${commons_lang3_3_16_0.version}.jar"
    "${asm_9_9}/asm-${asm_9_9.version}.jar"
    "${optionalRepo}/zstd-jni-1.5.6-4.jar"
  ];
}
