#!/bin/bash

set -o errexit
set -o nounset

imagedir=$1

podman build -t curl -f Containerfile.curl ./curl/
podman save --format oci-archive -o "$imagedir/curl.oci" localhost/curl

podman pull docker.io/traefik/whoami
podman save --format oci-archive -o "$imagedir/whoami.oci" docker.io/traefik/whoami

podman pull docker.io/library/traefik
podman save --format oci-archive -o "$imagedir/traefik.oci" docker.io/library/traefik

chmod -R 755 "$imagedir"

