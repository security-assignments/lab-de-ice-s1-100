Vagrant.configure("2") do |config|

  config.vm.network :private_network,
    ip: '192.168.1.100',
    libvirt__network_name: 'De-ICE',
    libvirt__dhcp_enabled: false,
    libvirt__forward_mode: 'nat',
    libvirt__host_ip: '192.168.1.1',
    # Do not destroy the De-ICE network when this VM is destroyed.
    # vagrant-libvirt deletes any network it recorded unless a RUNNING domain is
    # attached -- shut-off lab VMs do not protect theirs, so one destroy breaks
    # the others' next boot. NOTE: always_destroy is undocumented in the
    # vagrant-libvirt README (real in 0.12.2); re-verify on plugin upgrade.
    libvirt__always_destroy: false,
    model_type: 'e1000',
    autostart: true

  config.vm.provider :libvirt do |libvirt|
    libvirt.storage :file, :device => :cdrom, :path => "#{Dir.pwd}/De-ICE_S1.100.iso"
    libvirt.boot 'cdrom'
    libvirt.mgmt_attach = false
    # Inert while mgmt_attach is false (this VM never joins the management
    # network), but kept so the shared 'vagrant-libvirt' network is still
    # protected from this VM's destroy if mgmt_attach is ever turned back on.
    libvirt.management_network_keep = true
  end

end
