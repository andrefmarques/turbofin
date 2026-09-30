# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

# Base Image
# bluefin-dx `latest` is the rolling Fedora 44 stream this machine already tracks.
# Left as a floating tag: the build runs --pull=newer, so the daily scheduled
# rebuild picks up each upstream release on its own. A pinned digest would need
# something watching it to be worth the reproducibility, and an upstream
# regression is one `bootc rollback` away.
FROM ghcr.io/ublue-os/bluefin-dx:latest
## Other possible base images include:
# FROM ghcr.io/ublue-os/bluefin-dx:stable
# FROM ghcr.io/ublue-os/bluefin-dx-nvidia-open:latest
#
# Universal Blue Images: https://github.com/orgs/ublue-os/packages

### [IM]MUTABLE /opt
## Fedora bootc images symlink /opt to /var/opt so it is writable, but /var is
## machine-local and reset on deploy. cloudflare-warp ships
## /opt/cloudflare-warp/warp-svc.service, so /opt is made a real directory here
## to keep that file part of the image. Both /opt and /var/opt are empty in the
## base, so nothing is lost by replacing the symlink.

RUN rm /opt && mkdir /opt

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
