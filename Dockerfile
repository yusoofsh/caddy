FROM caddy:builder-alpine AS builder

RUN GOMAXPROCS=1 GOMEMLIMIT=900MiB xcaddy build \
  --with github.com/caddy-dns/cloudflare \
  --with github.com/WeidiDeng/caddy-cloudflare-ip \
  --with github.com/lucaslorentz/caddy-docker-proxy/v2 \
  --with github.com/hslatman/caddy-crowdsec-bouncer/http \
  --with github.com/hslatman/caddy-crowdsec-bouncer/appsec

FROM caddy:alpine

RUN apk add --no-cache bash

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
