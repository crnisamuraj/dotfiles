# How does the installer decide what to copy? {#dotfiles-installer}

Only `Source:` and `Target:` after a successful run means no changes were reported for included paths. `.installignore` now controls which paths are included.

- The installer compares contents with checksums, not Git status or timestamps alone.[](source:transfer)
- Missing or content-different files are copied. Matching file contents are skipped; metadata can still change.[](source:transfer)
- There is no final success or no-change message. A successful repeat run can end after those two headings.[](source:review-start)[](source:transfer)
- Ignored paths are excluded from both review and copying. The `.archify` report folder is ignored by the current rules.[](source:selection)[](source:ignore-rules)

@answer scope="Working-tree snapshot; successful runs; observed output examples"
@meta locale=en style=editorial
@source arguments title="Working-tree snapshot: arguments and path validation" path=sources/install.sh lines=28:104
@source review-start title="Working-tree snapshot: headings and existing-entry review" path=sources/install.sh lines=106:145
@source review-rules title="Working-tree snapshot: diff and replacement review" path=sources/install.sh lines=146:170
@source selection title="Working-tree snapshot: shared filters and source selection" path=sources/install.sh lines=193:230
@source ignore-rules title="Working-tree snapshot: current .installignore rules" path=sources/.installignore lines=1:7
@source approval title="Working-tree snapshot: approval gate" path=sources/install.sh lines=232:239
@source transfer title="Working-tree snapshot: checksum-based rsync" path=sources/install.sh lines=241:257
@source documentation title="Working-tree snapshot: documented behavior and safety" path=sources/README.md lines=33:65

## What does the output mean? {#output}

```text title="The output you saw"
Source: /var/mnt/data/Projects/github/crnisamuraj/dotfiles/
Target: /home/vudu
```

Those headings identify the paths. They print before review and before `rsync`, so they do not prove success on their own.[](source:review-start)

| Output after the headings | Meaning |
| --- | --- |
| Nothing, with a successful exit | No changes were reported for the included paths. {good:No-op} |
| `>f+++++++++ first.txt` | A new regular file was copied, or would be copied in a dry run. |
| `.f..t...... timestamp.txt` | A timestamp changed; file contents were not transferred. |
| A unified diff or approval question | The installer is reviewing an existing entry before copying. |
| An error or nonzero exit | Do not call this a no-op. Investigate the failure. {caution:Check failure} |

The file and timestamp examples came from isolated tests with the installed GNU rsync. The original pasted output did not include its exit status.

## How does a normal install work? {#process}

@workflow id=install-flow title="Normal run: filter, review, then sync"
| resolve | Select included paths | backend | source:selection |
| review | Review differences | backend | source:review-start |
| gate | Approval required? | security | source:review-rules |
| approve | Approve install? | security | source:approval |
| abort | Abort before writes | external | source:approval |
| sync | Run rsync | backend | source:transfer |
| resolve > review | filtered |
| review > gate | inspected |
| gate > sync | no |
| gate > approve | yes |
| approve > sync | yes | emphasis |
| approve > abort | no | dashed |

@steps id=install-tour
| scope-step | Select included paths | Validate paths, apply mandatory exclusions and .installignore, then list included entries with an rsync dry run against an empty temporary directory. | install-flow | resolve |
| review-step | Review differences | Review only included entries. Compare existing regular files with cmp, show diffs, and report entry replacements. | install-flow | review |
| approval-step | Approve install? | Ask once for changes that remove or modify lines, binary changes, or symlink/type replacements. Rejection aborts everything before copying. | install-flow | approve |
| transfer-step | Run rsync | Visit the included paths, compare file contents by checksum, merge directories, and print itemized changes. | install-flow | sync |

`--dry-run` still reviews differences, but skips the prompt and previews rsync without writing. `--approve-all` skips confirmation, not review or change detection.[](source:approval)[](source:transfer)

## How does `.installignore` work? {#ignore}

The control file is named `.installignore`, not `.installerignore`. It lives at the repository root and supplies rsync exclude patterns, one per line.[](source:selection)[](source:documentation)

| Pattern or rule | Scope and effect | Where it is enforced |
| --- | --- | --- |
| `.archify` | Excludes matching files or directories at any depth, including this report folder. | Current `.installignore` |
| `.DS_Store` | Excludes matching entries at any depth. | Current `.installignore` |
| `/README.md`, `/.gitignore`, `/install.sh` | Excludes only those root entries. Nested files with those names remain eligible. | Current `.installignore` |
| `.git` | Excludes matching entries at any depth. | Mandatory in the installer; also listed in `.installignore` |
| `/.installignore` | Excludes the root control file itself. | Mandatory in the installer |

These are the current rules, not a fixed list of all possible exclusions.[](source:ignore-rules)[](source:selection)

To add exclusions, put `/private/` on a line to exclude the root directory, or `*.tmp` to exclude matching files at any depth.[](source:documentation)

The installer builds one filter list and uses it for both the pre-install review and the final rsync. Ignored files produce no review diff or approval prompt.[](source:selection)[](source:transfer)

`--only` does not override exclusions. Selecting `.archify` or an ignored child fails with `Excluded path` before copying.[](source:selection)

@callout level=warning title="Removing rules changes what can be installed"
| If `.installignore` is absent, only `.git` and root `.installignore` remain excluded. README.md, install.sh, and .archify are no longer excluded by default. |
| Mandatory exclusions come before user rules, so include rules cannot override them. An ignore rule never deletes an earlier copy at the target.[](source:selection)[](source:transfer) |

`.gitignore` controls Git, not installation. Hidden, untracked, and Git-ignored files can still be copied unless `.installignore` excludes them.[](source:documentation)

## What is copied, skipped, or protected? {#rules}

| Situation | What the installer does |
| --- | --- |
| Entry is missing at the target | Copies it without a prompt. |
| Existing regular file contents match | Skips content transfer. Timestamps or executability may still update without a prompt. |
| Text changes only add lines | Shows the diff and installs without a prompt. |
| Text changes remove or modify lines; binary contents differ | Shows the change and requires approval unless `--approve-all` is set. |
| Existing symlink target or entry type differs | Requires approval unless `--approve-all` is set. Source symlinks stay symlinks. |
| Entry exists only at the target | Keeps it. There is no deletion mirror. {good:Retained} |
| A non-empty target directory conflicts with a source file or symlink | Errors instead of forcibly removing the directory. {caution:Not replaced} |

These rules come from the preflight review and rsync configuration.[](source:review-start)[](source:review-rules)[](source:transfer)[](source:documentation)

These actions apply only to paths that pass the ignore filters. Excluded source changes and destination-only entries are left alone.[](source:selection)[](source:transfer)

`--only PATH` narrows the selection but keeps its relative destination path. Existing directory permissions and timestamps are retained. File timestamps and executability follow the source.[](source:arguments)[](source:documentation)

@callout level=warning title="Approval is not a backup or a transaction"
| Matching files are overwritten without backups. A rejected approval prevents all copying, but a later rsync failure can leave partial changes. |
| No packages are installed, application hooks run, or services restarted. See the source safety notes.[](source:documentation) |

## How can I verify this safely? {#verify}

```sh title="Preview the whole install without writing"
./install.sh --dry-run
```

```sh title="Preview only one application directory"
./install.sh --only .config/ghostty --dry-run
```

A preview uses the same ignore filters and checksum logic. New or changed entries produce itemized output without being copied.[](source:selection)[](source:transfer)

@facts
| Current target check | A read-only dry run with `.archify` present exited 0, printing only Source/Target. |
| Explicit exclusion check | `./install.sh --only .archify --dry-run` exited 1 with `Excluded path: .archify`, as intended. |
| New feature tests | All 12 isolated ignore-feature checks passed. They covered review suppression, transfer exclusions, --only, anchored patterns, wildcards, mandatory filters, missing rules, Git ignores, and retained destination files. |
| Report location | Project `.archify/explainer-dotfiles-installer-20261107-024408/`, excluded by the current `.installignore`. |

@callout level=note title="These sources include uncommitted changes"
| The report explains the current working tree, not a committed release. Existing changes to `install.sh`, `README.md`, and the new `.installignore` were not modified by this report task. |
| The bundle includes exact source copies in `sources/` and their SHA-256 hashes in `sources/snapshot.json`. Citations refer to those copies, not verified commit links. |

@callout level=note title="Symlink validation limit"
| An earlier symlink test created the correct link, but rsync exited 23 when setting symlink permissions: Operation not supported (95). That filesystem limitation was not retested in this update. |

- [ ] Confirm that Source and Target name the intended directories.
- [ ] Keep `.archify` in `.installignore` while storing reports here.
- [ ] Preview with `--dry-run` before a real install.
- [ ] Treat a silent preview as no planned changes only when the command exits successfully.
- [ ] Back up local changes before approving overwrites that you may need to undo.
