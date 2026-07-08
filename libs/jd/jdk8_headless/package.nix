{
  callPackage,
  stdenv,
  openjdk8_headless,
}:
if stdenv.isDarwin then
  openjdk8_headless
else
  (callPackage ../../op/openjdk-common { }).jdk8_headless_bootstrapped
