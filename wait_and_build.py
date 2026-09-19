import time
import subprocess

def is_running():
    result = subprocess.run(['pgrep', '-f', 'update_classic_lock.sh'], capture_output=True)
    return result.returncode == 0

while is_running():
    time.sleep(5)

print("Running build...")
subprocess.run(["nix", "build", ".#apk_forkgram-classic"])
