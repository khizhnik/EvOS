#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: create-xnu-checkpoint.sh SNAPSHOT_NAME [NOTE...]

Creates a numbered snapshot from the active VM XNU tree and stores it under:
  checkpoints/xnu-lab/snapshots/SNAPSHOT_NAME/

The script:
  - captures git status and commit metadata from the VM
  - stores the tracked patch as a binary diff
  - prompts before archiving any intentional untracked files
  - refuses to overwrite an existing snapshot
EOF
}

if [[ $# -lt 1 ]]; then
    usage >&2
    exit 2
fi

snapshot_name=$1
shift || true
note_text=${*:-}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
checkpoint_root="$(cd "${script_dir}/.." && pwd)"
snapshot_dir="${checkpoint_root}/snapshots/${snapshot_name}"
vm_tree="/Users/khizhnik/Work/EvOS/xnu"
ssh_user="khizhnik"
ssh_host="localhost"
ssh_port="10022"
ssh_pass="${SSH_PASSWORD:-Ping_Uin}"

if [[ -e "${snapshot_dir}" ]]; then
    echo "snapshot already exists: ${snapshot_dir}" >&2
    exit 1
fi

mkdir -p "${snapshot_dir}"

remote() {
    sshpass -p "${ssh_pass}" ssh -p "${ssh_port}" -o StrictHostKeyChecking=no \
        "${ssh_user}@${ssh_host}" "$@"
}

remote_sh() {
    remote "cd '${vm_tree}' && ${1}"
}

head_commit="$(remote_sh 'git rev-parse HEAD')"
base_commit="$(remote_sh 'git rev-parse HEAD^')"
branch="$(remote_sh 'git branch --show-current')"
tags="$(remote_sh 'git tag --points-at HEAD | paste -sd, -')"
subject="$(remote_sh 'git show -s --format=%s HEAD')"
status_short="$(remote_sh 'git status --short')"
diffstat="$(remote_sh 'git diff --stat')"
cachedstat="$(remote_sh 'git diff --cached --stat')"
show_stat="$(remote_sh 'git show --stat --oneline HEAD')"
vm_uname="$(remote_sh 'uname -a')"
build_command=$'cd /Users/khizhnik/Work/EvOS/xnu\n\nSDKROOT=$(/usr/bin/xcrun --sdk macosx --show-sdk-path)\n\nRC_DARWIN_KERNEL_VERSION=23.6.0 \\\nmake SDKROOT="$SDKROOT" \\\n  ARCH_CONFIGS=X86_64 \\\n  KERNEL_CONFIGS=DEVELOPMENT'
snapshot_json="${snapshot_dir}/snapshot.json"
journal_root="${checkpoint_root}/journal"
mkdir -p "${journal_root}"

printf '%s\n' "${head_commit}" > "${snapshot_dir}/commit.txt"
printf '%s\n' "${base_commit}" > "${snapshot_dir}/base-commit.txt"

remote_sh "git diff --binary ${base_commit} ${head_commit}" > "${snapshot_dir}/tracked.patch"

mapfile -t intentional_untracked < <(remote_sh "git status --short" | awk '/^\?\? /{print substr($0,4)}' | grep -v '^BUILD/obj/' | grep -v '^\\.DS_Store$' || true)
if (( ${#intentional_untracked[@]} > 0 )); then
    printf 'Intentional untracked files considered for archiving:\n' >&2
    printf '  %s\n' "${intentional_untracked[@]}" >&2
    read -r -p "Archive these untracked files into ${snapshot_name}/untracked.tar.gz? [y/N] " answer
    case "${answer}" in
        y|Y|yes|YES)
            printf '%s\n' "${intentional_untracked[@]}" | remote "cd '${vm_tree}' && tar -czf - -T -" > "${snapshot_dir}/untracked.tar.gz"
            ;;
        *)
            echo "untracked files were not archived; creating an empty archive" >&2
            tar -czf "${snapshot_dir}/untracked.tar.gz" --files-from /dev/null
            ;;
    esac
else
    tar -czf "${snapshot_dir}/untracked.tar.gz" --files-from /dev/null
fi

cat > "${snapshot_dir}/status.txt" <<EOF
date: $(date -u '+%Y-%m-%dT%H:%M:%SZ')
linux-host: $(uname -a)
vm-uname: ${vm_uname}
vm-tree: ${vm_tree}
vm-head: ${head_commit}
vm-branch: ${branch}
vm-tags: ${tags:-<none>}
git-status-short:
$(printf '%s\n' "${status_short}")
git-diff-stat:
$(printf '%s\n' "${diffstat}")
git-diff-cached-stat:
$(printf '%s\n' "${cachedstat}")
intentional-untracked-considered:
$(if (( ${#intentional_untracked[@]} > 0 )); then printf '%s\n' "${intentional_untracked[@]}"; else printf '%s\n' "<none>"; fi)
excluded-build-artifacts:
- BUILD/obj/*.o
- BUILD/obj/*.d
- BUILD/obj/**/*.o
- BUILD/obj/**/*.d
- BUILD/obj/san/
- BUILD/obj/xnuVersion
- temporary logs
- .DS_Store
EOF

cat > "${snapshot_dir}/vm-commit.txt" <<EOF
branch: ${branch}
commit: ${head_commit}
base-commit: ${base_commit}
tag: ${tags:-<none>}
subject: ${subject}
show-stat:
${show_stat}
EOF

cat > "${snapshot_dir}/build-command.txt" <<EOF
${build_command}
EOF

cat > "${snapshot_dir}/notes.md" <<EOF
# Snapshot ${snapshot_name}

${note_text:-Imported VM checkpoint snapshot from the current validated F-002..F-022 state.}

## Notes

- This snapshot is stored on the Linux host and is the primary durable checkpoint.
- VM-local branch/tag state is secondary convenience state only.
- Intentional untracked headers/shims are archived explicitly when present.
- The full BUILD directory is not archived blindly.
EOF

SNAPSHOT_NAME="${snapshot_name}" \
SNAPSHOT_CREATED_UTC="$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
SNAPSHOT_LINUX_HOST="$(uname -a)" \
SNAPSHOT_VM_UNAME="${vm_uname}" \
SNAPSHOT_VM_TREE="${vm_tree}" \
SNAPSHOT_VM_HEAD="${head_commit}" \
SNAPSHOT_VM_BRANCH="${branch}" \
SNAPSHOT_VM_TAG="${tags:-<none>}" \
SNAPSHOT_BASE_COMMIT="${base_commit}" \
SNAPSHOT_SUBJECT="${subject}" \
SNAPSHOT_VALIDATED_RANGE="F-002..F-022" \
SNAPSHOT_EXCLUDED_EDIT="libkern/c++/OSMetaClass.cpp alloc override" \
SNAPSHOT_FRONTIER_FILE="BUILD/obj/EXPORT_HDRS/libkern/libkern/c++/OSMetaClass.h" \
SNAPSHOT_FRONTIER_LINE="1232" \
SNAPSHOT_FRONTIER_CLASS="-Winconsistent-missing-override" \
SNAPSHOT_FRONTIER_SYMBOL="taggedRelease" \
SNAPSHOT_FRONTIER_SUBSYSTEM="pexpert/i386" \
python3 - "${snapshot_json}" <<'PY'
import json
import os
import sys

path = sys.argv[1]
payload = {
    "name": os.environ["SNAPSHOT_NAME"],
    "created_utc": os.environ["SNAPSHOT_CREATED_UTC"],
    "linux_host": os.environ["SNAPSHOT_LINUX_HOST"],
    "vm_uname": os.environ["SNAPSHOT_VM_UNAME"],
    "vm_tree": os.environ["SNAPSHOT_VM_TREE"],
    "vm_head": os.environ["SNAPSHOT_VM_HEAD"],
    "vm_branch": os.environ["SNAPSHOT_VM_BRANCH"],
    "vm_tag": os.environ["SNAPSHOT_VM_TAG"],
    "base_commit": os.environ["SNAPSHOT_BASE_COMMIT"],
    "subject": os.environ["SNAPSHOT_SUBJECT"],
    "validated_fix_range": os.environ["SNAPSHOT_VALIDATED_RANGE"],
    "excluded_unvalidated_edit": os.environ["SNAPSHOT_EXCLUDED_EDIT"],
    "current_frontier": {
        "file": os.environ["SNAPSHOT_FRONTIER_FILE"],
        "line": int(os.environ["SNAPSHOT_FRONTIER_LINE"]),
        "failure_class": os.environ["SNAPSHOT_FRONTIER_CLASS"],
        "symbol": os.environ["SNAPSHOT_FRONTIER_SYMBOL"],
        "latest_successful_subsystem": os.environ["SNAPSHOT_FRONTIER_SUBSYSTEM"],
    },
    "artifacts": {
        "tracked_patch": "tracked.patch",
        "untracked_tar": "untracked.tar.gz",
        "manifest": "manifest.txt",
    },
}
with open(path, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, indent=2, sort_keys=True)
    fh.write("\n")
PY

cat > "${journal_root}/${snapshot_name}.md" <<EOF
# ${snapshot_name}

- VM commit: \`${head_commit}\`
- VM branch: \`${branch}\`
- VM tag: \`${tags:-<none>}\`
- Validated range: \`F-002..F-022\`
- Excluded unvalidated edit: \`libkern/c++/OSMetaClass.cpp alloc override\`
- Current frontier:
  - \`${snapshot_dir}/snapshot.json\`
EOF

(
    cd "${snapshot_dir}"
    sha256sum $(printf '%s\n' base-commit.txt build-command.txt commit.txt notes.md snapshot.json status.txt tracked.patch untracked.tar.gz vm-commit.txt) > manifest.txt
)

echo "created snapshot: ${snapshot_dir}"
