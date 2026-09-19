set -e
export JAVA_HOME=$(nix-build '<nixpkgs>' -A jdk17_headless)/lib/openjdk
export ANDROID_HOME=/home/dev/.gemini/antigravity-cli/brain/8bb262e5-4e99-42fc-b006-908662d65dd1/scratch/android-sdk
mkdir -p $ANDROID_HOME/licenses
echo -e "\n8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > $ANDROID_HOME/licenses/android-sdk-license
echo -e "\n84831b9409646a918e30573bab4c9c91346d8abd\n504667f4c0de7af1a06de9f4b1727b84351f2910" > $ANDROID_HOME/licenses/android-sdk-preview-license

cd /home/dev/.gemini/antigravity-cli/brain/8bb262e5-4e99-42fc-b006-908662d65dd1/scratch/forkgram_src
echo "sdk.dir=$ANDROID_HOME" > local.properties
nix run github:tadfisher/gradle2nix/v2
cp gradle.lock /home/dev/Documents/repo/app/apks/forkgram/gradle.lock

cd /home/dev/.gemini/antigravity-cli/brain/8bb262e5-4e99-42fc-b006-908662d65dd1/scratch/forkgram_classic_src
echo "sdk.dir=$ANDROID_HOME" > local.properties
nix run github:tadfisher/gradle2nix/v2
cp gradle.lock /home/dev/Documents/repo/app/apks/forkgram-classic/gradle.lock
