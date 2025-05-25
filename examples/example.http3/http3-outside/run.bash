#!/bin/bash

# The curl version available on the host might not have been built with HTTP/3 support.
# Use curl container instead with HTTP/3 support instead. The container image is
# built from docker.io/library/debian:testing).

echo _________ test HTTP/3 _________
echo 1. connect from outside the custom network and use HTTP/3
podman run --rm  -v ~/ca.crt:/root/ca.crt:Z --add-host whoami.example.com:host-gateway localhost/curl curl --cacert /root/ca.crt --http3-only -s https://whoami.example.com

echo
echo _________ test HTTP2 __________
echo 2. connect from outside the custom network and use HTTP2
podman run --rm -v ~/ca.crt:/root/ca.crt:Z --add-host whoami.example.com:host-gateway localhost/curl curl --cacert /root/ca.crt -s https://whoami.example.com

echo
echo _________ test HTTP ___________
echo 3. connect from outside the custom network and use HTTP
podman run --rm --add-host whoami.example.com:host-gateway localhost/curl curl -v -s http://whoami.example.com
