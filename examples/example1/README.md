return to [main page](../..)

## Example 1

``` mermaid
graph TB

    a1[curl] -.->a2[traefik container reverse proxy]
    a2 -->|"for http://mynginx"| a3["nginx container"]
```

Set up a systemd user service _example1.service_ for the user _test_ where rootless podman is running the container image _localhost/traefik_.
Configure _socket activation_ for TCP port 8080.

1. Log in to user _test_
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
1. Clone git repo
   ```
   git clone https://github.com/eriksjolund/podman-traefik-socket-activation.git
   ```
1. Install the container unit files
   ```
   cp podman-traefik-socket-activation/examples/example1/*.container \
      ~/.config/containers/systemd
   ```
1. Install the network unit file
   ```
   cp podman-traefik-socket-activation/examples/example1/mynet.network \
      ~/.config/containers/systemd
   ```
1. Install the socket unit file
   ```
   cp podman-traefik-socket-activation/examples/example1/mytraefik.socket \
      ~/.config/systemd/user
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
1. Start the nginx container
   ```
   systemctl --user start mynginx.service
   ```
1. Start the traefik socket
   ```
   systemctl --user start mytraefik.socket
   ```
1. Download a web page __http://mynginx__ from the traefik
   container and see that the request is proxied to the container _mynginx_.
   ```
   $ curl -s --resolve mynginx:8080:127.0.0.1 http://mynginx:8080 | head -4
   <!DOCTYPE html>
   <html>
   <head>
   <title>Welcome to nginx!</title>
   ```
   Instead of using the curl __--resolve__ option, it is also possible
   to set the HTTP header directly to achieve the same HTTP request
   ```
   $ curl -s --header "Host: mynginx" http://127.0.0.1:8080 | head -4
   <!DOCTYPE html>
   <html>
   <head>
   <title>Welcome to nginx!</title>
   ```

### Discussion

The default configuration for _ip_unprivileged_port_start_ was used

```
$ cat /proc/sys/net/ipv4/ip_unprivileged_port_start
1024
```
TCP port 8080 is thus an unprivileged port.

To use the method described in Example 1 for TCP port 80 instead, you need to
modify the Linux kernel setting _ip_unprivileged_port_start_ to the number
80 or less.

Create the file  _/etc/sysctl.d/99-unprivileged-port.conf_ with the contents
```
net.ipv4.ip_unprivileged_port_start=80
```
Reload sysctl configuration
```
sudo sysctl --system
```
Note that any user on the system could then bind to port 80 if it is unused.
