{
  callPackage,
  stdenv,
  openjdk21,
}:
if stdenv.isDarwin then openjdk21 else (callPackage ../openjdk-common { }).jdk21_bootstrapped
