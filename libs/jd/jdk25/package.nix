{
  callPackage,
  stdenv,
  openjdk25,
}:
if stdenv.isDarwin then openjdk25 else (callPackage ../../op/openjdk-common { }).jdk25_bootstrapped
