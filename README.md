# Dev Container Templates

A collection of [Dev Container Templates](https://containers.dev/implementors/templates/), published to GitHub Container Registry.

## Templates

| Template | Version | Description |
|---|---|---|
| [`egress-firewall`](./src/egress-firewall) | `0.0.1` | A dev container that can only reach an explicit allowlist of hosts, enforced by a Squid sidecar and a routeless internal network. |

> **Everything here is 0.x and experimental.** While a Template's major version
> is `0`, expect breaking changes between releases — service and network names,
> file layout, options, and enforcement mechanisms may all change without a
> deprecation path. Pin the version you apply rather than tracking `latest`.
> A `1.0.0` release marks the point at which a Template's layout is stable.

## Using a template

In VS Code: **Dev Containers: New Dev Container…** → **Show All Definitions…** and enter

```
ghcr.io/olibutzki/devcontainer-templates/egress-firewall:0.0.1
```

Or with the [devcontainer CLI](https://github.com/devcontainers/cli):

```bash
devcontainer templates apply \
  --template-id ghcr.io/olibutzki/devcontainer-templates/egress-firewall:0.0.1 \
  --workspace-folder .
```

## `egress-firewall` in one paragraph

Running a coding agent in a dev container means running a semi-autonomous
process with your full network reach. This template replaces that with an
explicit, reviewable allowlist: the dev container sits on a Docker network
declared `internal: true` and therefore has **no default route to the
internet**, and a Squid sidecar dual-homed onto that network and a normal
bridge network is the only way out. Squid denies by default and permits only
the hosts in `allowed-domains.txt`. HTTPS is filtered on the hostname in the
`CONNECT` request and tunnelled without decryption, so nothing needs to trust a
new CA.

The distinction that matters: `HTTP_PROXY` is not the control. The absent route
is. A process that unsets the proxy variables does not gain unrestricted
access — it gains no access. What the template does *not* cover (build-time
Feature downloads, DNS as a residual channel, domain- rather than path-level
granularity) is documented honestly in
[`src/egress-firewall/.devcontainer/egress/README.md`](./src/egress-firewall/.devcontainer/egress/README.md).

## Repository layout

```
├── src/
│   └── egress-firewall/
│       ├── devcontainer-template.json    # metadata + the squidImage option
│       ├── NOTES.md                      # prose merged into the generated README
│       └── .devcontainer/                # what lands in the user's repo
│           ├── devcontainer.json
│           ├── docker-compose.yml
│           └── egress/
│               ├── squid.conf
│               ├── allowed-domains.txt
│               ├── verify-egress.sh
│               └── README.md
├── test/
│   ├── egress-firewall/test.sh
│   └── test-utils/test-utils.sh
└── .github/
    ├── actions/smoke-test/
    └── workflows/
```

## Developing

Test a template locally (requires Docker and Node):

```bash
./.github/actions/smoke-test/build.sh egress-firewall
./.github/actions/smoke-test/test.sh  egress-firewall
```

`build.sh` copies the template to `/tmp/<id>`, substitutes each option's
`default` for its `${templateOption:…}` placeholder, drops the contents of
`test/<id>/` into `test-project/`, and runs `devcontainer up`. `test.sh` then
executes `test-project/test.sh` inside the container and tears the Compose
stack down.

CI runs the same scripts on pull requests that touch a template
(`.github/workflows/test-pr.yaml`). Publishing is manual:
run the **Release Dev Container Templates** workflow, which pushes to GHCR and
opens a PR with regenerated documentation.

## License

[MIT](./LICENSE)
