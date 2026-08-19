{
  callPackage,
  stdenv,
  openjdk17,
}:
if stdenv.hostPlatform.isDarwin then openjdk17 else (callPackage ../../op/openjdk-common { }).jdk17_bootstrapped
