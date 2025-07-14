#!/bin/bash

set -o errexit
set -o nounset

imagedir=$1

mkdir -p "$imagedir/docker.io/traefik"
mkdir -p "$imagedir/docker.io/library"

podman pull docker.io/traefik/whoami
podman save --format oci-archive -o "$imagedir/docker.io/traefik/whoami" docker.io/traefik/whoami

podman pull docker.io/library/traefik
podman save --format oci-archive -o "$imagedir/docker.io/library/traefik" docker.io/library/traefik

chmod -R 755 "$imagedir"
