#!/bin/bash

set -ouex pipefail

# Runs before any install, so system_files/etc/yum.repos.d/google-cloud-cli.repo
# is in place by the time dnf5 resolves the google-cloud-* packages below.
cp -avf "/ctx/system_files"/. /

### Fedora repos

dnf5 install -y \
    dejavu-sans-fonts \
    google-noto-sans-fonts \
    liberation-fonts \
    niri \
    sassc \
    tilix \
    twinkle

### Google Cloud SDK
# Repo comes from system_files; the key is fetched over https at build time.
#
# Upstream renamed google-cloud-sdk-* to google-cloud-cli-*. The old names still
# resolve through Obsoletes, but are spelled out here so the transaction does not
# depend on that chain staying in place.

dnf5 install -y \
    google-cloud-cli \
    google-cloud-cli-gke-gcloud-auth-plugin \
    google-cloud-cli-package-go-module

### ghostty
# Both scottames/ghostty and avengemedia/danklinux ship a `ghostty` package.
# Installing here, before danklinux is enabled, pins it to the scottames build
# regardless of which COPR happens to carry the higher version.

dnf5 -y copr enable scottames/ghostty
dnf5 install -y ghostty
dnf5 -y copr disable scottames/ghostty

### DankMaterialShell
# danklinux is declared as a runtime-dependency COPR of the dms project. dnf5 can
# resolve that indirection on a live system, but it is not reliable inside a
# container build, so both projects are enabled explicitly.

dnf5 -y copr enable avengemedia/dms
dnf5 -y copr enable avengemedia/danklinux
dnf5 install -y \
    dms \
    quickshell-git
dnf5 -y copr disable avengemedia/dms
dnf5 -y copr disable avengemedia/danklinux

# Nerd Fonts are installed on the source machine from che/nerd-fonts but were not
# part of the layered set. Uncomment to bake them in as well.
#
# dnf5 -y copr enable che/nerd-fonts
# dnf5 install -y nerd-fonts
# dnf5 -y copr disable che/nerd-fonts
