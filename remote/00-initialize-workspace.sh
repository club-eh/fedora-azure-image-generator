# initializes the workspace and does some sanity checks for later steps

# create required work directories
mkdir -p build cache

# install dependencies
log_info "Installing dependencies"
sudo apt-get install -y --no-install-recommends git wget p7zip-full qemu-system-x86 qemu-utils pipx xorriso
pipx install pykickstart

# ensure required dependencies are available
REQUIRED_COMMANDS=(
	# for downloading upstream Fedora kickstart files
	"git"
	# for downloading installer files
	"wget"
	# for extracting installer files
	"7z"
	# for running the installer VM
	"qemu-system-x86_64"  # from QEMU
	# for generating kickstart ISO image
	"ksflatten"  # `pipx install pykickstart`
	"xorrisofs"  # from libisoburn/xorriso
)
for req_cmd in "${REQUIRED_COMMANDS[@]}"; do
	if ! silent type -f "$req_cmd"; then
		log_err "Required program '$req_cmd' was not found!"
		exit 1
	fi
done
