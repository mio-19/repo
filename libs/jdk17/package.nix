{
  callPackage,
  stdenv,
  openjdk17,
}:
if stdenv.isDarwin then openjdk17 else (callPackage ../openjdk-common { }).jdk17_bootstrapped
