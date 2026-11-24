# Deploy and Host Perlite on Railway

Perlite is an open-source web viewer that publishes an Obsidian vault, or any folder of Markdown notes, as a website. It builds the page from your folder structure and shows notes with Obsidian links, tags, callouts, LaTeX, Mermaid, canvases, themes, search and an interactive graph. It is an open-source alternative to Obsidian Publish.

## About Hosting Perlite

Perlite needs no database: it reads your vault from disk and renders it with PHP. This template runs Perlite 1.6.4 (the official image, PHP 8.5) with Caddy in one service and keeps the vault on a Railway volume, so your notes survive redeploys and restarts. Caddy serves the site on Railway's domain, applies upstream's access rules (note sources, `metadata.json` and `.obsidian` settings are never served as files) and adds a WebDAV endpoint at `/webdav/`, locked with a generated password, so you can upload and sync notes. A first boot puts a welcome note in the empty vault. It fits Railway's 0.5 GB plan.

## Common Use Cases

* Publish an Obsidian vault as a public knowledge base, digital garden or documentation site
* Share project notes or a team handbook written in Markdown without a hosted publishing plan
* Keep a read-only web copy of your notes that you sync from Obsidian over WebDAV

## Dependencies for Perlite Hosting

* One Railway service built from the template repo (Perlite + PHP-FPM + Caddy)
* One Railway volume at `/data` for the vault

### Deployment Dependencies

* Perlite: https://github.com/secure-77/Perlite (release 1.6.4)
* Perlite settings: https://github.com/secure-77/Perlite/blob/main/perlite/Demo/Documentation/03-Env-Settings.md
* Template source: https://github.com/aalfath/perlite-railway-template
* Remotely Save (Obsidian plugin for WebDAV sync): https://github.com/remotely-save/remotely-save

### Implementation Details

**Services.** `Perlite`: PHP-FPM renders the notes and Caddy serves them on `PORT` 8080, with a health check at `/healthz`. The vault is the volume folder `/data/vault`.

**After deploy.** Open the service's Railway domain: you see a welcome note. Then put your notes in the vault:

1. **WebDAV.** Address `https://YOUR-DOMAIN/webdav/`, username `perlite` (`WEBDAV_USERNAME`), password in the service's `WEBDAV_PASSWORD` variable. In Obsidian, install the community plugin Remotely Save, pick WebDAV, enter those three values and sync; or mount the address in your file manager or with `rclone`.
2. **Railway shell.** `railway ssh` into the service and copy files to `/data/vault`.

Replace the welcome `README.md` with your own home note (`HOME_FILE`, default `README`). For the graph, let the Obsidian plugin Metadata Extractor write `metadata.json` into the vault root.

**Settings.** Perlite reads its `.env` settings from service variables: add any of `SITE_TITLE`, `HOME_FILE`, `HIDE_FOLDERS`, `SHOW_TOC`, `HTML_SAFE_MODE`, `SITE_DESC` and the others in the settings link above. Set `SITE_PASSWORD` to make the whole site ask for a login (user `perlite`, or `SITE_USERNAME`). Without it the site is public, which is what Perlite is for: only publish notes you want people to read.

**Updates.** The service builds from the template repo, which pins Perlite's image by version and digest. When we publish a new Perlite release there, Railway shows you an update notice; read the repo's `CHANGELOG.md` and apply it when you choose. Your vault stays on the volume.

## Why Deploy Perlite on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Perlite on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
