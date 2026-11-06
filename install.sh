#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: ./install.sh [--dry-run] [--approve-all] [--target DIR] [--only PATH]

Copy this repository's contents into your home directory, merging directories
and overwriting matching files. Destination-only files are never deleted.

  --dry-run     Show planned changes without writing anything or prompting.
  --approve-all Approve overwrites without prompting.
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
is_dry_run=0
approve_all=0

while (($#)); do
    case "$1" in
        --dry-run)
            dry_run=(--dry-run)
            is_dry_run=1
            shift
            ;;
        --approve-all)
            approve_all=1
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

# Resolve both paths so invocation from another directory works and the target
# remains a local absolute path, even when a directory name contains a colon.
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
target_dir=$(cd -- "$target_dir" && pwd -P)

case "$target_dir/" in
    "$repo_dir/"*) die 'The target cannot be the repository or a directory inside it.' ;;
esac

source_path="$repo_dir/"
display_source=$source_path
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
    # openrsync does not reliably handle an absolute source with /./ and
    # --relative. Start from the repository and use a local relative path.
    source_path="./$only_path"
    display_source="$repo_dir/$only_path"
    relative=(--relative)
fi

printf 'Source: %s\nTarget: %s\n' "$display_source" "$target_dir"
cd -- "$repo_dir"

# Review existing entries before rsync changes anything. A parent type conflict
# is reviewed on its own; do not follow destination symlinks while inspecting.
needs_approval=0
review_entry() {
    local path=$1 dest parent component rest diff_status source_link dest_link source_exec dest_exec
    path=${path#./}
    [[ $path != . ]] || return 0
    case "/$path/" in
        */.git/*|*/.DS_Store/*) return 0 ;;
    esac
    case "$path" in
        README.md|.gitignore|install.sh) return 0 ;;
    esac
    dest="$target_dir/$path"
    # Refuse entries that would write into the repository, or replace one of
    # its ancestor directories. The target itself may legitimately be $HOME.
    case "$dest/" in
        "$repo_dir/"*) die "Installation would write into the repository: $dest" ;;
    esac
    case "$repo_dir/" in
        "$dest/"*)
            [[ -d $path && ! -L $path ]] || die "Installation would replace a repository ancestor: $dest"
            ;;
    esac
    parent=$target_dir
    rest=$path
    while [[ $rest == */* ]]; do
        component=${rest%%/*}
        parent="$parent/$component"
        [[ ! -L $parent && -d $parent ]] || return 0
        rest=${rest#*/}
    done
    [[ -e $dest || -L $dest ]] || return 0

    if [[ -d $path && ! -L $path && -d $dest && ! -L $dest ]]; then
        return
    elif [[ -f $path && ! -L $path && -f $dest && ! -L $dest ]]; then
        source_exec=$(find "$path" -prune \( -perm -100 -o -perm -010 -o -perm -001 \) -exec printf x \;)
        dest_exec=$(find "$dest" -prune \( -perm -100 -o -perm -010 -o -perm -001 \) -exec printf x \;)
        if [[ $source_exec != "$dest_exec" ]]; then
            printf '\nExecutability will change: %s\n' "$dest"
        fi
        if cmp -s -- "$dest" "$path"; then return; fi
        printf '\nExisting file to overwrite: %s\n' "$dest"
        diff_status=0
        diff -u -- "$dest" "$path" > "$diff_file" || diff_status=$?
        cat "$diff_file"
        if ((diff_status != 1)) || ! grep -q '^@@ ' "$diff_file" ||
            awk 'NR > 2 && /^-/ { found=1 } END { exit !found }' "$diff_file"; then
            needs_approval=1
        fi
    elif [[ -L $path && -L $dest ]]; then
        # A sentinel preserves trailing newlines stripped by command substitution.
        source_link=$(readlink -n "$path"; printf '.')
        dest_link=$(readlink -n "$dest"; printf '.')
        if [[ $source_link == "$dest_link" ]]; then return; fi
        printf '\nExisting symlink to replace: %s\n' "$dest"
        printf '  Destination symlink -> %s\n' "${dest_link%?}"
        printf '  Source symlink -> %s\n' "${source_link%?}"
        needs_approval=1
    else
        printf '\nExisting entry to replace: %s\n' "$dest"
        if [[ -L $dest ]]; then printf '  Destination symlink -> %s\n' "$(readlink "$dest")"; fi
        if [[ -L $path ]]; then printf '  Source symlink -> %s\n' "$(readlink "$path")"; fi
        printf '  Entry type or symlink target differs.\n'
        needs_approval=1
    fi
}

temp_dir=${TMPDIR:-/tmp}
[[ -d $temp_dir ]] || die 'The temporary directory does not exist.'
temp_dir=$(cd -- "$temp_dir" && pwd -P)
case "$temp_dir/" in
    "$repo_dir/"*)
        temp_dir=$(cd -- "${TMP:-/tmp}" && pwd -P) || die 'Cannot access a safe temporary directory.'
        case "$temp_dir/" in
            "$repo_dir/"*)
                temp_dir=$(cd -- /tmp && pwd -P) || die 'Cannot access a safe temporary directory.'
                case "$temp_dir/" in
                    "$repo_dir/"*) die 'Cannot create temporary files outside the repository.' ;;
                esac
                ;;
        esac
        ;;
esac
diff_file=$(mktemp "$temp_dir/dotfiles-diff.XXXXXXXX") || die 'Cannot create temporary diff file.'
trap 'rm -f -- "$diff_file" "${entries_file:-}"' EXIT
entries_file=$(mktemp "$temp_dir/dotfiles-entries.XXXXXXXX") || die 'Cannot create temporary file list.'
if [[ -n $only_path ]]; then
    # --relative also transfers parent directories, which can replace existing
    # non-directories at the destination before the selected entry is copied.
    remaining=$only_path
    parent_path=
    while [[ $remaining == */* ]]; do
        component=${remaining%%/*}
        parent_path="${parent_path:+$parent_path/}$component"
        review_entry "$parent_path"
        remaining=${remaining#*/}
    done
    review_root="./$only_path"
else
    review_root=.
fi
find "$review_root" \( -name .git -o -name .DS_Store \) -prune -o -print0 > "$entries_file" || die 'Cannot enumerate source files for review.'
while IFS= read -r -d '' entry; do
    review_entry "$entry"
done < "$entries_file"

if ((needs_approval && !approve_all && !is_dry_run)); then
    printf '\nChanges include modifications, removals, or entry replacements. Approve installation? [y/N] '
    IFS= read -r answer || answer=
    case "$answer" in
        y|Y|yes|YES) ;;
        *) die 'Installation not approved; no changes were made.' ;;
    esac
fi

# Compare contents rather than only timestamps/sizes. Preserve file timestamps
# and executability without copying ownership or changing existing directory
# permissions/timestamps. Do not add --delete or --force: home may contain data
# that is absent from this repository. Guard empty array expansions for Bash 3.2
# (the macOS default), which otherwise treats them as unset under nounset.
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
    ${dry_run[@]+"${dry_run[@]}"} \
    ${relative[@]+"${relative[@]}"} \
    -- "$source_path" "$target_dir/"
