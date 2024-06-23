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

### Build or pull the traefik container image

The traefik project is [planning](https://github.com/traefik/traefik/pull/10399#issuecomment-2133376924) to add _socket activation_ support in traefik v3.1.0 (which has not yet been released).

It's possible to try out the new _socket activation_ functionality by building
https://github.com/traefik/traefik/pull/10399

Sketchy instructions of how I built an arm64 traefik container (from PR 10399): <details><summary>Click me</summary>

(I have forgotten exactly which commands I ran. Most probably there are better ways of how to build a traefik container image. It would be nice to have a Containerfile and just
run `podman build .` but I couldn't find any)

1. Install Fedora CoreOS (stream: _next_). (I added some extra free disk space with `qemu-img resize fedora-coreos-40.20240616.1.0-qemu.aarch64.qcow2 +15G`)
1. Start the Fedora CoreOS VM and log in.
1. Install make
   ```
   sudo rpm-ostree install -A make
   ```
1. Download golang 1.22.4 from https://go.dev/doc/install
1. Install golang
   ```
   sudo sh -c "rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz"
   ```
1. Create user for building the container image
   ```
   sudo useradd test
   ```
1. Add to supplimentary group
   ```
   sudo usermod -aG docker test
   ```
1. Start the docker socket
   ```
   sudo systemctl start docker.socket
   ```
1. Log in to the _test_ user
   ```
   sudo machinectl shell --uid test
   ```
1. Clone traefik repo
   ```
   git clone https://github.com/traefik/traefik.git
   ```
1. Append this text
   ```
   export PATH=$PATH:/usr/local/go/bin
   export GOPATH=~/go
   export PATH=$PATH:$GOPATH/bin
   ```
   to the file _~/.bash_profile_
1. Source the updated Bash configuration
   ```
   source ~/.bash_profile
   ```
1. Change directory
   ```
   cd traefik
   ```
1. Modify the trafik sources according to this diff
   ```
   diff --git a/Makefile b/Makefile
   index b006ce68e..01c2b313f 100644
   --- a/Makefile
   +++ b/Makefile
   @@ -43,8 +43,8 @@ clean-webui:

    webui/static/index.html:
	   $(MAKE) build-webui-image
   -       docker run --rm -v "$(PWD)/webui/static":'/src/webui/static' traefik-webui npm run build:nc
   -       docker run --rm -v "$(PWD)/webui/static":'/src/webui/static' traefik-webui chown -R $(shell id -u):$(shell id -g) ./static
   +       docker run --rm -v "$(PWD)/webui/static":'/src/webui/static':Z traefik-webui npm run build:nc
   +       docker run --rm -v "$(PWD)/webui/static":'/src/webui/static':Z traefik-webui chown -R $(shell id -u):$(shell id -g) ./static

    .PHONY: generate-webui
    #? generate-webui: Generate WebUI
   ```
1. Build the binary
   ```
   make binary
   ```
1. Build the container image with podman
   ```
   podman build --build-arg TARGETPLATFORM=linux/arm64 -t traefik .
   ```

</details>

Alternatively if you are using arm64, pull the container image that I've already built

```
img=ghcr.io/eriksjolund/traefik:experiment-with-pr10399-git-commit-6d15f00af
podman pull $img
podman image tag $img localhost/traefik
```

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
