{
  callPackage,
  stdenv,
  openjdk25,
}:
if stdenv.hostPlatform.isDarwin then openjdk25 else (callPackage ../../op/openjdk-common { }).jdk25_bootstrapped
