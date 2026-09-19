# For forkgram
cd /home/dev/.gemini/antigravity-cli/brain/8bb262e5-4e99-42fc-b006-908662d65dd1/scratch
rm -rf TelegramAndroid
git clone --depth 1 -b v12.10.4.0 https://github.com/forkgram/TelegramAndroid.git forkgram_src
cd forkgram_src
nix run github:tadfisher/gradle2nix/v2
cp gradle.lock /home/dev/Documents/repo/app/apks/forkgram/gradle.lock

# For forkgram-classic
cd /home/dev/.gemini/antigravity-cli/brain/8bb262e5-4e99-42fc-b006-908662d65dd1/scratch
git clone --depth 1 -b v12.10.7.0 https://github.com/forkgram/TelegramAndroid.git forkgram_classic_src
cd forkgram_classic_src
nix run github:tadfisher/gradle2nix/v2
cp gradle.lock /home/dev/Documents/repo/app/apks/forkgram-classic/gradle.lock
