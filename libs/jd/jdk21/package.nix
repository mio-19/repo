{
  callPackage,
  stdenv,
  openjdk21,
}:
if stdenv.isDarwin then openjdk21 else (callPackage ../../op/openjdk-common { }).jdk21_bootstrapped
