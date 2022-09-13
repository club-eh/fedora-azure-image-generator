# Use upstream Azure base configuration
%include fedora-kickstarts/fedora-cloud-base-azure.ks

# After installation, poweroff instead of rebooting
poweroff


# Install kernel modules for Azure Accelerated Network support (specifically `mlx4_en` and `mlx5_core`)
%packages
kernel-modules
%end


%post --erroronfail

# Enable WALinuxAgent (will be obsoleted by https://pagure.io/fesco/issue/2849)
systemctl enable waagent.service

# Prevent NetworkManager from interfering with Azure Accelerated Network (https://github.com/Azure/WALinuxAgent/pull/1622)
echo 'SUBSYSTEM=="net", DRIVERS=="hv_pci", ACTION=="add", ENV{NM_UNMANAGED}="1"' > /etc/udev/rules.d/68-azure-sriov-nm-unmanaged.rules

%end
