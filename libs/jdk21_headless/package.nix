{
  callPackage,
  stdenv,
  openjdk21_headless,
}:
if stdenv.isDarwin then
  openjdk21_headless
else
  (callPackage ../openjdk-common { }).jdk21_headless_bootstrapped
