{
  callPackage,
  stdenv,
  openjdk11,
}:
if stdenv.hostPlatform.isDarwin then openjdk11 else (callPackage ../../op/openjdk-common { }).jdk11_bootstrapped
