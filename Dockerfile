FROM golang:1.26.8-alpine@sha256:8ac98ca534ac3f51e1f420a1dd2c15e74c75cfa0f23f3ad27eb5d7236c349a0c AS toolchain
FROM caddy:2.11.4-builder-alpine@sha256:0aa610043dab5da82ad0a0268e46bb852785e6f5160f12f1c6fe3f42903d7e1b AS builder

COPY --from=toolchain /usr/local/go /opt/go
ENV PATH="/opt/go/bin:${PATH}" GOROOT=/opt/go GOTOOLCHAIN=local

RUN go version && GOMAXPROCS=2 GOMEMLIMIT=1600MiB xcaddy build v2.11.4 \
  --with github.com/caddy-dns/cloudflare@v0.2.4 \
  --with github.com/WeidiDeng/caddy-cloudflare-ip@v0.0.0-20231130002422-f53b62aa13cb \
  --with github.com/lucaslorentz/caddy-docker-proxy/v2@v2.13.1 \
  --with github.com/hslatman/caddy-crowdsec-bouncer/http@v0.14.1 \
  --with github.com/hslatman/caddy-crowdsec-bouncer/appsec@v0.14.1 \
  --replace golang.org/x/net=golang.org/x/net@v0.56.0 \
  --replace golang.org/x/crypto=golang.org/x/crypto@v0.55.0 \
  --replace golang.org/x/text=golang.org/x/text@v0.39.0 \
  --replace google.golang.org/grpc=google.golang.org/grpc@v1.83.2 \
  --replace github.com/crowdsecurity/crowdsec=github.com/crowdsecurity/crowdsec@v1.7.8

FROM caddy:2.11.4-alpine@sha256:6aeddd44c3078b0f9a35206472a11420648a79c184603ef95957d0a20044cb2b

RUN apk add --no-cache bash

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
