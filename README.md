# Caddy

Custom Caddy image for `yusoofs-lighthouse`.

## Image

```text
ghcr.io/yusoofsh/caddy:latest
```

The GitHub Actions workflow builds on `ubuntu-latest` and publishes to GitHub Container Registry on every push to `main`.

## Included Modules

- `github.com/caddy-dns/cloudflare`
- `github.com/WeidiDeng/caddy-cloudflare-ip`
- `github.com/lucaslorentz/caddy-docker-proxy/v2`
- `github.com/hslatman/caddy-crowdsec-bouncer/http`
- `github.com/hslatman/caddy-crowdsec-bouncer/appsec`

Module versions are intentionally not pinned in `Dockerfile`; the build resolves current versions at image build time.
