{
  callPackage,
  stdenv,
  openjdk21_headless,
}:
if stdenv.hostPlatform.isDarwin then
  openjdk21_headless
else
  (callPackage ../../op/openjdk-common { }).jdk21_headless_bootstrapped
