# Changelog

## 1.6.4 (2026-11-24)

First release of the Railway template.

- Perlite 1.6.4 (`sec77/perlite:1.6.4@sha256:2de18f37…`, PHP 8.5.12, includes upstream's fix for CVE-2026-109618 and CVE-2026-109619).
- Caddy 2.11.9 with caddy-webdav (`v0.0.0-20260127042217-fa2f366b0d75`) in the same service instead of upstream's nginx container; upstream's access rules kept.
- Vault on the `/data` volume, WebDAV upload at `/webdav/` behind a generated password, optional site-wide password (`SITE_PASSWORD`).
- Health check `/healthz` through PHP-FPM; the container exits non-zero if PHP-FPM or Caddy stops, so Railway restarts it.
