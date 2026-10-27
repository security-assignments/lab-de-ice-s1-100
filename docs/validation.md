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

ShellCheck, Bash syntax checking, and Ruby syntax checking passed. Detailed
runtime checks and course-image results are recorded below as they complete.
