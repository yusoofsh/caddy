# ADR-001: Isolate Lighthouse ingress without reducing administrator capabilities

## Status

Accepted and deployed on 2026-09-26; limited to Lighthouse.

## Context

The public ingress shared Docker discovery access, creating a path from an
Internet-facing process toward sensitive container metadata. The user requires
full SSH, AWS/SSM, Dokploy, NetBird, email, WhatsApp and DNS functionality.
Removing administrative tools or moving all services behind an interactive
identity wall would break the intended integrations.

## Decision

Run Docker discovery in a non-root, read-only Caddy controller on a dedicated
socket network. Run the serving Caddy process without Docker socket access.
Restrict the control bridge to the controller/server pair. A dedicated firewall
also covers mesh-forwarded and host-network traffic; root/sudo retains the
server's recovery API. Do not flush or replace existing mesh/namespace rules.

Keep application bearer/OAuth authentication, explicit full-admin consent,
exact approved HTTPS callbacks and native loopback callbacks. Persist token
digests, not raw token map keys. Keep all administrative provider schemas and
callable tools. Protect browser password checking with failure-based throttling
where implemented, without throttling valid bearer streams.

## Alternatives considered

- Removing administrative tools: rejected because it violates the required
  functionality and does not fix credential exposure.
- Mounting a read-only Docker socket in ingress: rejected because filesystem
  read-only does not make the Docker API read-only.
- A Docker GET-only proxy shared with ingress: reduced mutation risk but still
  exposes discovery metadata; isolate its network as well.
- Mandatory interactive edge login on every MCP route: rejected because it
  changes machine-client authentication and breaks existing integrations.

## Consequences and evidence

Exact HTTP server configuration was compared before/after the Caddy migration.
Controller discovery, ingress-to-proxy denial, app/non-root denial of the
control API and root recovery access were checked live. Infrastructure
registrations and upstream tool catalogs were retained. Full-admin access
still has a large intentional blast radius: a stolen authorized credential can
exercise those tools. This is a single-administrator design, not tenant isolation.

The controller and ingress still require certificate/WAF credentials where
runtime placeholders resolve. Token rotation, tested backups and reviewed
dependency updates remain necessary. A future subnet change must update the
Compose addresses, GOWA trusted proxy and dedicated firewall together.
