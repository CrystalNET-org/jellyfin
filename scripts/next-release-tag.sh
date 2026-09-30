#!/bin/sh
# Prints the tag for releasing the current commit if the Jellyfin or
# grpc-ffmpeg version differs from the latest release, and nothing otherwise.
#
# Release tags are <Jellyfin version>-<n>, e.g. 10.11.11-1; n counts the
# releases of the same Jellyfin version.
set -eu

versions() { grep -E '^ARG (JELLYFIN|GRPC_FFMPEG)_VERSION=' | sort; }
current_version=$(sed -n 's/^ARG JELLYFIN_VERSION=//p' Dockerfile)
if [ -z "$current_version" ]; then
    echo "JELLYFIN_VERSION not found in Dockerfile" >&2
    exit 1
fi

# Latest release, ordered by Jellyfin version, then n
latest=$(git tag -l \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+-[0-9]+$' \
    | awk -F'[.-]' '{ print $1, $2, $3, $4, $0 }' \
    | sort -n -k1,1 -k2,2 -k3,3 -k4,4 \
    | tail -n 1 \
    | cut -d' ' -f5)

if [ -n "$latest" ]; then
    if [ "$(versions < Dockerfile)" = "$(git show "$latest:Dockerfile" 2>/dev/null | versions)" ]; then
        exit 0
    fi
    if [ "${latest%-*}" = "$current_version" ]; then
        echo "$current_version-$(( ${latest##*-} + 1 ))"
        exit 0
    fi
fi

echo "$current_version-1"
