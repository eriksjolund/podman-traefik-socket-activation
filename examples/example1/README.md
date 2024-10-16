return to [main page](../..)

## Example 1

``` mermaid
graph TB

    a1[curl] -.->a2[traefik container reverse proxy]
    a2 -->|"for http&colon;//whoami"| a3["whoami container"]
```

Set up a systemd user service _example1.service_ for the user _test_ where rootless podman is running the container image _localhost/traefik_.
Configure _socket activation_ for TCP ports 80 and 443.

1. Verify that unprivileged users are allowed to open port numbers 80 and above.
   Run the command
   ```
   cat /proc/sys/net/ipv4/ip_unprivileged_port_start
   ```
   Make sure the number printed is not higher than 80. To configure the number,
   see https://rootlesscontaine.rs/getting-started/common/sysctl/#allowing-listening-on-tcp--udp-ports-below-1024
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
1. Download a web page __http://whoami__ from the traefik
   container and see that the request is proxied to the container _whoami_.
   Resolve _whoami_ to _127.0.0.1_.
   ```
   $ curl -s --resolve whoami:80:127.0.0.1 http://whoami:80
   Hostname: 0315603f400d
   IP: 127.0.0.1
   IP: ::1
   IP: 10.89.0.2
   IP: fe80::18fe:c3ff:fe9e:d8ee
   RemoteAddr: 10.89.0.3:37168
   GET / HTTP/1.1
   Host: whoami
   User-Agent: curl/8.6.0
   Accept: */*
   Accept-Encoding: gzip
   X-Forwarded-For: 127.0.0.1
   X-Forwarded-Host: whoami
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
1. Download a web page __http://whoami__ from the traefik
   container and see that the request is proxied to the container _whoami_.
   Resolve _whoami_ to the IP address of the main network interface.
   Run the command
   ```
   curl --resolve whoami:80:192.168.10.108 http://whoami
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
   Host: whoami
   User-Agent: curl/8.6.0
   Accept: */*
   Accept-Encoding: gzip
   X-Forwarded-For: 192.168.10.108
   X-Forwarded-Host: whoami
   X-Forwarded-Port: 80
   X-Forwarded-Proto: http
   X-Forwarded-Server: 046d07b93fc9
   X-Real-Ip: 192.168.10.108
   ```
   __result:__ The IPv4 address of the main network interface, _192.168.10.108_, matches the IPv4 address
   of _X-Forwarded-For_ and _X-Real-Ip_
1. From another computer download a web page __http://whoami__ from the traefik
   container and see that the request is proxied to the container _whoami_.
   ```
   curl --resolve whoami:80:192.168.10.108 http://whoami
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
   Host: whoami
   User-Agent: curl/8.7.1
   Accept: */*
   Accept-Encoding: gzip
   X-Forwarded-For: 192.168.10.161
   X-Forwarded-Host: whoami
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

### Using `Internal=true`

The file [_mynet.network_](mynet.network) currently contains

```
[Network]
Internal=true
```

The line

```
Internal=true
```

prevents containers on the network to connect to the internet.
To allow Containers on the network to download files from the internet you would need to remove the line.
