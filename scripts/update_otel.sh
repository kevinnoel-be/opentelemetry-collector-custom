#!/bin/bash

set -euo pipefail

REPO_DIR="$( cd "$(dirname $( dirname "${BASH_SOURCE[0]}" ))" &> /dev/null && pwd )"
otelcol_version=${1:-}

if [[ -z "$otelcol_version" ]]; then
    echo "Usage: $0 <otel version>"
    exit 1
fi

if ! command -v yq >/dev/null 2>/dev/null; then
    echo "Requires yq v4 to be installed"
    exit 1
fi

echo "Updating to OpenTelemetry collector version: $otelcol_version"

echo "... updating Makefile"
sed -i "s/^OTELCOL_BUILDER_VERSION.*/OTELCOL_BUILDER_VERSION ?= ${otelcol_version}/" Makefile

manifests=$(find ${REPO_DIR}/distributions -type f -name otel-build.yaml)
for manifest in $manifests; do
    echo "... updating $manifest"

    otelcol_version="$otelcol_version" yq -i '
        with(.dist |
            .otelcol_version = strenv(otelcol_version) ;
            .version = strenv(otelcol_version)
        ) |
        with(.*[].gomod |
            . |= sub("(go\.opentelemetry\.io/collector.+\s)v.+", "${1}v" + strenv(otelcol_version)) ;
            . |= sub("(github\.com/open-telemetry/opentelemetry-collector-contrib.+\s)v.+", "${1}v" + strenv(otelcol_version))
        )
    ' "$manifest"
done

echo "Update done"
