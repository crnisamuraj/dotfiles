#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: ./install.sh [--dry-run] [--target DIR] [--only PATH]

Copy this repository's contents into your home directory, merging directories
and overwriting matching files. Destination-only files are never deleted.

  --dry-run     Show planned changes without writing anything.
  --target DIR  Use an existing directory instead of $HOME.
  --only PATH   Install only this repository-relative file or directory.
  -h, --help    Show this help.

Excluded: .git, .DS_Store, and the root README.md, .gitignore, and install.sh.
Requires Bash and rsync. No software is installed and no services are restarted.
EOF
}

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

target_dir=${HOME:-}
only_path=
dry_run=()

while (($#)); do
    case "$1" in
        --dry-run)
            dry_run=(--dry-run)
            shift
            ;;
        --target)
            (($# >= 2)) && [[ -n $2 ]] || die '--target requires a directory.'
            target_dir=$2
            shift 2
            ;;
        --only)
            (($# >= 2)) && [[ -n $2 ]] || die '--only requires a repository-relative path.'
            [[ -z $only_path ]] || die '--only can only be specified once.'
            only_path=$2
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Unknown argument: $1 (see --help)."
            ;;
    esac
done

command -v rsync >/dev/null 2>&1 || die 'rsync is required but was not found.'
[[ -n $target_dir && -d $target_dir ]] || die 'The target must be an existing directory.'

# Resolve both paths so invocation from another directory works and rsync uses
# local absolute paths, even when a directory name contains a colon.
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
target_dir=$(cd -- "$target_dir" && pwd -P)

case "$target_dir/" in
    "$repo_dir/"*) die 'The target cannot be the repository or a directory inside it.' ;;
esac

source_path="$repo_dir/"
relative=()
if [[ -n $only_path ]]; then
    [[ $only_path != /* ]] || die '--only must be a repository-relative path.'
    while [[ $only_path == ./* ]]; do only_path=${only_path#./}; done
    while [[ $only_path == */ ]]; do only_path=${only_path%/}; done
    [[ -n $only_path && $only_path != . ]] || die '--only requires a file or directory within the repository.'

    # Reject traversal and excluded components, and never traverse symlinks.
    remaining=$only_path
    current=$repo_dir
    first=1
    while :; do
        component=${remaining%%/*}
        [[ -n $component && $component != . && $component != .. ]] || die 'Invalid --only path.'
        case "$component" in
            .git|.DS_Store) die "Excluded path: $only_path" ;;
        esac
        if ((first)); then
            case "$component" in
                README.md|.gitignore|install.sh) die "Excluded path: $only_path" ;;
            esac
        fi
        current="$current/$component"
        if [[ $remaining != */* ]]; then break; fi
        [[ -d $current && ! -L $current ]] || die "Not a directory within the repository: $current"
        remaining=${remaining#*/}
        first=0
    done
    [[ -e $current || -L $current ]] || die "Path not found: $only_path"
    source_path="$repo_dir/./$only_path"
    relative=(--relative)
fi

printf 'Source: %s\nTarget: %s\n' "$source_path" "$target_dir"

# Compare contents rather than only timestamps/sizes. Preserve file timestamps
# and executability without copying ownership or changing existing directory
# permissions/timestamps. Do not add --delete or --force: home may contain data
# that is absent from this repository.
rsync \
    --recursive \
    --links \
    --times \
    --executability \
    --omit-dir-times \
    --checksum \
    --itemize-changes \
    --exclude='.git' \
    --exclude='.DS_Store' \
    --exclude='/README.md' \
    --exclude='/.gitignore' \
    --exclude='/install.sh' \
    "${dry_run[@]}" \
    "${relative[@]}" \
    -- "$source_path" "$target_dir/"
