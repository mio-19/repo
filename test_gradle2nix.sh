set -e
export JAVA_HOME=$(nix-build '<nixpkgs>' -A jdk17_headless)/lib/openjdk
cd /home/dev/.gemini/antigravity-cli/brain/8bb262e5-4e99-42fc-b006-908662d65dd1/scratch/forkgram_src
nix run github:tadfisher/gradle2nix/v2
