
clone_git_repo() { (
    repo="$1"
    mkdir -p "${repo%/*}"
    if [ -d "${repo}" ]; then return 0; fi
    cp -a "$GIT_DEPS/${project}" "$repo"
    chmod -R u+w "$repo"
); }

checkout_git_repo() { (
    tree="$1"
    repo="$2"
    rm -rf "$tree"
    cp -a "$repo" "$tree"
    chmod -R u+w "$tree"
); }
