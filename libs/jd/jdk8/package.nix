{
  callPackage,
  stdenv,
  openjdk8,
}:
if stdenv.isDarwin then openjdk8 else (callPackage ../../op/openjdk-common { }).jdk8_bootstrapped
