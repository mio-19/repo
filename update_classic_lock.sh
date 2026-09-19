set -e
export JAVA_HOME=$(nix-build '<nixpkgs>' -A jdk17_headless)/lib/openjdk
export ANDROID_HOME=/home/dev/.gemini/antigravity-cli/brain/8bb262e5-4e99-42fc-b006-908662d65dd1/scratch/android-sdk

cd /home/dev/.gemini/antigravity-cli/brain/8bb262e5-4e99-42fc-b006-908662d65dd1/scratch
rm -rf forkgram_classic_src
git clone --depth 1 -b 12.10.7.0 https://github.com/forkgram/forkgram-classic.git forkgram_classic_src
cd forkgram_classic_src
git submodule update --init --recursive
echo "sdk.dir=$ANDROID_HOME" > local.properties
nix run github:tadfisher/gradle2nix/v2
cp gradle.lock /home/dev/Documents/repo/app/apks/forkgram-classic/gradle.lock
