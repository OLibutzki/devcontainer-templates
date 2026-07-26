
# Dev Container with Squid Egress Firewall (egress-firewall)

EXPERIMENTAL (0.x — expect breaking changes between releases). A dev container that can only reach an explicit allowlist of hosts. All traffic leaves through a Squid sidecar; the dev container itself has no route to the internet, so processes that ignore the proxy get no connectivity rather than unrestricted access. Intended for running coding agents under a reviewable network policy.

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| squidImage | Container image for the Squid egress sidecar (pin to a digest for a reproducible policy): | string | ubuntu/squid:latest |

> **Experimental — 0.x.** This Template is at `0.0.1`. While the major version
> is `0`, anything may change in a breaking way between releases: service and
> network names, the location and format of `allowed-domains.txt`, the Template
> options, and the enforcement mechanism itself. Pin the version you apply
> (`...egress-firewall:0.0.1`) rather than tracking `latest`, and re-read this
> page before upgrading. The first `1.0.0` release will mark the point at which
> the layout is considered stable.

## What you get

Two services in `.devcontainer/docker-compose.yml`:

- **`dev`** — your dev container, on a Docker network declared `internal: true`. Docker gives it no default route, so there is no way out except the proxy.
- **`egress`** — a Squid sidecar, dual-homed onto that internal network and a normal bridge network. Default deny; allows only the hosts in `.devcontainer/egress/allowed-domains.txt`. HTTPS is filtered on the CONNECT hostname and then tunnelled without decryption, so there is no CA to install and no TLS stack to placate.

Setting `HTTP_PROXY` is not what restricts the container — the missing route is. A process that unsets the proxy variables does not escape the allowlist; it loses the only path that works.

The dev container itself is deliberately unopinionated: a plain `mcr.microsoft.com/devcontainers/base:trixie` image, hardcoded in `docker-compose.yml`. Swap it for whatever your project needs and add your own Features, extensions and lifecycle commands — nothing in the egress policy depends on the base image.

## Using it

Edit `.devcontainer/egress/allowed-domains.txt` (one host per line; a leading dot matches subdomains), then reload:

```bash
docker compose -f .devcontainer/docker-compose.yml restart egress
```

To see what got blocked:

```bash
docker compose -f .devcontainer/docker-compose.yml logs egress | grep TCP_DENIED
```

To confirm the firewall is enforcing rather than merely configured:

```bash
bash .devcontainer/egress/verify-egress.sh
```

## Know the boundary

Dev Container **Features** and image layers are downloaded over the *host* network before the restricted container exists, so they are **not** filtered. The allowlist covers what runs inside the started container.

There is no SSH, no ICMP and no arbitrary TCP — only HTTP/HTTPS through the proxy. DNS resolution still works via Docker's embedded resolver, which remains a residual channel this setup does not close. Full details and the rest of the limitations are in `.devcontainer/egress/README.md`, which ships with the template.


---

_Note: This file was auto-generated from the [devcontainer-template.json](https://github.com/OLibutzki/devcontainer-templates/blob/main/src/egress-firewall/devcontainer-template.json).  Add additional notes to a `NOTES.md`._
