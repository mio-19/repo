{
  callPackage,
  stdenv,
  openjdk17_headless,
}:
if stdenv.hostPlatform.isDarwin then
  openjdk17_headless
else
  (callPackage ../../op/openjdk-common { }).jdk17_headless_bootstrapped
