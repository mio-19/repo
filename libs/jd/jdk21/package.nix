{
  callPackage,
  stdenv,
  openjdk21,
}:
if stdenv.hostPlatform.isDarwin then openjdk21 else (callPackage ../../op/openjdk-common { }).jdk21_bootstrapped
