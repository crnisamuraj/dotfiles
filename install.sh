#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: ./install.sh [--dry-run] [--target DIR]

Copy this repository's contents into your home directory, merging directories
and overwriting matching files. Destination-only files are never deleted.

  --dry-run     Show planned changes without writing anything.
  --target DIR  Use an existing directory instead of $HOME.
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

printf 'Source: %s\nTarget: %s\n' "$repo_dir" "$target_dir"

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
    -- "$repo_dir/" "$target_dir/"
