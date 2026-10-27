# De-ICE S1.100 on Kali / libvirt

Run the [De-ICE S1.100 VulnHub challenge](https://www.vulnhub.com/entry/de-ice-s1100,8/)
on the course Kali host. The target is a 512 MiB, one-vCPU live-CD VM at
**192.168.1.100**, on a separate `De-ICE` libvirt network. Use it from Kali;
keep the deliberately vulnerable target on the lab network.

## Deploy

On the [course Kali image](https://security-assignments.com/labs/virtual-machines),
open a terminal and run:

```bash
git clone https://github.com/security-assignments/lab-de-ice-s1-100.git
cd lab-de-ice-s1-100
sudo bash deploy.sh install
```

The Bash script installs the Vagrantfile in
`/var/lib/libvirt/vagrant-boxes/lab-de-ice-s1-100`, verifies the ISO's SHA-256,
starts the VM, and waits up to two minutes for HTTP and SSH. Current course Kali
images already cache the ISO there; otherwise it downloads our
[hosted ISO](https://storage.googleapis.com/security-assignments-vagrant-boxes/lab-isos/De-ICE_S1.100.iso)
(205,422,592 bytes). No cloud account or download login is needed.

Open **http://192.168.1.100/** in Kali's browser. In `virt-manager`, use the
**QEMU/KVM system** connection to see `lab-de-ice-s1-100_default` and its console.
Vagrant does not log into or provision this challenge VM; `vagrant ssh` is not
supported. SSH credentials are part of the exercise.

The ISO is read-only, mode `0644`; it does **not** need execute permission.
Placing it under `/var/lib/libvirt` lets QEMU traverse its parent directories,
including when your home directory is private.

## Stop, resume, check, or remove

From your cloned repository:

```bash
sudo bash deploy.sh status
sudo bash deploy.sh check
sudo bash deploy.sh stop
sudo bash deploy.sh start
sudo bash deploy.sh destroy
```

**Stopping or destroying this live-CD VM loses changes in guest RAM.** Starting
again boots the original challenge. `destroy` asks for confirmation and retains
the ISO. Other lab networks are left alone. Repeating `install` verifies and reuses the ISO and
existing VM. To update the launcher, run `git pull --ff-only`, then repeat
`sudo bash deploy.sh install`; stop/destroy a VM before applying changes to its
hardware configuration.

## Instructor prerequisites and troubleshooting

Bash, Vagrant and libvirt (`virsh`) are sufficient; Ansible is not needed. Use the course
Kali image for the supported environment. Other Linux hosts need working KVM,
libvirt's system connection and default storage pool, Bash, curl, coreutils,
util-linux (`flock`), Vagrant, and a plugin installed for the user running
Vagrant. The launcher uses Vagrant to create/remove the domain and libvirt directly for
power controls and status. This avoids Vagrant interpreting the lack of a DHCP
lease as an inaccessible VM. All launcher commands use root consistently:

```bash
sudo vagrant plugin list
# Only if vagrant-libvirt is missing:
sudo vagrant plugin install vagrant-libvirt
```

The launcher does not install host packages or change SSH policy. If startup
fails, inspect the console in `virt-manager` and check for an overlapping
`192.168.1.0/24` network or another VM using `.100`. On a cloud host, nested
virtualization must be enabled. A successful `vagrant up` alone does not prove
the live CD finished booting; use `deploy.sh check`.

For a checksum mismatch, remove only the named cached ISO and rerun `install`.
Downloads use a temporary file and are renamed only after verification.
The expected SHA-256 is:

```text
d4d17be52000a6f92a970198a538eb85af54c4fa70a34e3c87ee5819126e3cc6
```

Current course Kali enables compatibility with old SSH targets. On another
host, if SSH reports negotiation errors, use a target-specific override:

```bash
ssh -oKexAlgorithms=+diffie-hellman-group1-sha1 -oHostKeyAlgorithms=+ssh-rsa USER@192.168.1.100
```

Replace `USER` with a username discovered during the exercise. See
[OpenSSH's legacy guidance](https://www.openssh.com/legacy.html); authentication
failures after negotiation are separate from SSH algorithm compatibility.

## Maintainers

The ISO mirror is the original live CD recovered from the
[Wayback Machine](https://web.archive.org/web/20190831103512/https://hackingdojo.com/downloads/iso/De-ICE_S1.100.iso).
Its bytes and checksum match the copy cached by the Kali image build. Only this
ISO object is public; publishing it requires no bucket-list permission.
Do not replace it with different bytes under the same name. An ISO update needs
a new object path and an explicit checksum update in this repo and the Kali
image provisioning configuration.

See [validation notes](docs/validation.md) for tested behavior and host versions.
