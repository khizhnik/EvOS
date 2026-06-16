#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
checkpoint_root="$(cd "${script_dir}/.." && pwd)"
snapshot_root="${checkpoint_root}/snapshots"

printf '%-28s %-20s %-18s %s\n' "SNAPSHOT" "DATE" "VM COMMIT" "CURRENT FRONTIER"

for snap in "${snapshot_root}"/*; do
    [[ -d "${snap}" ]] || continue
    name="$(basename "${snap}")"
    if [[ -f "${snap}/snapshot.json" ]]; then
        read -r date_line commit_line frontier <<<"$(python3 - "${snap}/snapshot.json" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    data = json.load(fh)
frontier = data.get("current_frontier", {})
print(
    data.get("created_utc", "<unknown>"),
    data.get("vm_head", "<unknown>")[:12],
    f"{frontier.get('file', '<unknown>')}:{frontier.get('line', '<unknown>')}",
    sep="\t",
)
PY
)"
    else
        date_line="$(sed -n 's/^date: //p' "${snap}/status.txt" 2>/dev/null | head -n 1)"
        commit_line="$(sed -n 's/^commit: //p' "${snap}/vm-commit.txt" 2>/dev/null | head -n 1)"
        frontier="$(awk '
            /^## Current frontier$/ {found=1; next}
            found && /^- Current blocker:/ {print $0; exit}
        ' "${snap}/notes.md" 2>/dev/null | sed 's/^- Current blocker: //' | sed 's/^`//; s/`$//')"
    fi
    short_commit="<unknown>"
    if [[ -n "${commit_line}" ]]; then
        short_commit="${commit_line:0:12}"
    fi
    printf '%-28s %-20s %-18s %s\n' "${name}" "${date_line:-<unknown>}" "${short_commit}" "${frontier:-<unknown>}"
done
