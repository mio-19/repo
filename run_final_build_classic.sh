while pgrep -f "update_classic_lock.sh" > /dev/null; do
  sleep 5
done
nix build .#apk_forkgram-classic
