# Welcome to your Perlite site

This page is the `README.md` note in your vault. Perlite on Railway is running: anything you put in the vault shows up here as a website, with the folder tree on the left, search, links, tags, LaTeX, Mermaid and (with a `metadata.json`) the graph.

## Put your notes in the vault

Your vault lives on the Railway volume at `/data/vault`. You can fill it in two ways:

1. **WebDAV (recommended).** Connect to `https://YOUR-DOMAIN/webdav/` with the username `perlite` and the password in the service's `WEBDAV_PASSWORD` variable.
   - From Obsidian: install the community plugin **Remotely Save**, choose WebDAV, enter that address, username and password, and sync. Remotely Save puts the vault in a folder named after your vault, so set the plugin's remote base directory to `/` or move the files up.
   - From a computer: mount it in your file manager (Finder: Go → Connect to Server; Windows: Map network drive) or use `rclone`.
2. **Railway shell.** `railway ssh` into the service and copy files into `/data/vault`.

Delete or replace this `README.md` when your own notes are in place: Perlite opens the note named in `HOME_FILE` (default `README`) as the home page.

## Graph

The graph needs a `metadata.json` in the vault root, written by the Obsidian plugin **Metadata Extractor**. It is never served to visitors.

## Settings

Perlite reads its settings from the service's variables, for example `SITE_TITLE`, `HIDE_FOLDERS`, `HOME_FILE`, `SHOW_TOC` or `HTML_SAFE_MODE`. See the [Perlite settings](https://github.com/secure-77/Perlite/blob/main/perlite/Demo/Documentation/03-Env-Settings.md). Set `SITE_PASSWORD` to make the whole site ask for a login.
