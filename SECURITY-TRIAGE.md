# Dependency triage (2026-09-26)

Keep raw scanner reports visible. A dependency match is not proof that its
vulnerable function is called by this executable.

## CVE-2026-44982 / GHSA-rw47-hm26-6wr7

The bouncer 0.14.1 depends on CrowdSec 1.6.3 API models. This advisory concerns
the CrowdSec AppSec server's `pkg/appsec.NewParsedRequestFromRequest` parser.
The Caddy plugin uses its own request adapter and sends the body to a separate
AppSec service; it does not embed that server as the WAF engine. The Lighthouse
AppSec engine was verified as 1.7.8, the advisory's fixed version.

Relevant upstream code:

- https://github.com/hslatman/caddy-crowdsec-bouncer/blob/v0.14.1/internal/core/appsec.go
- https://github.com/hslatman/caddy-crowdsec-bouncer/blob/v0.14.1/internal/bouncer/live.go
- https://github.com/crowdsecurity/crowdsec/security/advisories/GHSA-rw47-hm26-6wr7

Forcing the CrowdSec dependency to 1.7.8 breaks the bouncer's model API at build
time (`*string` versus `string`). Do not disable the WAF or use an unreviewed
source rewrite simply to remove a scanner match. Retain the compatible client,
keep the actual engine patched, and revisit when a compatible bouncer release
arrives. Review by 2026-10-26 or whenever either component changes.

## Other candidate findings

The Caddy builder carries these proposed replacements; the image build and
runtime checks, not static inspection, establish compatibility:

| Reported module | Reported | Build pin | Reachability / compatibility |
| --- | ---: | ---: | --- |
| `github.com/google/cel-go` | 0.28.1 | retained | 0.29.0 breaks Caddy 2.11.4's Interpretable API at compile time. Keep the medium finding visible; upgrade with a compatible Caddy release. Current routes do not use CEL expression matchers. |
| `go.mongodb.org/mongo-driver` | 1.17.0 | 1.17.7 | Transitive through the CrowdSec bouncer; this is the compatible 1.17 patch line and no Caddy source API is changed. |
| `go.opentelemetry.io/otel/exporters/otlp/otlplog/otlploggrpc` | 0.19.0 | retained | Forcing 0.21.0 breaks the current stdout log exporter's Value API at compile time. Keep the medium finding visible; do not enable OTLP log exporting before a compatible coordinated upgrade. |
| `go.opentelemetry.io/otel/exporters/otlp/otlptrace*` | 1.43.0 | 1.45.0 | Caddy's tracing integration uses stable OTel APIs; the trace, gRPC, and HTTP exporter modules are updated together. |
| `go.opentelemetry.io/otel/sdk` | 1.44.0 | 1.45.0 | Coordinated with the OTel root/metric/trace modules selected by the exporter graph. |
| `golang.org/x/crypto` | 0.55.0 | 0.56.0 | Fixes the reported SSH denial-of-service advisories; the builder is pinned to Go 1.26.8, which satisfies this module's Go 1.26 requirement. |

The `GO-2026-5932` match remains reported for `golang.org/x/crypto/openpgp`, an
unmaintained package with no supported fixed release. The Caddy source and its
enabled modules import bcrypt, argon2, cryptobyte, x509roots, and other supported
packages, but do not import `openpgp`; no source rewrite or blanket scanner
exception is warranted. Revisit if a dependency begins importing OpenPGP or if
the upstream module provides a supported replacement.

The Go toolchain, x/net, x/crypto, x/text, gRPC, MongoDB, and stable OTel
trace/SDK dependencies are explicitly patched in the Dockerfile. Re-scan the
final image digest after each change; a prior report is not evidence for a
rebuilt candidate. Release requires the pinned
workflow build to succeed, `go version -m /usr/bin/caddy` to show the expected
module versions, and a fresh final-image scan.
