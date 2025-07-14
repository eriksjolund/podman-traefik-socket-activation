return to [main page](../..)

## Example 1

``` mermaid
graph TB

    a1[curl] -.->a2[traefik container reverse proxy]
    a2 -->|"for http&colon;//whoami.example.com"| a3["whoami container"]
```

Set up a systemd user service _example1.service_ for the user _test_ where rootless podman is running the container image _localhost/traefik_.
Configure _socket activation_ for TCP ports 80 and 443.


Requirements:

* podman 4.4.0 or later (needed for using [quadlets](https://www.redhat.com/en/blog/quadlet-podman)). Not strictly needed for this example but podman 5.3.0 or later is recommended because then `AddHost=postgres.example.com:host-gateway`, `host.containers.internal` or `host.docker.internal` could be used to let a container on the custom network connect to a service that is listening on the host's main network interface. For details, see [Outbound TCP/UDP connections to the host's main network interface (e.g eth0)](https://github.com/eriksjolund/podman-networking-docs?tab=readme-ov-file#outbound-tcpudp-connections-to-the-hosts-main-network-interface-eg-eth0)

* `ip_unprivileged_port_start` ≤ 80

   Verify that [`ip_unprivileged_port_start`](https://github.com/eriksjolund/podman-networking-docs#configure-ip_unprivileged_port_start) is less than or equal to 80
   ```
   $ cat /proc/sys/net/ipv4/ip_unprivileged_port_start
   80
   ```

1. Create a test user
   ```
   sudo useradd test
   ```
1. Open a shell for user _test_
   ```
   sudo machinectl shell --uid=test
   ```
1. Optional step: enable lingering to avoid services from being stopped when the user _test_ logs out.
   ```
   loginctl enable-linger test
   ```
1. Create directories
   ```
   mkdir -p ~/.config/systemd/user
   mkdir -p ~/.config/containers/systemd
   ```
1. Pull the traefik container image
   ```
   podman pull docker.io/library/traefik
   ```
1. Pull the _whoami_ container image
   ```
   podman pull docker.io/traefik/whoami
   ```
1. Clone git repo
   ```
   git clone https://github.com/eriksjolund/podman-traefik-socket-activation.git
   ```
1. Install the container unit files
   ```
   cp podman-traefik-socket-activation/examples/example1/*.container \
      ~/.config/containers/systemd/
   ```
1. Install the network unit file
   ```
   cp podman-traefik-socket-activation/examples/example1/mynet.network \
      ~/.config/containers/systemd/
   ```
1. Install the socket unit files
   ```
   cp podman-traefik-socket-activation/examples/example1/*.socket \
      ~/.config/systemd/user/
   ```
1. Reload the systemd user manager
   ```
   systemctl --user daemon-reload
   ```
   This triggers __systemd__ to execute the generator `/usr/lib/systemd/user-generators/podman-user-generator`
   that will generate systemd user service unit files out of the quadlet files (that is the files
   having filenames ending with _.container_, _.volume_ and _.network_).
   The generated files are written to the directory `/run/user/<USERID>/systemd/generator`.
   For details, see [_podman-systemd.unit(5)_](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)
   and [_systemd.generator(7)_](https://www.freedesktop.org/software/systemd/man/latest/systemd.generator.html).
1. Start the podman socket. (The path to the unix socket is `$XDG_RUNTIME_DIR/podman/podman.sock` which
   would for example expand to _/run/user/1003/podman/podman.sock_ if the UID of the user _test_ is 1003)
   ```
   systemctl --user start podman.socket
   ```
1. Start the socket for TCP port 80
   ```
   systemctl --user start http.socket
   ```
1. Start the socket for TCP port 443
   ```
   systemctl --user start https.socket
   ```
1. Start the _whoami_ container
   ```
   systemctl --user start whoami.service
   ```
1. Start the _traefik_ container
   ```
   systemctl --user start traefik.service
   ```
   This step was added due to traefik issue [7347](https://github.com/traefik/traefik/issues/7347).
1. Wait a few seconds
   ```
   sleep 3
   ```
   This is also related to traefik issue [7347](https://github.com/traefik/traefik/issues/7347). Traefik sends `READY=1` before traefik is ready.
1. Download a web page __http://whoami.example.com__ from the traefik
   container and see that the request is proxied to the container _whoami_.
   Resolve _whoami.example.com_ to _127.0.0.1_.
   ```
   $ curl -s --resolve whoami.example.com:80:127.0.0.1 http://whoami.example.com:80
   Hostname: 0315603f400d
   IP: 127.0.0.1
   IP: ::1
   IP: 10.89.0.2
   IP: fe80::18fe:c3ff:fe9e:d8ee
   RemoteAddr: 10.89.0.3:37168
   GET / HTTP/1.1
   Host: whoami.example.com
   User-Agent: curl/8.6.0
   Accept: */*
   Accept-Encoding: gzip
   X-Forwarded-For: 127.0.0.1
   X-Forwarded-Host: whoami.example.com
   X-Forwarded-Port: 80
   X-Forwarded-Proto: http
   X-Forwarded-Server: 046d07b93fc9
   X-Real-Ip: 127.0.0.1
   ```
   __result:__ The IPv4 address  127.0.0.1 matches the IP address of _X-Forwarded-For_ and _X-Real-Ip_
1. Check the IPv4 address of the main network interface.
   Run the command
   ```
   hostname -I
   ```
   The following output is printed
   ```
   192.168.10.108 192.168.39.1 192.168.122.1 fd25:c7f8:948a:0:912d:3900:d5c4:45ad
   ```
   __result:__ The IPv4 address of the main network interface is _192.168.10.108_ (the address furthest to the left)
1. Download a web page __http://whoami.example.com__ from the traefik
   container and see that the request is proxied to the container _whoami_.
   Resolve _whoami.example.com_ to the IP address of the main network interface.
   Run the command
   ```
   curl --resolve whoami.example.com:80:192.168.10.108 http://whoami.example.com
   ```
   The following output is printed
   ```
   Hostname: 0315603f400d
   IP: 127.0.0.1
   IP: ::1
   IP: 10.89.0.2
   IP: fe80::18fe:c3ff:fe9e:d8ee
   RemoteAddr: 10.89.0.3:37168
   GET / HTTP/1.1
   Host: whoami.example.com
   User-Agent: curl/8.6.0
   Accept: */*
   Accept-Encoding: gzip
   X-Forwarded-For: 192.168.10.108
   X-Forwarded-Host: whoami.example.com
   X-Forwarded-Port: 80
   X-Forwarded-Proto: http
   X-Forwarded-Server: 046d07b93fc9
   X-Real-Ip: 192.168.10.108
   ```
   __result:__ The IPv4 address of the main network interface, _192.168.10.108_, matches the IPv4 address
   of _X-Forwarded-For_ and _X-Real-Ip_
1. From another computer download a web page __http://whoami.example.com__ from the traefik
   container and see that the request is proxied to the container _whoami_.
   ```
   curl --resolve whoami.example.com:80:192.168.10.108 http://whoami.example.com
   ```
   The following output is printed
   ```
   Hostname: 0315603f400d
   IP: 127.0.0.1
   IP: ::1
   IP: 10.89.0.2
   IP: fe80::18fe:c3ff:fe9e:d8ee
   RemoteAddr: 10.89.0.3:42586
   GET / HTTP/1.1
   Host: whoami.example.com
   User-Agent: curl/8.7.1
   Accept: */*
   Accept-Encoding: gzip
   X-Forwarded-For: 192.168.10.161
   X-Forwarded-Host: whoami.example.com
   X-Forwarded-Port: 80
   X-Forwarded-Proto: http
   X-Forwarded-Server: 046d07b93fc9
   X-Real-Ip: 192.168.10.161
   ```
   Check the IP address of the other computer (which in this example runs macOS).
   In the macOS terminal run the command
   ```
   ipconfig getifaddr en0
   ```
   The following output is printed
   ```
   192.168.10.161
   ```
   __result:__ The IPv4 address of the other computer matches the IPv4 address of _X-Forwarded-For_ and _X-Real-Ip_
   
   __troubleshooting tip:__ If the curl command fails with `Connection timed out` or `Connection refused`,
   then there is probably a firewall blocking the connection. How to open up the firewall is beyond
   the scope of this tutorial.

### Using `Internal=true`

The file [_mynet.network_](mynet.network) currently contains

```
[Network]
Options=isolate=true
Internal=true
```

The line

```
Internal=true
```

prevents containers on the network to connect to the internet.
To allow Containers on the network to download files from the internet you would need to remove the line.
