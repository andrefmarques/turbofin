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

### CLI tools
# helm is v4 and helm3 is v3. They install /usr/bin/helm and /usr/bin/helm3
# respectively, so the two coexist.

dnf5 install -y \
    ansible \
    azure-cli \
    hadolint \
    helm \
    helm3 \
    k9s \
    kubernetes-client \
    kustomize \
    pipx \
    pre-commit \
    ripgrep \
    uv \
    yamllint \
    yq

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
    dms
dnf5 -y copr disable avengemedia/dms
dnf5 -y copr disable avengemedia/danklinux

### Cloudflare WARP
# Repo comes from system_files. Cloudflare publishes a Fedora build, so
# $releasever in its baseurl resolves on its own and needs none of the hardcoding
# the el9-only Google SDK repo does.
#
# The rpm's postinstall copies its unit out of /opt into /etc/systemd/system but
# stops short of enabling it, so warp-svc is enabled explicitly. The daemon only
# idles until `warp-cli registration new` and `warp-cli connect` are run.

dnf5 install -y cloudflare-warp
systemctl enable warp-svc.service

### Signature policy
# The base image only trusts ghcr.io/ublue-os, so `bootc switch
# --enforce-container-sigpolicy` onto this image would be rejected without an
# entry of its own. policy.json is a single file rather than a drop-in
# directory, so the entry is merged in here instead of shipped in system_files.
# The key itself and the registries.d drop-in do come from system_files.

POLICY=/etc/containers/policy.json
jq '.transports.docker["ghcr.io/andrefmarques/turbofin"] = [{
      "type": "sigstoreSigned",
      "keyPath": "/usr/lib/pki/containers/turbofin.pub",
      "signedIdentity": { "type": "matchRepository" }
    }]' "${POLICY}" > "${POLICY}.new"
mv "${POLICY}.new" "${POLICY}"
