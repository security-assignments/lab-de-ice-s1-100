#!/usr/bin/env bash
# Manage the optional De-ICE live-CD lab on a Kali/libvirt host.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: sudo bash deploy.sh [install|start|stop|status|check|destroy]
  install  Verify/download the ISO, install the Vagrantfile, and start (default).
  start    Start the installed VM and wait for HTTP and SSH.
  stop     Power off the live CD (changes in guest RAM are lost).
  status   Show Vagrant status.
  check    Wait up to two minutes for HTTP and an SSH banner.
  destroy  Remove this VM after Vagrant's confirmation; retain the ISO.

Run on the course Kali host. Requires Bash, curl, sha256sum, flock, timeout,
Vagrant and the vagrant-libvirt plugin. State and ISO are kept in:
  /var/lib/libvirt/vagrant-boxes/lab-de-ice-s1-100
Target: http://192.168.1.100/ (access from the Kali host).
EOF
}

action=${1:-install}
case "$action" in
  -h|--help|help) usage; exit 0 ;;
  install|start|stop|status|check|destroy) ;;
  *) usage >&2; exit 2 ;;
esac
[[ $# -le 1 ]] || { usage >&2; exit 2; }
[[ $EUID -eq 0 ]] || { echo 'Run with sudo bash deploy.sh.' >&2; exit 1; }

runtime=/var/lib/libvirt/vagrant-boxes/lab-de-ice-s1-100
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
iso="$runtime/De-ICE_S1.100.iso"
url=https://storage.googleapis.com/security-assignments-vagrant-boxes/lab-isos/De-ICE_S1.100.iso
sha256=d4d17be52000a6f92a970198a538eb85af54c4fa70a34e3c87ee5819126e3cc6

ready() {
  echo 'Waiting for De-ICE HTTP and SSH at 192.168.1.100...'
  local deadline=$((SECONDS + 120))
  while ((SECONDS < deadline)); do
    # The banner variable belongs to the child shell.
    # shellcheck disable=SC2016
    if curl --noproxy '*' -fsS --max-time 2 -o /dev/null http://192.168.1.100/ 2>/dev/null &&
       timeout 2 bash -c 'exec 3<>/dev/tcp/192.168.1.100/22; IFS= read -r banner <&3; [[ $banner == SSH-* ]]' 2>/dev/null; then
      echo 'Ready: HTTP responds and SSH offers a banner. Open http://192.168.1.100/ from Kali.'
      return 0
    fi
    sleep 2
  done
  echo 'Readiness timed out. Check the VM console in virt-manager (QEMU/KVM system connection).' >&2
  return 1
}

for tool in curl sha256sum flock timeout vagrant; do
  command -v "$tool" >/dev/null || { echo "Missing prerequisite: $tool" >&2; exit 1; }
done
if [[ $action == check ]]; then ready; exit; fi
vagrant plugin list | grep -q '^vagrant-libvirt ' || {
  echo 'Missing plugin for root. Run: sudo vagrant plugin install vagrant-libvirt' >&2
  exit 1
}
install -d -m 0755 "$runtime"
exec 9>"$runtime/.deploy.lock"
flock -n 9 || { echo 'Another deployment is running.' >&2; exit 1; }
export VAGRANT_DEFAULT_PROVIDER=libvirt
export LIBVIRT_DEFAULT_URI=qemu:///system

if [[ $action == install ]]; then
  [[ -r $source_dir/Vagrantfile ]] || { echo 'Keep deploy.sh beside its Vagrantfile.' >&2; exit 1; }
  if [[ $source_dir != "$runtime" ]]; then
    install -m 0644 "$source_dir/Vagrantfile" "$runtime/Vagrantfile"
  fi
  verify() { printf '%s  %s\n' "$sha256" "$1" | sha256sum --check --status; }
  if [[ -f $iso ]]; then
    verify "$iso" || { echo "ISO checksum mismatch: $iso. Remove it and retry install." >&2; exit 1; }
    echo 'Using the checksum-verified cached ISO.'
  else
    partial=$(mktemp "$runtime/.iso-download.XXXXXX")
    trap 'rm -f -- "$partial"' EXIT
    curl -fL --retry 3 --connect-timeout 15 "$url" -o "$partial"
    verify "$partial" || { echo 'Downloaded ISO checksum mismatch.' >&2; exit 1; }
    chmod 0644 "$partial"
    mv -- "$partial" "$iso"
    trap - EXIT
  fi
  chmod 0644 "$iso"
fi
[[ -f $runtime/Vagrantfile ]] || { echo 'Run install first.' >&2; exit 1; }
cd -- "$runtime"
case "$action" in
  install|start) vagrant up --provider=libvirt; ready ;;
  stop) vagrant halt --force ;;
  status) vagrant status ;;
  destroy) vagrant destroy ;;
esac
