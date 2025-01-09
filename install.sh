#! /usr/bin/env sh
#
# Author: Andie Keller <andie@bugehisperer.dev>
#
# FERN INSTALL SCRIPT
# This script will install the Fern executable script into the user's local bin folder.
#
# Usage:
#  `$ chmod +x ./install.sh`
#  `$ ./install.sh`

#{{{ Shell settings
set -o errexit;		# abort on nonzero exitstatus
set -o nounset;		# abort on unbound variable
#}}}

#{{{ Variables
script_dir="$(CDPATH=""; cd -- "$(dirname -- "$0")" && pwd)";
binary_dir="$HOME/.local/bin";
binary_name="fern";
os="$(uname -s)";
readonly script_dir binary_dir binary_name os;
#}}}

main() {
	check_os;
	install_exe;
	install_docs;

	# all set! XD
	printf "\n~~~~~~  FERN INSTALLATION: SUCCESS!  ~~~~~~\n";
	printf "You can now run 'fern' from your terminal for the next steps!\nYou might have to restart your terminal session for the changes to take effect.\n";
	exit 0;
}

# check if this is a compatible UNIX OS and attempt to pull the SHELL being used
check_os() {
	printf "> Checking System and OS compatibility\n";
	if [ "${os}" != "Linux" ] && [ "${os}" != "Darwin" ]; then
		printf "Error: Unsupported OS found: %s" "$os" >&2;
		exit 1;
	fi
}

# install fern script to user's local bin
install_exe() {
	printf "> Installing Fern to bin folder\n";
	mkdir --parents "${binary_dir}"; # make sure the local bin folder exists
	cp "${script_dir}/src/fern.sh" "${binary_dir}/${binary_name}";
	chmod +x "${binary_dir}/${binary_name}";
	if [ ! -e "${binary_dir}/${binary_name}" ]; then
		printf "Error: Something went wrong! Fern does not exist at the installation location: %s.\n" "${binary_dir}" >&2;
	fi
}

# install the fern manpage
install_docs() {
	printf "Install the Fern documentation (manpage)? [Y/n] ";
	read -r option;
	if [ "${option}" = 'Y' ] || [ "$option" = 'y' ] || [ -x "${option}" ]; then
		printf "> Installing manpage\n";
		sudo cp "${script_dir}/docs/fern.1" /usr/local/share/man/man1;
	elif [ "${option}" != 'N' ] && [ "$option" != 'n' ]; then
		printf 'Invalid option: %s\n' "$option";
		install_docs;
	else
		printf "> Skipping manpage installation\n";
	fi
}


main "${@}";
