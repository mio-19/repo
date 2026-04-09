{
  jdk11_headless,
  jdk21_headless,
  gradle-packages,
  gradle-from-source,
}:
(gradle-packages.mkGradle {
  version = "8.14";
  hash = "sha256-Ya0xDTx9Pl2hMbdrvyK1pMB4bp2JLa6MFljUtITePKo=";
  defaultJava = jdk21_headless;
}).wrapped
