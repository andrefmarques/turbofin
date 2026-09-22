# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

# Base Image
# bluefin-dx `latest` is the rolling Fedora 44 stream this machine already tracks.
# The digest is pinned so builds are reproducible; Renovate bumps it on upstream releases.
FROM ghcr.io/ublue-os/bluefin-dx:latest@sha256:df4f9c85c34f373b72d81227d83777bf141fbc39d9ae438e72fd406bccdac31a
## Other possible base images include:
# FROM ghcr.io/ublue-os/bluefin-dx:stable
# FROM ghcr.io/ublue-os/bluefin-dx-nvidia-open:latest
#
# Universal Blue Images: https://github.com/orgs/ublue-os/packages

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
