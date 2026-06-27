# Caddy

Custom Caddy image for `yusoofs-lighthouse`.

## Image

```text
ghcr.io/yusoofsh/caddy:latest
```

The GitHub Actions workflow builds on `ubuntu-latest` and publishes to GitHub Container Registry on every push to `main`.

It also runs daily from GitHub Actions schedule so `latest` is rebuilt against current Caddy base images and current unpinned module resolutions even when repository files do not change.

Published images include BuildKit provenance and SBOM attestations.

## Included Modules

- `github.com/caddy-dns/cloudflare`
- `github.com/WeidiDeng/caddy-cloudflare-ip`
- `github.com/lucaslorentz/caddy-docker-proxy/v2`
- `github.com/hslatman/caddy-crowdsec-bouncer/http`
- `github.com/hslatman/caddy-crowdsec-bouncer/appsec`

Module versions are intentionally not pinned in `Dockerfile`; the build resolves current versions at image build time.

## Rollback

Every successful publish creates:

- `latest`
- `sha-<commit>`

To roll back `yusoofs-lighthouse` if `latest` breaks, choose a known-good commit SHA from the package tags, then run:

```sh
cd /opt/stacks/caddy
cp compose.yaml "compose.yaml.bak-rollback-$(date +%Y%m%dT%H%M%S%z)"
perl -0pi -e 's#ghcr.io/yusoofsh/caddy:[^\s"]+#ghcr.io/yusoofsh/caddy:sha-<commit>#g' compose.yaml
docker compose pull ingress
docker compose up -d ingress
docker compose ps
docker compose logs --tail=100 ingress
```

Replace `<commit>` with the commit SHA suffix used by the `sha-<commit>` image tag.
