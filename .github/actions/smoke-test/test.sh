#!/bin/bash
TEMPLATE_ID="$1"
set -e

SRC_DIR="/tmp/${TEMPLATE_ID}"
echo "Running Smoke Test"

ID_LABEL="test-container=${TEMPLATE_ID}"
devcontainer exec --workspace-folder "${SRC_DIR}" --id-label ${ID_LABEL} /bin/sh -c 'set -e && if [ -f "test-project/test.sh" ]; then cd test-project && if [ "$(id -u)" = "0" ]; then chmod +x test.sh; else sudo chmod +x test.sh; fi && ./test.sh; else ls -a; fi'

# Clean up. This Template is a Docker Compose project, so tearing down only the
# labelled dev container would leave the egress sidecar and its networks behind.
# Resolve the Compose project from the dev container and bring the whole stack down.
COMPOSE_PROJECT=$(docker container ls -f "label=${ID_LABEL}" --format '{{.Label "com.docker.compose.project"}}' | head -n 1)
if [ -n "${COMPOSE_PROJECT}" ] ; then
    echo "(*) Tearing down Compose project '${COMPOSE_PROJECT}'"
    docker compose -p "${COMPOSE_PROJECT}" down --volumes --remove-orphans || true
else
    docker rm -f $(docker container ls -f "label=${ID_LABEL}" -q) || true
fi

rm -rf "${SRC_DIR}"
