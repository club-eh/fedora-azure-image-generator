#!/bin/bash

# Creates a new Fedora VM image in an Azure resource group.

set -eu

# check bash version
if ((${BASH_VERSINFO[0]} < 4)) || ( ((${BASH_VERSINFO[0]} == 4)) && ((${BASH_VERSINFO[1]} < 2)) ); then
	log_err
	echo "this script requires bash 4.2+"
	exit 1
fi

# cd to script directory
cd "$(dirname "$(realpath "$0")")"

# import bashlib
source _bashlib.sh
# use distinct logging prefix
LOG_PREFIX="  => "

# import config
source _config.sh


# generate build ID
if [[ ! -v BUILD_ID ]]; then
	BUILD_ID="$(date +%Y%m%d-%H%M%S)-$(head -c4 /dev/urandom | xxd -p)"
fi
log_info "Build ID: ${BUILD_ID}"

AZ_IMAGE_NAME="${AZ_IMAGE_PREFIX}-${BUILD_ID}"
AZ_MDISK_NAME="temp-${AZ_IMAGE_NAME}"
AZ_INSTALL_VM_NAME="${AZ_INSTALL_VM_PREFIX}-${BUILD_ID}"

# create local temporary directory
TEMP_DIR="/tmp/.az-image-${BUILD_ID}"
mkdir -p "$TEMP_DIR"


# create managed disk
AZ_DISK_ARGS=(
	-g "$AZ_RESOURCE_GROUP"
	-n "$AZ_MDISK_NAME"
	-l "$AZ_LOCATION"

	--size-gb "$IMAGE_SIZE"

	--os-type Linux
	--hyper-v-generation "$AZ_HYPERV_GEN"
)
log_info "Creating blank managed disk"
az disk create "${AZ_DISK_ARGS[@]}"

# create new VM
AZ_VM_ARGS=(
	-g "$AZ_RESOURCE_GROUP"
	-n "$AZ_INSTALL_VM_NAME"
	-l "$AZ_LOCATION"

	--size "Standard_D2s_v3"
	--image "Debian:debian-11:11:latest"
	--public-ip-sku "Standard"
	# use standard admin username
	--admin-username azureuser

	# use an ephemeral disk
	--ephemeral-os-disk true
	# delete the NIC with the VM
	--nic-delete-option Delete
	# delete the OS disk with the VM
	--os-disk-delete-option Delete

	# attach target data disk
	--attach-data-disks "$AZ_MDISK_NAME"
	# don't delete the data disk on VM deletion
	--data-disk-delete-option Detach
)
log_info "Creating installer VM"
az vm create "${AZ_VM_ARGS[@]}" | tee "${TEMP_DIR}/vm-info.json"

# get public IP address
INSTALLER_VM_IP="$(jq -r '.publicIpAddress' <"${TEMP_DIR}/vm-info.json")"


# define SSH connection wrapper
SSH_OPTS=(
	# reuse SSH connections
	-o ControlMaster=auto
	-o ControlPersist=60
	-o ControlPath="${TEMP_DIR}/ssh-multiplex.sock"
	# disable host key checking
	-o UserKnownHostsFile=/dev/null
	-o StrictHostKeyChecking=false

	# connection string
	azureuser@"$INSTALLER_VM_IP"
)
run_step() {
	# enables pseudo-terminal creation so sudo works properly
	ssh "${SSH_OPTS[@]}" -t -- bash ./wrapper.sh "$@"
}

# wait for installer VM to finish booting, to prevent race conditions with APT
log_info "Waiting for installer VM to finish boot process"
ssh "${SSH_OPTS[@]}" -- "systemctl is-system-running --wait"

# upload files to installer VM
log_info "Uploading files to installer VM"
tar -c _{bashlib,config}.sh | ssh "${SSH_OPTS[@]}" -- "tar -x"
tar -c remote | ssh "${SSH_OPTS[@]}" -- "tar -x --strip-components=1"


log_info "Remote: Installing dependencies"
run_step 00-initialize-workspace.sh

log_info "Remote: Downloading Fedora installer"
run_step 01-download-image.sh

log_info "Remote: Preparing for installation"
run_step 02-extract-kernel-images.sh
run_step 03-prepare-kickstart-image.sh

log_info "Remote: Installing Fedora to disk via QEMU"
run_step 04-run-installer.sh


log_info "Creating VM image from managed disk"
AZ_IMAGE_ARGS=(
	-g "$AZ_RESOURCE_GROUP"
	-n "$AZ_IMAGE_NAME"
	-l "$AZ_LOCATION"

	--source "$AZ_MDISK_NAME"

	--storage-sku Premium_LRS

	--os-type Linux
	--hyper-v-generation "$AZ_HYPERV_GEN"
)
az image create "${AZ_IMAGE_ARGS[@]}"

log_info "Done creating image: $AZ_IMAGE_NAME"


log_info "Deleting installer VM and temporary resources"
az vm delete --yes -g "$AZ_RESOURCE_GROUP" -n "${AZ_INSTALL_VM_NAME}"
az network public-ip delete -g "$AZ_RESOURCE_GROUP" -n "${AZ_INSTALL_VM_NAME}PublicIP"
az network nsg delete -g "$AZ_RESOURCE_GROUP" -n "${AZ_INSTALL_VM_NAME}NSG"
az network vnet delete -g "$AZ_RESOURCE_GROUP" -n "${AZ_INSTALL_VM_NAME}VNET"
az disk delete --yes -g "$AZ_RESOURCE_GROUP" -n "$AZ_MDISK_NAME"
