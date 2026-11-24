# Perlite on Railway: upstream PHP-FPM image + Caddy (with WebDAV) in one service.
# Upstream runs PHP-FPM and nginx as two containers sharing one volume; Railway
# services can't share volumes, so Caddy serves the site here instead of nginx.

# Caddy 2.11.9 with the WebDAV module, built from pinned sources.
FROM caddy:2.11.9-builder-alpine@sha256:86e132d1d6db8850352b2dbc15f82a4cb25363ac305ee41e11405873e5931f37 AS caddy
ENV GOFLAGS=-p=2
RUN xcaddy build v2.11.9 \
      --with github.com/mholt/caddy-webdav@v0.0.0-20260127042217-fa2f366b0d75 \
      --output /usr/local/bin/caddy \
 && /usr/local/bin/caddy list-modules | grep -q '^http.handlers.webdav$'

# Perlite 1.6.4 (official image, PHP 8.5.12 on Alpine).
FROM sec77/perlite:1.6.4@sha256:2de18f37564a4a5827b8809601586a409412eaaefca3dda89419fafd4b708d2f

COPY --from=caddy /usr/local/bin/caddy /usr/local/bin/caddy
COPY railway/Caddyfile /etc/caddy/Caddyfile
COPY railway/welcome.md /usr/local/share/perlite-railway/welcome.md
COPY railway/start.sh /usr/local/bin/perlite-railway-start
RUN chmod 0755 /usr/local/bin/perlite-railway-start \
 && caddy version

ENV PORT=8080 \
    NOTES_PATH=Notes \
    VAULT_DIR=/data/vault

EXPOSE 8080
STOPSIGNAL SIGTERM
CMD ["/usr/local/bin/perlite-railway-start"]
