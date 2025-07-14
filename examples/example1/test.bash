#!/bin/bash

set -o errexit
set -o nounset

imagedir=$1
sleep=$2

mkdir -p ~/.config/systemd/user
mkdir -p ~/.config/containers/systemd

cp http.socket ~/.config/systemd/user
cp https.socket ~/.config/systemd/user

cp traefik.container ~/.config/containers/systemd
cp whoami.container ~/.config/containers/systemd
cp mynet.network ~/.config/containers/systemd

for i in docker.io/library/traefik docker.io/traefik/whoami
  do
    if ! podman image exists $i
    then
	podman image load -i "$imagedir/$i"
    fi
done

systemctl --user daemon-reload

systemctl --user stop whoami.service || true
systemctl --user reset-failed whoami.service || true
systemctl --user stop traefik.service  || true
systemctl --user reset-failed traefik.service || true

systemctl --user start podman.socket
systemctl --user start http.socket
systemctl --user start https.socket

shift
shift
while(($#)) ; do
  systemctl --user start $1
  shift
done

sleep $sleep
curl --resolve whoami.example.com:80:127.0.0.1 --connect-timeout 2 http://whoami.example.com
