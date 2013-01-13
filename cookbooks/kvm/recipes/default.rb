packages = %w(qemu-kvm libvirt-bin ebtables ipxe kvm-pxe)

packages.each do |pkg|
  package pkg do
    action :install
  end
end