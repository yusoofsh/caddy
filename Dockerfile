FROM golang:1.27.2-alpine@sha256:f92b6ef800e499660581efdabdf25d9d817a9d124eaf900924f0504e7e27e12d AS toolchain
FROM caddy:2-builder-alpine@sha256:d6161a2c82fd58b3205048958fb6246d0c5d892beee8a47e90944610c4efd100 AS builder

COPY --from=toolchain /usr/local/go /opt/go
ENV PATH="/opt/go/bin:${PATH}" GOROOT=/opt/go GOTOOLCHAIN=local

# Build Caddy from the upstream development branch. The surrounding image
# stages provide the reproducible Go/Alpine toolchain and runtime hardening;
# the application source is a verified snapshot of upstream `master`.
ARG CADDY_COMMIT=719db53e946181dd10a9aae36721c3251f7f8dc1
RUN go version && GOMAXPROCS=2 GOMEMLIMIT=1600MiB GOFLAGS=-p=2 xcaddy build "${CADDY_COMMIT}" \
  --with github.com/caddy-dns/cloudflare@v0.2.4 \
  --with github.com/WeidiDeng/caddy-cloudflare-ip@v0.0.0-20231130002422-f53b62aa13cb \
  --with github.com/lucaslorentz/caddy-docker-proxy/v2@v2.13.1 \
  --with github.com/hslatman/caddy-crowdsec-bouncer/http@v0.14.1 \
  --with github.com/hslatman/caddy-crowdsec-bouncer/appsec@v0.14.1 \
  --replace go.mongodb.org/mongo-driver=go.mongodb.org/mongo-driver@v1.17.7 \
  --replace go.opentelemetry.io/otel/exporters/otlp/otlptrace=go.opentelemetry.io/otel/exporters/otlp/otlptrace@v1.46.0 \
  --replace go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc=go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc@v1.46.0 \
  --replace go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp=go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp@v1.46.0 \
  --replace go.opentelemetry.io/otel/sdk=go.opentelemetry.io/otel/sdk@v1.46.0 \
  --replace golang.org/x/net=golang.org/x/net@v0.60.0 \
  --replace golang.org/x/crypto=golang.org/x/crypto@v0.57.0 \
  --replace golang.org/x/text=golang.org/x/text@v0.42.0 \
  --replace google.golang.org/grpc=google.golang.org/grpc@v1.83.2

FROM caddy:2-alpine@sha256:d8542f48d34a9cf4e4c11a478865229840e87e4c96ea3f439101f31a5d35f75f

RUN apk add --no-cache bash

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
COPY entrypoint.sh /entrypoint.sh

# File capabilities inherited from the base otherwise make exec fail when the
# discovery controller drops all capabilities. The serving container receives
# NET_BIND_SERVICE explicitly through Compose instead.
RUN setcap -r /usr/bin/caddy && chmod +x /entrypoint.sh

ARG CADDY_COMMIT=719db53e946181dd10a9aae36721c3251f7f8dc1
LABEL io.yusoofsh.upstream.revision="${CADDY_COMMIT}"

CMD ["/entrypoint.sh"]
