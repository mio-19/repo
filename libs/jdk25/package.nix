{
  callPackage,
  stdenv,
  openjdk25,
}:
if stdenv.isDarwin then openjdk25 else (callPackage ../openjdk-common { }).jdk25_bootstrapped
