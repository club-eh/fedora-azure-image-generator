# downloads the Fedora installer ISO

if [[ -e "$INSTALLER_IMG_PATH" ]]; then
	log_info "Skipping installer ISO download, as the file already exists."
else
	log_info "Downloading installer ISO..."
	wget -nc "$INSTALLER_IMG_URL" -O "$INSTALLER_IMG_PATH"
fi
