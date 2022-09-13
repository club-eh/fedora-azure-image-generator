# define general functions
silent() {
	# run a command silently (by redirecting stdout/stderr to /dev/null)
	"$@" >/dev/null 2>&1
}

# check for color support and define colors
if silent type -f tput; then
	TPUT_AVAILABLE=1
	export TERM="${TERM:-xterm-256color}"
	C_RED="$(tput setaf 1)"
	C_GREEN="$(tput setaf 2)"
	C_BLUE="$(tput setaf 4)"
	C_RESET="$(tput sgr0)"
else
	C_RED=""
	C_GREEN=""
	C_BLUE=""
	C_RESET=""
fi

# define logging functions
LOG_PREFIX="> "
log_trace() {
	echo "${C_BLUE}${LOG_PREFIX}$@${C_RESET}"
}
log_info() {
	echo "${C_GREEN}${LOG_PREFIX}$@${C_RESET}"
}
log_err() {
	echo "${C_RED}${LOG_PREFIX}$@${C_RESET}" >&2
}
