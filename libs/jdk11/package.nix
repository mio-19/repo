{
  callPackage,
  stdenv,
  openjdk11,
}:
if stdenv.isDarwin then openjdk11 else (callPackage ../openjdk-common { }).jdk11_bootstrapped
