{
  callPackage,
  stdenv,
  openjdk25_headless,
}:
if stdenv.isDarwin then
  openjdk25_headless
else
  (callPackage ../../op/openjdk-common { }).jdk25_headless_bootstrapped
