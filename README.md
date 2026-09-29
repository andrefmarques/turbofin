# turbofin

A custom [bootc](https://bootc-dev.github.io/bootc/) image built on
[`ghcr.io/ublue-os/bluefin-dx`](https://github.com/ublue-os/bluefin), with the packages
that would otherwise be layered on top of it baked into the image instead.

Built from [ublue-os/image-template](https://github.com/ublue-os/image-template).

## What is in it

Everything in `bluefin-dx:latest`, plus:

| Package | Source |
|---------|--------|
| `niri`, `tilix`, `twinkle`, `sassc` | Fedora |
| `dejavu-sans-fonts`, `google-noto-sans-fonts`, `liberation-fonts` | Fedora |
| `google-cloud-cli`, `google-cloud-cli-gke-gcloud-auth-plugin`, `google-cloud-cli-package-go-module` | [Google Cloud SDK](https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64) |
| `ghostty` | COPR [`scottames/ghostty`](https://copr.fedorainfracloud.org/coprs/scottames/ghostty/) |
| `dms`, and the `quickshell` it pulls in | COPR [`avengemedia/dms`](https://copr.fedorainfracloud.org/coprs/avengemedia/dms/) + [`avengemedia/danklinux`](https://copr.fedorainfracloud.org/coprs/avengemedia/danklinux/) |

Package selection lives in [`build_files/build.sh`](build_files/build.sh); the base image
lives in the [`Containerfile`](Containerfile).

The COPRs are disabled again after installation so they do not ship enabled in the final
image. The Google Cloud SDK repo is shipped enabled, via
[`system_files/etc/yum.repos.d/`](system_files/etc/yum.repos.d/).

## Setup

Set `REPO_ORGANIZATION` in [`image-template.env`](image-template.env) to the GitHub account
this repo lives under. The workflow derives the registry from
`github.repository_owner`, so nothing else needs the name.

### Signing

The build signs images with [cosign](https://docs.sigstore.dev/cosign/) and the published
public key is what client machines verify against.

```sh
cosign generate-key-pair
```

Leave the password empty. Commit `cosign.pub`, and add the contents of `cosign.key` as the
repository secret `SIGNING_SECRET`. Do not commit `cosign.key` — it is in `.gitignore`.

The image trusts its own signature: the same key ships at
[`system_files/usr/lib/pki/containers/turbofin.pub`](system_files/usr/lib/pki/containers/turbofin.pub),
[`build_files/build.sh`](build_files/build.sh) merges a matching `sigstoreSigned` entry into
`/etc/containers/policy.json`, and
[`system_files/etc/containers/registries.d/turbofin.yaml`](system_files/etc/containers/registries.d/turbofin.yaml)
points the registry at its sigstore attachments. Without those three,
`--enforce-container-sigpolicy` rejects the image, since the base only trusts `ghcr.io/ublue-os`.

Replacing the key means updating `cosign.pub`, `SIGNING_SECRET` and the copy under
`system_files/`, then rebasing once unsigned so the new policy lands before it is enforced.

Verify a published image against the key with:

```sh
cosign verify --key cosign.pub ghcr.io/andrefmarques/turbofin:latest
```

## Building

Locally:

```sh
just build          # build the image into local containers-storage
just build-vm       # build a QCOW2 to test it without rebasing
just run-vm         # boot that QCOW2
```

In CI: [`.github/workflows/build.yml`](.github/workflows/build.yml) builds on every push to
`main`, on pull requests, and daily at 10:05 UTC so the image follows upstream bluefin-dx.
Pull request builds do not push or sign.

The base image is a floating tag, so each scheduled rebuild picks up the current
bluefin-dx. Dependabot raises weekly pull requests for the pinned Action versions.

## Rebasing onto it

First to the unsigned image, so the signing policy is in place before it is enforced:

```sh
sudo bootc switch --transport registry ghcr.io/andrefmarques/turbofin:latest
systemctl reboot
```

Then to the signed one:

```sh
sudo bootc switch --enforce-container-sigpolicy \
  --transport registry ghcr.io/andrefmarques/turbofin:latest
systemctl reboot
```

After the first successful boot, the layered packages this image replaces can be dropped:

```sh
sudo rpm-ostree reset
```

To test a locally built image without pushing it:

```sh
sudo bootc switch --transport containers-storage localhost/turbofin:latest
```

## Rolling back

```sh
sudo bootc rollback
```
