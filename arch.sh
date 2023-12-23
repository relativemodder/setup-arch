#!/bin/sh

set -e

user=$USER
case "$1" in
	-r | --root) user='root'; shift;;
esac

rootfs=$(cd "$(dirname "$0")"/.. && pwd)
export | sudo tee "$rootfs/bounce/env.sh" >/dev/null

exec sudo "$rootfs/bin/arch-chroot" "$rootfs" \
	/bin/su "$user" \
		/bin/sh -lc ". /bounce/env.sh; cd '$GITHUB_WORKSPACE' 2>/dev/null; exec \"\$@\"" -- \
			/bin/sh -eo pipefail "$@"