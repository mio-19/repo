{
  brotli_dec_0_1_2,
  buildMavenRepository,
  commons_compress_common,
  xz_java_1_9,
}:

let
  # Optional compile-time deps (JNI / old ASM); needed to compile optional
  # compressor and pack200 support that ships in the upstream sources.
  optionalRepo = buildMavenRepository {
    pathMap = baseNameOf;
    dependencies = {
      "com/github/luben/zstd-jni/1.5.0-2/zstd-jni-1.5.0-2.jar" = {
        layout = "com/github/luben/zstd-jni/1.5.0-2/zstd-jni-1.5.0-2.jar";
        url = "https://repo.maven.apache.org/maven2/com/github/luben/zstd-jni/1.5.0-2/zstd-jni-1.5.0-2.jar";
        hash = "sha256-tmpwKXEZdlZskh7yVcVxkvu9xCqWwRrT2HnmrWABvhI=";
      };
      "asm/asm/3.2/asm-3.2.jar" = {
        layout = "asm/asm/3.2/asm-3.2.jar";
        url = "https://repo.maven.apache.org/maven2/asm/asm/3.2/asm-3.2.jar";
        hash = "sha256-GsO24Y29cFPNvvc3S4QBrX/2TOuABgzKzk3DXm64nUk=";
      };
    };
  };
in
commons_compress_common {
  version = "1.21";
  tag = "rel/1.21";
  hash = "sha256-sGHyM2dJ03knnU6DxH7P4QgJ57OAcTrlDWZGzBBG9QM=";
  classpathJars = [
    "${brotli_dec_0_1_2}/dec-${brotli_dec_0_1_2.version}.jar"
    "${xz_java_1_9}/xz-${xz_java_1_9.version}.jar"
    "${optionalRepo}/zstd-jni-1.5.0-2.jar"
    "${optionalRepo}/asm-3.2.jar"
  ];
}
