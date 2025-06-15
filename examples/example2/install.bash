#!/bash

set -o errexit
set -o nounset

imagedir=$1

mkdir -p ~/.config/containers/systemd
mkdir -p ~/.config/systemd/user

cp http.socket ~/.config/systemd/user
cp https.socket ~/.config/systemd/user
cp traefik.container ~/.config/containers/systemd
cp whoami.container ~/.config/containers/systemd
cp mynet.network ~/.config/containers/systemd
cp traefik.yaml ~/
cp file.yaml ~/

for i in traefik.oci whoami.oci curl.oci; do
    podman image load -i "$imagedir/$i"
done

openssl genrsa -out ~/ca.key 4096
openssl req -x509 -new -nodes -key ~/ca.key -sha256 -days 365 -out ~/ca.crt -subj "/CN=root ca"
openssl genrsa -out ~/server.key 2048
openssl req -new -key ~/server.key -out ~/server.csr -subj "/CN=whoami.example.com"
openssl x509 -req -in ~/server.csr -CA ~/ca.crt -CAkey ~/ca.key -CAcreateserial -out ~/server.crt -days 365 -sha256

systemctl --user daemon-reload
systemctl --user start whoami.service
systemctl --user start http.socket
systemctl --user start https.socket
systemctl --user start traefik.service
