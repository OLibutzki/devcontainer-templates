#!/bin/bash
cd $(dirname "$0")
source test-utils.sh

# An allowlisted host. Present in the Template's default allowed-domains.txt and
# a stable JSON endpoint, so a 200 here means the proxy really did tunnel it.
ALLOWED_URL="https://update.code.visualstudio.com/api/releases/stable"

# Deliberately absent from the allowlist.
BLOCKED_URL="https://example.com/"

# A literal IP, so this needs no DNS: it tests reachability, not resolution.
DIRECT_URL="https://1.1.1.1/"

check "proxy-env-is-set" bash -c '[ -n "$HTTPS_PROXY" ] && [ -n "$https_proxy" ]'

check "allowed-host-is-reachable" bash -c "curl -sSf -o /dev/null --max-time 30 '${ALLOWED_URL}'"

# Squid answers the CONNECT with 403, so curl exits non-zero.
check "blocked-host-is-refused" bash -c "! curl -sS -o /dev/null --max-time 30 '${BLOCKED_URL}'"

# The important one: with the proxy bypassed there must be no route out at all.
# If this ever starts passing, the `internal: true` network has been lost and the
# allowlist has become advisory rather than enforced.
check "no-direct-egress" bash -c "! curl -sS --noproxy '*' -o /dev/null --max-time 10 '${DIRECT_URL}'"

reportResults
