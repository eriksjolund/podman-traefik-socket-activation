# podman-traefik-socket-activation

This demo shows how to run a socket-activated traefik container with Podman.
See also the tutorials [Podman socket activation](https://github.com/containers/podman/blob/main/docs/tutorials/socket_activation.md) and
[podman-nginx-socket-activation](https://github.com/eriksjolund/podman-nginx-socket-activation).

Overview of the examples

| Example | Type of service | Port | Using quadlet | rootful/rootless podman | Comment |
| --      | --              |   -- | --      | --   | --  |
| [Example 1](examples/example1) | systemd user service | 8080 | yes | rootless podman | |

### Advantages of using rootless Podman with socket activation

See https://github.com/eriksjolund/podman-nginx-socket-activation?tab=readme-ov-file#advantages-of-using-rootless-podman-with-socket-activation

### Discussion about SELinux

When using the traefik option __--providers.docker__, traefik needs access to a unix socket
that provides the Docker API. By default the path to the unix socket is  _/var/run/docker.sock_.
SELinux will by default block access to the file.

Currently, the problem is worked around by disabling SELinux for the traefik container.

The quadlet unit file contains this line:
```
SecurityLabelDisable=true
```

Another workaround could have been to bind-mount the unix socket with the `:z` option,
but that would change the file context of the unix socket which might cause problems for
other programs.

See also
https://bugzilla.redhat.com/show_bug.cgi?id=1495053#c2
