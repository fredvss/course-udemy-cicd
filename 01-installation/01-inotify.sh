#!/usr/bin/env bash
# Aumenta os limites do inotify para evitar erro de watch e aplica a configuracao.
set -euo pipefail

SYSCTL_FILE="/etc/sysctl.conf"

set_or_append_sysctl_key() {
	local key="$1"
	local value="$2"

	if sudo grep -Eq "^[[:space:]]*${key}[[:space:]]*=" "$SYSCTL_FILE"; then
		sudo sed -i -E "s|^[[:space:]]*${key}[[:space:]]*=.*$|${key}=${value}|" "$SYSCTL_FILE"
	else
		echo "${key}=${value}" | sudo tee -a "$SYSCTL_FILE" >/dev/null
	fi
}

set_or_append_sysctl_key "fs.inotify.max_user_watches" "655360"
set_or_append_sysctl_key "fs.inotify.max_user_instances" "1280"

sudo sysctl -p "$SYSCTL_FILE" >/dev/null
echo "inotify limits applied successfully."