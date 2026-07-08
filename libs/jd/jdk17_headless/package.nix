{
  callPackage,
  stdenv,
  openjdk17_headless,
}:
if stdenv.isDarwin then
  openjdk17_headless
else
  (callPackage ../../op/openjdk-common { }).jdk17_headless_bootstrapped
