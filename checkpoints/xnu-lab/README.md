# XNU Build Lab Checkpoints

This directory is the durable Linux-host checkpoint store for the EvOS XNU build lab.

Source of truth:

- Linux host checkpoint tree: `checkpoints/xnu-lab/`
- VM tree: `/Users/khizhnik/Work/EvOS/xnu`

Current imported snapshot:

- `snapshots/000-f022-restored/`

Policy:

- Treat Linux-host snapshots as the primary durable record.
- Treat VM-local commits and tags as convenience state only.
- Keep intentional untracked shims and restored headers explicit.
- Do not archive the full `BUILD/` directory blindly.

The scripts in `bin/` are intentionally small and reversible:

- `create-xnu-checkpoint.sh`
- `restore-xnu-checkpoint.sh`
- `list-xnu-checkpoints.sh`

Each snapshot directory should contain:

- `snapshot.json` for machine-readable metadata
- `manifest.txt` for SHA256 integrity checks
- `tracked.patch` and `untracked.tar.gz` for restore material
- `notes.md`, `status.txt`, `vm-commit.txt`, and `build-command.txt` for human review

The `journal/` directory stores append-only notes for each validated snapshot.
