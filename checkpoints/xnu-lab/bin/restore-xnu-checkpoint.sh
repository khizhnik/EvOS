#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: restore-xnu-checkpoint.sh [--force] SNAPSHOT_NAME

Restores a checkpoint snapshot into the active VM tree.

By default the script refuses to continue if the VM tree is dirty or if the
current HEAD does not match the snapshot base commit. Use --force to proceed
after the safety check.
EOF
}

force=0
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            force=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            break
            ;;
    esac
done

if [[ $# -ne 1 ]]; then
    usage >&2
    exit 2
fi

snapshot_name=$1
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
checkpoint_root="$(cd "${script_dir}/.." && pwd)"
snapshot_dir="${checkpoint_root}/snapshots/${snapshot_name}"
tracked_patch="${snapshot_dir}/tracked.patch"
untracked_tar="${snapshot_dir}/untracked.tar.gz"
base_commit_file="${snapshot_dir}/base-commit.txt"
snapshot_commit_file="${snapshot_dir}/commit.txt"
vm_tree="/Users/khizhnik/Work/EvOS/xnu"
ssh_user="khizhnik"
ssh_host="localhost"
ssh_port="10022"
ssh_pass="${SSH_PASSWORD:-Ping_Uin}"

if [[ ! -f "${tracked_patch}" ]]; then
    echo "missing tracked patch: ${tracked_patch}" >&2
    exit 1
fi

remote() {
    sshpass -p "${ssh_pass}" ssh -p "${ssh_port}" -o StrictHostKeyChecking=no \
        "${ssh_user}@${ssh_host}" "$@"
}

base_commit="$(cat "${base_commit_file}")"
snapshot_commit="$(cat "${snapshot_commit_file}")"
remote_status="$(remote "cd '${vm_tree}' && git status --short")"
remote_head="$(remote "cd '${vm_tree}' && git rev-parse HEAD")"

if [[ -n "${remote_status}" && ${force} -eq 0 ]]; then
    echo "VM tree is dirty; refusing to restore without --force" >&2
    echo "${remote_status}" >&2
    exit 1
fi

if [[ "${remote_head}" != "${snapshot_commit}" ]]; then
    if [[ "${remote_head}" != "${base_commit}" ]]; then
        if [[ ${force} -eq 0 ]]; then
            echo "VM HEAD (${remote_head}) does not match snapshot base commit (${base_commit})" >&2
            echo "rerun with --force if you want to realign the VM tree first" >&2
            exit 1
        fi
        remote "cd '${vm_tree}' && git checkout --force '${base_commit}'"
    fi

    remote "cd '${vm_tree}' && git apply --binary - < /dev/stdin" < "${tracked_patch}"
else
    echo "VM already at snapshot commit ${snapshot_commit}; skipping tracked patch application" >&2
fi

if [[ -s "${untracked_tar}" ]]; then
    remote "cd '${vm_tree}' && tar -xzf - < /dev/stdin" < "${untracked_tar}"
fi

remote "cd '${vm_tree}' && git status --short"
echo "restored snapshot: ${snapshot_name}"
