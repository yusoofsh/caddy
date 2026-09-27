# Caddy

Custom Caddy image for `yusoofs-lighthouse`.

## Image

```text
ghcr.io/yusoofsh/caddy:latest
```

The GitHub Actions workflow builds on `ubuntu-latest` and publishes to GitHub Container Registry on every push to `main`.

Use `workflow_dispatch` on a reviewed branch to publish a commit-specific candidate without moving `latest`. The Lighthouse Compose file defaults to the `main` image at `:latest`; set `CADDY_IMAGE` or `SOCKET_PROXY_IMAGE` explicitly when a digest-pinned rollback is required.

Published images include BuildKit provenance and SBOM attestations.

## Included Modules

- `github.com/caddy-dns/cloudflare`
- `github.com/WeidiDeng/caddy-cloudflare-ip`
- `github.com/lucaslorentz/caddy-docker-proxy/v2`
- `github.com/hslatman/caddy-crowdsec-bouncer/http`
- `github.com/hslatman/caddy-crowdsec-bouncer/appsec`

Base image digests, Go, and plugin versions are pinned in `Dockerfile`; Caddy itself follows upstream `master` at build time rather than a release tag. The Go toolchain is explicitly copied from the pinned Go image rather than inherited from an older Caddy builder. The `x/net` replacement carries the DNS parser security fix. Review and rebuild these pins regularly; pinning is not a substitute for updates.

## Discovery isolation

The image supports `CADDY_DOCKER_MODE=controller` and `server`. Only the private controller should reach the Docker socket proxy. The public server must not join the socket network or mount a Docker socket. Preserve the server's `/data` volume for certificates.

The upstream controller uses the server's private HTTP admin listener; it does not provide mutual TLS. Isolate its control network, bind the listener only there, restrict traffic to controller-to-server configuration pushes, and verify no reverse path to the Docker API. The controller's admin API is disabled by upstream in controller-only mode. Never publish the control listener on the host.

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
