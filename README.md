[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/perlite?utm_medium=integration&utm_source=button&utm_campaign=perlite)

# Perlite on Railway

One-click [Perlite](https://github.com/secure-77/Perlite) for [Railway](https://railway.com): publish an Obsidian vault, or any folder of Markdown notes, as a website.

## What it deploys

| Service | What it does |
|---|---|
| `Perlite` | Perlite **1.6.4** (`sec77/perlite:1.6.4@sha256:2de18f37564a4a5827b8809601586a409412eaaefca3dda89419fafd4b708d2f`, PHP 8.5.12 FPM on Alpine) plus Caddy **2.11.9** with the [WebDAV module](https://github.com/mholt/caddy-webdav), built from pinned sources. Listens on `PORT` (8080), health check `/healthz`. |

One volume at `/data`: the vault is `/data/vault`. No database.

Upstream runs PHP-FPM and nginx as two containers sharing one volume. Railway services can't share a volume, so here Caddy replaces nginx inside the same service and applies the same access rules as upstream's `perlite.conf`: note sources (`.md`), `.json` files (including `metadata.json`) and `.obsidian` settings are never served as files (theme CSS and `appearance.json` are), and only Perlite's own `index.php` and `content.php` run as PHP: a `.php` file in the vault is never executed.

Fits Railway's 0.5 GB / 1 vCPU plan: about 35–55 MB in use under load in our tests. PHP-FPM workers are sized from the memory limit (`ondemand`, 2–16) and Caddy's threads from the CPU limit.

## Variables

| Variable | Default | What it is |
|---|---|---|
| `WEBDAV_PASSWORD` | `${{secret(24)}}` | Password for the WebDAV endpoint `/webdav/` that writes to the vault. Generated; the service won't start without one of at least 12 characters. |
| `WEBDAV_USERNAME` | `perlite` | WebDAV username. |
| `SITE_TITLE` | `Perlite` | Browser tab title. |
| `PORT` | `8080` | Port Caddy listens on. |

Optional, add them yourself:

- `SITE_PASSWORD` (and `SITE_USERNAME`, default `perlite`): makes the whole site ask for a login. Empty by default, because Perlite publishes notes.
- Any Perlite setting from [`.env.example`](https://github.com/secure-77/Perlite/blob/1.6.4/.env.example), for example `HOME_FILE`, `HIDE_FOLDERS`, `SHOW_TOC`, `HTML_SAFE_MODE`, `SITE_DESC`, `SITE_NAME`. `SITE_URL` defaults to the service's Railway domain. `NOTES_PATH` is fixed by the template.

## Put your notes in the vault

On first boot the empty vault gets a welcome `README.md`. Then:

1. **WebDAV:** `https://YOUR-DOMAIN/webdav/`, user `perlite`, password from `WEBDAV_PASSWORD`. From Obsidian use the community plugin **Remotely Save** (WebDAV); from a computer mount it in your file manager or use `rclone`.
2. **Railway shell:** `railway ssh`, then copy files into `/data/vault`.

For the graph, let the Obsidian plugin **Metadata Extractor** write `metadata.json` into the vault root. Perlite's graph cache goes to `/tmp` and is rebuilt when `metadata.json` changes.

## Updates

The template builds from this repo's `main` branch. When a new Perlite release is pinned here, Railway shows everyone who deployed the template an "update available" notice; read [`CHANGELOG.md`](CHANGELOG.md) (breaking changes first) and apply it when you choose. The vault on the volume is kept.

## Local test

```sh
docker compose -f compose.test.yml up --build
# http://localhost:8080, WebDAV user perlite / password test-password-1234567890
```

## Licence

Perlite is MIT-licensed by [secure-77](https://github.com/secure-77/Perlite). Caddy and caddy-webdav are Apache-2.0. This wrapper is MIT.
