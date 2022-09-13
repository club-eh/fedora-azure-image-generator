# install Fedora to virtual hard drive
log_info "Running installer via QEMU"
QEMU_OPTS=(
	# use semi-modern machine type, with KVM hardware acceleration
	-machine type=q35,accel=kvm
	# configure CPU
	-cpu host
	-smp 6
	# configure memory
	-m 1536M
	# disable graphics
	-display none
	# enable serial IO + QEMU monitor on stdio
	-serial mon:stdio
	# use direct kernel boot
	-kernel build/vmlinuz
	-initrd build/initrd.img
	# specify kernel cmdline
	-append 'console=ttyS0 inst.text inst.ks=cdrom inst.repo=cdrom'
	# add installer CD-ROM drive
	-drive file="$INSTALLER_IMG_PATH",media=cdrom,format=raw,read-only=true
	# add kickstart CD-ROM drive
	-drive file=build/kickstart.iso,format=raw,media=cdrom,read-only=true
	# add target hard drive (virtio is expected by the upstream kickstart config)
	-drive file="$TARGET_BLOCK_DEVICE",format=raw,if=virtio,read-only=false
)
sudo qemu-system-x86_64 "${QEMU_OPTS[@]}"
