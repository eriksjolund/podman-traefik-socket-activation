# HTTP/3 example

Requirement:

```
$ cat /proc/sys/net/ipv4/ip_unprivileged_port_start
80
```
Make sure the number is 80 or less.

Design goal:
The traefik container serves HTTP/3 on the socket-activated sockets.
The traefik container also creates listening sockets on the custom network "mynet" and serves HTTP/3.

socket-activated sockets:
web
websecure

sockets created on the custom network (currently only used for `variant=http3-inside`)
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
2. Set shell variable `variant` to either `http3-outside` or `http3-inside`, for example
   ```
   variant=http3-outside
   ```
3. Set up quadlets and start the services
   ```
   bash install.bash $imagedir $variant
   ```
4. Run curl
   ```
   bash ./${variant}/run.bash
   ```

Status:

### status when using `variant=http3-outside`

HTTP/3 works when accessing traefik from the outside.

### status when using `variant=http3-inside`

HTTP/3 works when accessing traefik from the inside. HTTP2 works when accessing traefik from the outside.
