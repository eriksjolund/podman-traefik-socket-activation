# HTTP/3 example

> [!IMPORTANT]
> This example does not work with the official container image docker.io/traefik/traefik
> because that container does not yet include https://github.com/traefik/traefik/pull/11848
> which fixes the issue https://github.com/traefik/traefik/issues/11805
> The example should work if you build the container image from https://github.com/traefik/traefik/tree/v3.4

Requirements:

* podman 5.2.0 or later (needed for [`NetworkAlias=`](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html#networkalias)). Not strictly needed for this example but podman 5.3.0 or later is recommended because then `AddHost=postgres.example.com:host-gateway`, `host.containers.internal` or `host.docker.internal` could be used to let a container on the custom network connect to a service that is listening on the host's main network interface. For details, see [Outbound TCP/UDP connections to the host's main network interface (e.g eth0)](https://github.com/eriksjolund/podman-networking-docs?tab=readme-ov-file#outbound-tcpudp-connections-to-the-hosts-main-network-interface-eg-eth0)

* `ip_unprivileged_port_start` ≤ 80

   Verify that [`ip_unprivileged_port_start`](https://github.com/eriksjolund/podman-networking-docs#configure-ip_unprivileged_port_start) is less than or equal to 80
   ```
   $ cat /proc/sys/net/ipv4/ip_unprivileged_port_start
   80
   ```

Design goal:
The traefik container serves HTTP/3 on the socket-activated sockets.
The traefik container also creates listening sockets on the custom network "mynet" and serves HTTP/3.

socket-activated sockets:
web
websecure

sockets created on the custom network
web2
websecure2

1. Create directory
   ```
   imagedir=$(mktemp -d)
   ```
1. Prepare container images.
   ```
   bash prepare-images.bash $imagedir
   ```
2. This step will be removed in the future when https://github.com/traefik/traefik/issues/11805 has been fixed.
   Build the container image docker.io/traefik/traefik from https://github.com/eriksjolund/traefik/tree/fix-issue-11805-v2
   with docker and save it to $imagedir/traefik.oci
   ```
   docker save -o "$imagedir/traefik.oci" traefik/traefik
   ```
   (This step makes it easier to run the installation procedure for a new user because we can reuse
   a previously built container image)
3. Set up quadlets and start the services
   ```
   bash install.bash $imagedir
   ```
4. Run curl
   ```
   bash run.bash
   ```
   The following output is printed
   ```
      _________ test HTTP/3 _________
   1. connect from inside the custom network and use HTTP/3
   Hostname: 4fa971b9a071
   IP: 127.0.0.1
   IP: ::1
   IP: 10.89.0.2
   IP: fe80::e0e1:64ff:fe11:e15e
   RemoteAddr: 10.89.0.86:46126
   GET / HTTP/1.1
   Host: whoami
   User-Agent: curl/8.14.1
   Accept: */*
   Accept-Encoding: gzip
   X-Forwarded-For: 10.89.0.87
   X-Forwarded-Host: whoami.example.com
   X-Forwarded-Port: 443
   X-Forwarded-Proto: https
   X-Forwarded-Server: 8d37888ea4ac
   X-Real-Ip: 10.89.0.87


   2. connect from outside the custom network to the socket-activated sockets and use HTTP/3
   Hostname: 4fa971b9a071
   IP: 127.0.0.1
   IP: ::1
   IP: 10.89.0.2
   IP: fe80::e0e1:64ff:fe11:e15e
   RemoteAddr: 10.89.0.86:46126
   GET / HTTP/1.1
   Host: whoami
   User-Agent: curl/8.14.1
   Accept: */*
   Accept-Encoding: gzip
   X-Forwarded-For: 10.0.2.15
   X-Forwarded-Host: whoami.example.com
   X-Forwarded-Port: 443
   X-Forwarded-Proto: https
   X-Forwarded-Server: 8d37888ea4ac
   X-Real-Ip: 10.0.2.15


   _________ test HTTP2 __________
   3. connect from inside the custom network and use HTTP2
   Hostname: 4fa971b9a071
   IP: 127.0.0.1
   IP: ::1
   IP: 10.89.0.2
   IP: fe80::e0e1:64ff:fe11:e15e
   RemoteAddr: 10.89.0.86:46126
   GET / HTTP/1.1
   Host: whoami
   User-Agent: curl/8.14.1
   Accept: */*
   Accept-Encoding: gzip
   X-Forwarded-For: 10.89.0.88
   X-Forwarded-Host: whoami.example.com
   X-Forwarded-Port: 443
   X-Forwarded-Proto: https
   X-Forwarded-Server: 8d37888ea4ac
   X-Real-Ip: 10.89.0.88


   4. connect from inside the custom network to the socket-activated sockets and use HTTP2
   Hostname: 4fa971b9a071
   IP: 127.0.0.1
   IP: ::1
   IP: 10.89.0.2
   IP: fe80::e0e1:64ff:fe11:e15e
   RemoteAddr: 10.89.0.86:46126
   GET / HTTP/1.1
   Host: whoami
   User-Agent: curl/8.14.1
   Accept: */*
   Accept-Encoding: gzip
   X-Forwarded-For: 10.0.2.15
   X-Forwarded-Host: whoami.example.com
   X-Forwarded-Port: 443
   X-Forwarded-Proto: https
   X-Forwarded-Server: 8d37888ea4ac
   X-Real-Ip: 10.0.2.15


   _________ test HTTP ___________
   5. connect from inside the custom network and use HTTP
   Moved Permanently

   6. connect from outside the custom network to the socket-activated sockets and use HTTP
   Moved Permanently

   7. connect from inside the custom network directly to the whoami container and use HTTP
   Hostname: 4fa971b9a071
   IP: 127.0.0.1
   IP: ::1
   IP: 10.89.0.2
   IP: fe80::e0e1:64ff:fe11:e15e
   RemoteAddr: 10.89.0.91:33124
   GET / HTTP/1.1
   Host: whoami.example.com
   User-Agent: curl/8.14.1
   Accept: */*
   
   ```

## Discussion

You may wonder why the container image _localhost/curl_ is built and used when testing the socket-activated sockets.
Another simpler alternative would have been to use a curl executable installed on the host,
but my host (Fedora CoreOS) did not have a curl version with HTTP3 support.
To work around this problem I built a container image _localhost/curl_ that has curl with HTTP3 support.

For example this command connects to the socket-activated sockets and uses HTTP/3

```
podman run --rm \
           -v ~/ca.crt:/root/ca.crt:Z \
           --add-host whoami.example.com:host-gateway \
	   localhost/curl curl --cacert /root/ca.crt --http3-only -s https://whoami.example.com
```

By using the option `--add-host whoami.example.com:host-gateway` the connection goes to the host's main network interface.
In other words, traefik's socket-activated sockets will be used.
