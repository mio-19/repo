{
  callPackage,
  stdenv,
  openjdk11_headless,
}:
if stdenv.hostPlatform.isDarwin then
  openjdk11_headless
else
  (callPackage ../../op/openjdk-common { }).jdk11_headless_bootstrapped
