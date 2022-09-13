# prepares an ISO containing the Kickstart config

if [[ -d "fedora-kickstarts" ]]; then
	log_info "Deleting existing upstream Kickstart configs"
	rm -rf fedora-kickstarts
fi
log_info "Cloning upstream Kickstart configs"
git clone --depth=1 https://pagure.io/fedora-kickstarts.git fedora-kickstarts

log_info "Replacing rawhide repos with correct release repos"
echo '%include fedora-repo-not-rawhide.ks' > fedora-kickstarts/fedora-repo.ks

log_info "Flattening Kickstart config"
ksflatten -c custom-kickstart.ks -o build/ks.cfg

log_info "Creating Kickstart config ISO"
xorrisofs -r -o build/kickstart.iso build/ks.cfg
