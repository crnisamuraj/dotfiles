# dotfiles

The repository root maps to your home directory: `.codex/AGENTS.md` installs
as `~/.codex/AGENTS.md`, for example.

Requires Bash and `rsync`. Preview changes, then install:

```sh
./install.sh --dry-run
./install.sh
```

You can run the script from any working directory. To use another existing
destination directory:

```sh
./install.sh --target /path/to/destination --dry-run
./install.sh --target /path/to/destination
```

To install only a specific file or directory, pass its path relative to the
repository root. Its path under the destination stays the same:

```sh
./install.sh --only .config/ghostty --dry-run
./install.sh --only .config/ghostty
./install.sh --only .codex/AGENTS.md --target /path/to/destination
```

The usual exclusions still apply. `--only` does not follow symlinks in parent
directories; a selected symlink itself is copied as a symlink.

By default, the installer copies all repository contents, including hidden and untracked
files, except `.git`, `.DS_Store`, and the root `README.md`, `.gitignore`, and
`install.sh`. Nested files with those last three names are copied normally.
Git ignore rules do not determine what gets installed.

Directories are merged and matching files are overwritten with the repository
version. Files and subdirectories that exist only in the destination are kept,
even if you remove their counterparts from the repository later. Repeated runs
skip files whose contents and relevant metadata already match. Symlinks in the
repository are copied as symlinks.

Existing directory permissions and timestamps are not copied from the repository.
File timestamps and executability are preserved; other existing file permissions
are retained. New entries use the source permissions subject to the local umask.
Non-empty destination directories are never forcibly removed to replace them
with files or symlinks; these conflicts produce an error.

Before installation, the script shows diffs for existing files with different
contents. Changes that only add lines are installed without a prompt; changes
that remove or modify lines, binary changes, and entry type or symlink changes
require confirmation. Executability changes are also reported. `--dry-run` shows
the review without prompting or writing.
Use `--approve-all` to skip confirmation (the review is still shown), for example
`./install.sh --approve-all`. Declining or providing no input aborts the entire
installation before anything is copied. The installer also refuses source paths
that would overwrite the repository itself or replace one of its parent directories.

Installation overwrites matching files without backups. It does not install
packages, run application hooks, or restart services.
