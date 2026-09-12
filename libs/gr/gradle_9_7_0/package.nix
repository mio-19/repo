{
  jdk21_headless,
  gradle-packages,
}:
# Binary bootstrap for building gradle_9_7_1 from source (upstream wrapper).
# 9.6.1 cannot configure the 9.7.1 tree (Kotlin 2.3.21 vs 2.4.0).
(gradle-packages.mkGradle {
  version = "9.7.0";
  hash = "sha256-hPu6Rcf0xkq8d0YOHAD1Qen5YOPH7SU48e3hnqzYc64=";
  defaultJava = jdk21_headless;
}).wrapped
