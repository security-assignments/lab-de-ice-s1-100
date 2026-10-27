# Deployment validation — 2026-10-27

## Artifact and ownership

- Repository transferred from `deargle` to `security-assignments`; GitHub's old
  URL redirects to the new repository, preserving history and existing pins.
- Anonymous HTTPS download of the cloud ISO succeeded. SHA-256 matched
  `d4d17be52000a6f92a970198a538eb85af54c4fa70a34e3c87ee5819126e3cc6`,
  size 205,422,592 bytes. This matches the Kali build's cached image.
- Added public read to this ISO object only. No bucket listing or bucket-wide
  public access was granted.

## Local KVM host

Tested with Vagrant 2.4.9 and vagrant-libvirt 0.12.2 using `qemu:///system`.
The root plugin was installed separately, as documented; a plugin installed
only for the desktop user is not visible to `sudo vagrant`.

The initial installation downloaded and verified the ISO, created a 512 MiB,
one-vCPU domain, and booted the live CD. Readiness verified an HTTP response
and an SSH protocol banner at 192.168.1.100. The ISO stayed mode 0644.

A repeat-run check exposed vagrant-libvirt 0.12.2 rewriting the expanded CPU
model to an empty string while retaining the vendor. The Vagrantfile now uses
`host-passthrough` to avoid that rewrite. This live CD has no installed guest
hardware state to preserve across host changes.

After the CPU setting fix, repeated installation passed HTTP and SSH readiness.
Further lifecycle validation found Vagrant reporting a running static-IP guest
as `inaccessible`, and its halt action did not reliably stop that domain.
The launcher now reads Vagrant's recorded UUID and uses `virsh` for actual
power state, stop and start. Tests assert the domain is `shut off` after stop
and `running` after start, in addition to service readiness. Interactive `destroy` removed the domain and retained the
ISO; unrelated `infosec-net` and `default` networks stayed active. A deliberately
invalid cached ISO was rejected before VM creation, and the original ISO was
restored afterward. The transient De-ICE network was absent after removal;
removing and recreating the lab does not depend on retaining it.

ShellCheck, Bash syntax checking, and Ruby syntax checking passed.

## Released course image

Tested on a disposable GCE instance of **kali-v6-0-0**, with nested
virtualization enabled, using Vagrant **2.3.8.dev** and vagrant-libvirt **0.12.2**.
No host package installation or SSH policy changes were needed.

- Cloned the public organization repository and ran `sudo bash deploy.sh install`.
  The checksum-verified baked ISO was reused without downloading it.
- HTTP response and SSH banner checks passed after initial boot.
- Repeated install reused the running domain and passed readiness.
- With the final launcher, stop was verified through libvirt as **shut off**;
  a second stop succeeded without changing anything.
- Start returned the domain to **running**, and both service checks passed.
- Status displayed the real running state, one CPU and 524,288 KiB memory.
- A final repeated install passed readiness again.

The plugin can emit a `libvirt_ip_command` warning and a graphics websocket XML
difference on Vagrant-managed repeated starts. Neither prevented the tested
boot. The launcher uses libvirt directly for subsequent starts, avoiding both
that path and Vagrant's DHCP-based status inference.

The public course page's GitHub Pages deployment succeeded, and the published
page was checked for the new owner and launcher instructions. The Kali image
build playbook also passed its Ansible syntax check with the new repository URL
and pinned revision. This change does not require a golden-image rebuild.
