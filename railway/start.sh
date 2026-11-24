#!/bin/sh
# Start script for Perlite on Railway: PHP-FPM + Caddy, vault on the /data volume.
# Exits non-zero when either process stops, so Railway's ON_FAILURE policy restarts it.
set -eu

DATA_DIR=${DATA_DIR:-/data}
export VAULT_DIR="${VAULT_DIR:-$DATA_DIR/vault}"
export PORT="${PORT:-8080}"
export WEBDAV_USERNAME="${WEBDAV_USERNAME:-perlite}"
WEBDAV_PASSWORD="${WEBDAV_PASSWORD:-}"
SITE_USERNAME="${SITE_USERNAME:-perlite}"
SITE_PASSWORD="${SITE_PASSWORD:-}"

log() { echo "[perlite-railway] $*"; }

if [ -z "$WEBDAV_PASSWORD" ]; then
	log "ERROR: WEBDAV_PASSWORD is empty. Set it (the template generates one) so the vault upload is locked."
	exit 1
fi
if [ ${#WEBDAV_PASSWORD} -lt 12 ]; then
	log "ERROR: WEBDAV_PASSWORD must be at least 12 characters."
	exit 1
fi

# CPU count from the cgroup limit, not the host (Railway shows the host's CPUs).
cpus=1
if [ -r /sys/fs/cgroup/cpu.max ]; then
	read -r quota period < /sys/fs/cgroup/cpu.max || true
	if [ "${quota:-max}" != "max" ] && [ "${period:-0}" -gt 0 ]; then
		cpus=$(( (quota + period - 1) / period ))
	else
		cpus=$(nproc 2>/dev/null || echo 2)
	fi
fi
[ "$cpus" -lt 1 ] && cpus=1
[ "$cpus" -gt 8 ] && cpus=8
export GOMAXPROCS="${GOMAXPROCS:-$cpus}"

# PHP-FPM workers from the memory limit (about 40 MB each, 2..16).
mem_mb=0
if [ -r /sys/fs/cgroup/memory.max ]; then
	m=$(cat /sys/fs/cgroup/memory.max)
	[ "$m" != "max" ] && mem_mb=$(( m / 1048576 ))
fi
if [ "$mem_mb" -gt 0 ]; then
	children=$(( (mem_mb - 128) / 40 ))
else
	children=8
fi
[ "$children" -lt 2 ] && children=2
[ "$children" -gt 16 ] && children=16
children="${PHP_FPM_MAX_CHILDREN:-$children}"

cat > /usr/local/etc/php-fpm.d/zz-railway.conf <<CONF
[global]
daemonize = no
error_log = /proc/self/fd/2

[www]
listen = 127.0.0.1:9000
pm = ondemand
pm.max_children = $children
pm.process_idle_timeout = 30s
pm.max_requests = 500
ping.path = /railway-fpm-ping.php
ping.response = ok
access.log = /dev/null
clear_env = no
CONF

# The vault lives on the volume; Perlite reads it as /var/www/perlite/Notes.
mkdir -p "$VAULT_DIR"
if [ ! -L /var/www/perlite/Notes ]; then
	rm -r /var/www/perlite/Notes 2>/dev/null || true
	ln -s "$VAULT_DIR" /var/www/perlite/Notes
fi

# First boot: put a welcome note in an empty vault (only once).
if [ ! -e "$DATA_DIR/.perlite-railway-seeded" ]; then
	if [ -z "$(ls -A "$VAULT_DIR" 2>/dev/null)" ]; then
		cp /usr/local/share/perlite-railway/welcome.md "$VAULT_DIR/README.md"
		log "Empty vault: added a welcome note (README.md)."
	fi
	touch "$DATA_DIR/.perlite-railway-seeded"
fi
chmod -R a+rX "$VAULT_DIR" 2>/dev/null || true

# Perlite settings with Railway-friendly defaults (any can be overridden as a variable).
if [ -z "${SITE_URL:-}" ] && [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
	export SITE_URL="https://$RAILWAY_PUBLIC_DOMAIN"
fi
export SITE_NAME="${SITE_NAME:-${SITE_TITLE:-Perlite}}"
export NOTES_PATH=Notes

# Caddy: hashed WebDAV password and the optional site-wide password.
WEBDAV_HASH=$(caddy hash-password --plaintext "$WEBDAV_PASSWORD")
export WEBDAV_HASH
mkdir -p /run/perlite-railway
if [ -n "$SITE_PASSWORD" ]; then
	site_hash=$(caddy hash-password --plaintext "$SITE_PASSWORD")
	printf 'basic_auth {\n\t%s %s\n}\n' "$SITE_USERNAME" "$site_hash" > /run/perlite-railway/site-auth.caddy
	log "SITE_PASSWORD is set: the whole site asks for a login."
else
	printf '# no site password\n' > /run/perlite-railway/site-auth.caddy
fi
caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile >/dev/null 2>&1 || {
	caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
	exit 1
}

# Secrets stay out of PHP's environment.
env -u WEBDAV_PASSWORD -u WEBDAV_HASH -u SITE_PASSWORD php-fpm -F &
fpm_pid=$!
for i in $(seq 1 50); do
	if nc -z 127.0.0.1 9000 2>/dev/null; then break; fi
	sleep 0.2
done
env -u WEBDAV_PASSWORD -u SITE_PASSWORD caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
caddy_pid=$!
unset WEBDAV_PASSWORD SITE_PASSWORD
log "Perlite 1.6.4 on port $PORT (PHP-FPM workers: $children, CPUs: $cpus)."

stop() { kill -TERM "$fpm_pid" "$caddy_pid" 2>/dev/null || true; exit 0; }
trap stop TERM INT QUIT

# BusyBox 'wait -n' doesn't return on the first exit, so poll.
while kill -0 "$fpm_pid" 2>/dev/null && kill -0 "$caddy_pid" 2>/dev/null; do
	sleep 2
done
log "ERROR: a process stopped (php-fpm alive: $(kill -0 $fpm_pid 2>/dev/null && echo yes || echo no), caddy alive: $(kill -0 $caddy_pid 2>/dev/null && echo yes || echo no)); exiting so Railway restarts the service."
kill -TERM "$fpm_pid" "$caddy_pid" 2>/dev/null || true
exit 1
