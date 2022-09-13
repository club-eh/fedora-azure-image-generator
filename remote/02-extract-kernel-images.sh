# extracts the Linux kernel and initrd files (so QEMU can use direct boot)

log_info "Extracting Linux kernel and initrd"
7z e -aoa -obuild "$INSTALLER_IMG_PATH" images/pxeboot/{vmlinuz,initrd.img}
