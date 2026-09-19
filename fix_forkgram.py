with open("/home/dev/Documents/repo/app/apks/forkgram/package.nix", "r") as f:
    lines = f.readlines()

new_lines = []
skip = False
for i, line in enumerate(lines):
    if line.strip().startswith('target_include_directories(cpufeatures PUBLIC'):
        skip = True
    if skip:
        if line.strip() == "endif()'":
            skip = False
            new_lines.append("          --replace-quiet 'include(AndroidNdkModules)' \"\" \\\n")
            new_lines.append("          --replace-quiet 'android_ndk_import_module_cpufeatures()' \"\"\n")
    else:
        new_lines.append(line)

with open("/home/dev/Documents/repo/app/apks/forkgram/package.nix", "w") as f:
    f.writelines(new_lines)
