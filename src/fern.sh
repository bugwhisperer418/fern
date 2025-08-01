#! /usr/bin/env bash
#
# Author: Andie Keller <andie@bugwhisperer.dev>

#{{{ Shell settings
set -o errexit;		# abort on nonzero exitstatus
set -o nounset;		# abort on unbound variable
#}}}

#{{{ Variables
fVersion="0.1.7";
readonly fVersion;

if [[ ${FERN_VAULT:-"unset"} != "unset" ]]; then
	fNotes="$FERN_VAULT/notes";
	fJournals="$FERN_VAULT/journals";
	fTemplates="$FERN_VAULT/templates";
	fBookmarks="$FERN_VAULT/bookmarks";
	wl="$fTemplates/weekly.log";
	ml="$fTemplates/monthly.log";
	fl="$fTemplates/future.log";
	temp="$FERN_VAULT/.temp";
	readonly fNotes fJournals fTemplates fBookmarks wl ml fl temp;
fi
#}}}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~         MAIN LOGIC         ~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
main() {
	if help_wanted "$@"; then
		usage_lite;
	elif [ "${1}" = "help" ]; then
		usage_indepth;
	elif [ "${1}" = "vault" ]; then
		process_vault "${@}";
	else
		if [[ ${FERN_VAULT:-"unset"} == "unset" ]] || [ ! -e "${FERN_VAULT}" ]; then
			printf "Error: Fern Vault folder does not exist or the environment variable FERN_VAULT is not setup correctly.\nRun 'fern vault create <path>' to setup a new Fern Vault folder for management.\nIf you already went through the Fern Vault creation process, please verify that the FERN_VAULT environment variable is set correctly. You can verify this with 'echo \$FERN_VAULT'.\n" >&2;
			exit 1;
		fi
		if [ ! -e "${fl}" ]; then
			print_err "Error: The required 'future.log' template file does not exist! Please create one at '$fl' and then try again.";
		fi
		if [ ! -e "${ml}" ]; then
			print_err "Error: The required 'monthly.log' template file does not exist! Please create one at '$ml' and then try again.";
		fi
		if [ ! -e "${wl}" ]; then
			print_err "Error: The required 'weekly.log' template file does not exist! Please create one at '$wl' and then try again.";
		fi	
		decipher_request "${@}";
	fi
	exit 0;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~    HELPER FUNCTIONS      ~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# check for default editor for opening of files
default_editor() {
	local editor="${EDITOR:-${VISUAL:-${FCEDIT:-NONE}}}";
	if [ $editor = "NONE" ]; then
		local editors='nano joe vim vi helix nvim'; # common terminal editors to check as fallback
		local display='${DISPLAY:-NONE}';
		if [ $display = "NONE" ]; then
			editors="$editors code subl gedit kate"; # add some common GUI editors to check too
		fi
		for e in $editors; do
			if type "$e" >/dev/null 2>/dev/null; then
				editor="$e";
			fi
			if [ $editor != "NONE" ]; then
				break;
			fi
		done
		# editor is still none after checking common ones, so raise an error
		print_error "Error: No default editor found! Set $EDITOR, $VISUAL or $FCEDIT to your default editor.";
	fi
	echo "$editor";
}

# open file(s) in an editor
# $1 - file(s) [string]
# $2 - multiple files flag [bool]
open_files() {
	local editor=$(default_editor);
	local multi_file=${2-false};
	if [ $multi_file == true ]; then
		# check if we are dealing with editor that can handle multiple windows
		if [ $editor == "nvim" ] || [ $editor == "vim" ] || [ $editor == "vi" ]; then
			exec $editor -O $1;
			return 0;
		fi
	fi
	# special open commands for some editors
	if [ $editor == "kate" ]; then
		exec $editor -b $1;
	elif [ $editor == "code" ]; then
		exec $editor -n $1;
	else
		# covers all other editors for multi-files
		# & also covers all single file openings
		exec $editor $1;
	fi
	return 0;
}

# catches if no args are passed OR the first arg is a "common" help flag
help_wanted() {
	[ "$#" -eq 0 ] || [ "${1}" = "-h" ] || [ "${1}" = "--help" ] || [ "${1}" = "-?" ]
}

usage_lite() {
	printf "fern - a knowledge management system [v%s]\nUsage:\tfern COMMAND [ACTION [ARGS...]]\n\nfern is a swiss-army knife for your notetaking and personal knowledge management. Fern is a helpful commandline tool to manage, curate, and search a vault of your personal notes.\n\nTo get started with a new Fern Vault, use 'fern vault create <path_to_vault>'.\nFor a brief list of all commands and their options, use 'fern help'.\nFor more in-depth documentation and advanced usage see the fern(1) manpage (\"man fern\") and/or https://sr.ht/~bugwhisperer/fern/\n" "$fVersion";
}

usage_indepth() {
	printf "USAGE:\n  fern COMMAND [ACTION [ARGS...]]\n\nCOMMANDS:\n  help\t\t\t\t\t\t\tdisplay Fern help\n\n  vault create <path>\t\t\t\t\tsetup a new Fern Vault\n  vault stat\t\t\t\t\t\tget stats of Fern Vault\n\n  bookmark list\t\t\t\t\t\tlist out all Bookmarks\n  bookmark add <note_name>\t\t\t\tadd a note to Bookmarks\n  bookmark del <note_name>\t\t\t\tremove a note from Bookmarks\n\n  journal\t\t\t\t\t\topens today's weekly Journal log\n  journal open <{this|next|last}-{week|month|year}>\topen commonly accessed Journal log\n  journal open <YYYY-MM-DD>\t\t\t\topen a specific Journal log\n  journal find <pattern>\t\t\t\tsearch Journals for matching pattern\n\n  note add <note> [<template>]\t\t\t\tadd a new Note\n  note del <note>\t\t\t\t\tdelete a Note\n  note open <note>\t\t\t\t\topen a Note\n  note move <old_note> <new_note>\t\t\tmove/rename a Note\n  note find <pattern>\t\t\t\t\tsearch Notes for matching pattern\n\n  template list\t\t\t\t\t\tget list of Template files\n  template add <template>\t\t\t\tadd a new Template\n  template del <template>\t\t\t\tdelete a Template\n  template open <template>\t\t\t\topen a Template\n  template move <old_template> <new_template>\t\tmove/rename a Template\n\nFor more in-depth documentation and advanced usage see the fern(1) manpage (\"man fern\") and/or https://sr.ht/~bugwhisperer/fern/\n";
}

cmd_usage() {
	case "$1" in
	vault)
		printf "Usage:\n  fern vault stat\n  fern vault create <path>\n";
		;;
	bookmark)
		printf "Usage:\n  fern bookmark list\n  fern bookmark add|del <note_name>\n";
		;;
	journal)
		printf "Usage:\n  fern journal\n  fern journal open <{this|next|last}-{week|month|year}>\n  fern journal open <YYYY-MM-DD>\n  fern journal find <search_pattern> [--verbose]\n";
		;;
	note)
		printf "Usage:\n  fern note\n  fern note del|open <note_name>\n  fern note add <note_name> [<template_name>]\n  fern note find <search_pattern> [--verbose]\n  fern note move <old_note> <new_note>\n  fern note append <template_name> [<note_name>]\n";
		;;
	template)
		printf "Usage:\n  fern template list\n  fern template add|del|open <template_name>\n  fern template move <old_template> <new_template>\n";
		;;
	esac
	exit 0;
}

# Takes all user arguments "$@". Tries to find the right command >> action to execute.
decipher_request() {
	case "$1" in
	vault)
		process_vault "$@";
		;;
	bookmark)
		process_bookmark "$@";
		;;
	journal)
		process_journal "$@";
		;;
	note)
		process_note "$@";
		;;
	template)
		process_template "$@";
		;;
	*)
		printf "Usage: Invalid command - '%s'. See \"fern help\" or the manpage (\"man fern\") for guidance.\n" "$1";
		;;
	esac
}

# $1 - action; $2 - Vault path;
process_vault() {
	if [ "$#" -lt 2 ]; then cmd_usage "$1"; fi
	case "$2" in
	create)
		if [ "$#" -ne 3 ]; then cmd_usage "$1";
		elif [ -e "$3" ]; then
			print_err "Error: Folder already exists'$3'\n";
		fi
		# setup a new folder for management
		mkdir --parents "$3";
		mkdir --parents "$3/notes";
		mkdir --parents "$3/journals";
		mkdir --parents "$3/templates";
		touch "$3/bookmarks";
		touch "$3/templates/future.log";
		printf "# Future Log ## JAN\n" | tee --append "$3/templates/future.log" >/dev/null;
		touch "$3/templates/monthly.log";
		printf "# {{MONTH}} {{YEAR}}\n\n## Reflection\n\n## Log\n" | tee --append "$3/templates/monthly.log" >/dev/null;
		touch "$3/templates/weekly.log";
		printf "# Week {{WEEKNO}}\n\n## Reflection\n\n## Log\n\n## Daily Notes\n" | tee --append "$3/templates/weekly.log" >/dev/null;

		printf "A Fern Vault has been setup for you at '%s'.\nYou're all ready to start managing your notes!\nBe sure to review 'fern help' for more information on the available commands and their arguments.\nSeveral starter log files for yearly/monthly/weekly levels were created at '%s'.\nFeel free to add any starting contents that you require of your log journal entries.\n" "$3" "$3/templates";
		printf "\n~~ IMPORTANT! ~~\nIn order for fern to know where to find your Vault, add the following to your shell's RC File (ex. \$HOME/.bashrc or \$HOME/.zshrc):\n";
		printf "export FERN_VAULT=\"%s\"\n" "$3";
		;;
	stat)
		# Vault stats printed out
		local cntB=$(wc --lines < "$fBookmarks");
		local cntN=$(find "$fNotes" | wc --lines);
		local cntJ=$(find "$fJournals" | wc --lines);
		local cntT=$(find "$fTemplates" | wc --lines);
		printf "Vault Location: $FERN_VAULT\n# Bookmarks:\t%d\n# Journals:\t%d\n# Notes:\t%d\n# Templates:\t%d\n" "$cntB" "$cntJ" "$cntN" "$cntT";
		;;
	*)
		cmd_usage "$1";
		;;
	esac
}

# $1 - action; $2 - Note name;
process_bookmark() {
	if [ "$#" -lt 2 ]; then cmd_usage "$1"; fi
	case "$2" in
	list)
		cat "$fBookmarks";
		;;
	add)
		if [ "$#" -ne 3 ]; then cmd_usage "$1"; fi
		local target=$(ext_checks "$3");
		if [ ! -e "$fNotes/$target" ]; then
			print_err "Error: Note not found with the name '$target'.";
		elif [ "$(awk "/$target/" < "$fBookmarks" | wc --lines)" -eq 0 ]; then
			printf "%s" "$target" | tee --append "$fBookmarks" >/dev/null;
			sort "$fBookmarks" -o "$fBookmarks";
		fi
		;;
	del)
		if [ "$#" -ne 3 ]; then cmd_usage "$1"; fi
		local target=$(ext_checks "$3");
		mktemp -d -t "$temp";
		trap '{ rm -f -- "$temp"; }' EXIT;
		grep -xv "$target" "$fBookmarks" > "$temp" && mv "$temp" "$fBookmarks";
		;;
	*)
		cmd_usage "$1";
		;;
	esac
}

# $1 - action; $2 - template name; $3 - template name;
process_template() {
	if [ "$#" -lt 2 ]; then cmd_usage "$1"; fi
	case "$2" in
	list)
		ls "$fTemplates" -1;
		;;
	open)
		if [ "$#" -lt 3 ]; then cmd_usage "$1"; fi
		local target=$(ext_checks "$3");
		if [ ! -e "$fTemplates/$target" ]; then
			print_err "Error: Template not found with the name '$target'.";
		fi
		open_files "$fTemplates/$target";
		;;
	add)
		if [ "$#" -lt 3 ]; then cmd_usage "$1"; fi
		local target=$(ext_checks "$3");
		if [ -e "$target" ]; then
			print_err "Error: Template already exists with that name '$target'.";
		fi
		open_files "$fTemplates/$target";
		;;
	del)
		if [ "$#" -lt 3 ]; then cmd_usage "$1"; fi
		local target=$(ext_checks "$3");
		if [ ! -e "$fTemplates/$target" ]; then
			print_err "Error: Template not found with the name '$target'.";
		fi
		rm -f "$fTemplates/$target";
		;;
	move)
		if [ "$#" -lt 3 ]; then cmd_usage "$1"; fi
		local oldT=$(ext_checks "$3");
		if [ "$#" -lt 4 ]; then cmd_usage "$1"; fi
		local newT=$(ext_checks "$4");
		if [ ! -e "$fTemplates/$oldT" ]; then
			print_err "Error: Template not found with the name '$oldT'.";
		fi
		mv "$fTemplates/$oldT" "$fTemplates/$newT";
		;;
	*)
		cmd_usage "$1";
		;;
	esac
}

# $1 - action; $2 - journal date | pattern string.;
process_journal() {
	if [ "$#" -eq 1 ]; then
		# shortcut to create/open a new weekly journal for today's date
		open_weekly_journal "$(date +"%Y-%m-%d")";
	elif [ "$#" -lt 2 ]; then
		cmd_usage "$1";
	fi
	case "$2" in
	review)
		# open previous monthly log & all of it's weekly logs
		local dt_start=$(date --date="1 month ago" +"%Y-%m-01")
		local dt_end=$(date --date="$dt_start +1 months -1 days" +"%Y-%m-%d")
		local files="$fJournals/$(date -d "$dt_start" +"%Y/%m")/monthly.log"
		while [[ "$dt_start" < "$dt_end" ]]; do
			# get the monday of the week
			local monday=$(get_week_monday $(date --date="$dt_start" +"%Y-%m-%d"))
			# add week log file to string
			files="$files $fJournals/$(date -d "$monday" +"%Y/%m/wk%V").log";
			# set start date to next week
			dt_start=$(date --date="$dt_start +1 weeks" +"%Y-%m-%d")
		done
		open_files "$files" true;
		;;
	open)
		if [ "$#" -ne 3 ]; then
			cmd_usage "$1";
		fi
		case "$3" in
		last-week)
			open_weekly_journal "$(date --date="1 week ago" +"%Y-%m-%d")";
			;;
		this-week)
			open_weekly_journal "$(date +"%Y-%m-%d")";
			;;
		next-week)
			open_weekly_journal "$(date --date="1 week" +"%Y-%m-%d")";
			;;
		last-month)
			open_monthly_journal "$(date --date="1 month ago" +"%Y-%m-%d")";
			;;
		this-month)
			open_monthly_journal "$(date +"%Y-%m-%d")";
			;;
		next-month)
			open_monthly_journal "$(date --date="1 month" +"%Y-%m-%d")";
			;;
		last-year)
			open_yearly_journal "$(date --date="1 year ago" +"%Y-%m-%d")";
			;;
		this-year)
			open_yearly_journal "$(date +"%Y-%m-%d")";
			;;
		next-year)
			open_yearly_journal "$(date --date="1 year" +"%Y-%m-%d")";
			;;
		*)
			if date -d "$3" "+%Y-%m-%d" >/dev/null 2>&1; then
				open_weekly_journal "$3";
			else
				printf "Usage: fern journal open <{this|next|last}-{week|month|year}>|<YYYY-MM-DD>";
			fi
			;;
		esac
		;;
	find)
		if [ "$#" -eq 3 ]; then
			find_items "$3" "$fJournals";
		elif [ "$#" -eq 4 ]; then
			find_items "$3" "$fJournals" "$4";
		fi
		;;
	*)
		cmd_usage "$1";
		;;
	esac
}

# $1 - action; $2 - note name | pattern string; $3 - note name | template name;
process_note() {
	if [ "$#" -lt 2 ]; then cmd_usage "$1"; fi
	case "$2" in
	open)
		if [ "$#" -lt 3 ]; then cmd_usage "$1"; fi
		# try to open a note with the exact name provided first
		local target=$(ext_checks "$3");
		if [ ! -e "$fNotes/$target" ]; then
			# search for the note by name given in other files
			local hits=$(find_items "$3" "$fNotes");
			local lines=$(echo "$hits" | wc -l);
			local chars=$(echo "$hits" | wc -m);
			printf "Error: Note not found with the name '%s'.\n" "$target";
			if [ $lines -eq 1 ] && [ $chars -gt 1 ]; then
				# if only 1 search record returned, open it
				open_files "$hits";
				exit 0;
			elif [ $lines -gt 1 ]; then
				# if more than 1 record, display possible files of interest to user
				printf "Several possible files of interest were found:\n%s\n" "$hits";
			fi
			exit 1;
		fi
		open_files "$fNotes/$target";
		;;
	add)
		if [ "$#" -lt 3 ]; then cmd_usage "$1"; fi
		local targetF=$(ext_checks "$3");
		if [ -e "$fNotes/$targetF" ]; then
			print_err "Error: Note already exists with the name '$targetF'.";
		fi
		# optional starting template provided
		if [ "$#" -eq 4 ]; then
			local targetT=$(ext_checks "$4");
			if [ ! -e "$fTemplates/$targetT" ]; then
				print_err "Error: Template not found with the name '$targetT'.";
			fi
			# create a new Note from a Template file
			cp "$fTemplates/$targetT" "$fNotes/$targetF";
		fi
		open_files "$fNotes/$targetF";
		;;
	del)
		if [ "$#" -lt 3 ]; then cmd_usage "$1"; fi
		local target="$(ext_checks "$3" )";
		if [ -e "$fNotes/$target" ]; then
			rm -f "$fNotes/$target";
			update_internal_links "$target" "\[!FILE REMOVED $target\]";
		else
			print_err "Error: Note not found with the name '$target'.";
		fi
		;;
	move)
		if [ "$#" -lt 3 ]; then cmd_usage "$1"; fi
		local targetOld=$(ext_checks "$3");
		if [ "$#" -lt 4 ]; then cmd_usage "$1"; fi
		local targetNew=$(ext_checks "$4");
		if [ ! -e "$fNotes/$targetOld" ]; then
			print_err "Error: Note not found with the name '$targetOld'.";
		fi
		if [ -e "$fNotes/$targetNew" ]; then
			print_err "Error: Note already exists with the name '$targetNew'.";
		fi
		mv "$fNotes/$targetOld" "$fNotes/$targetNew";
		update_internal_links "$targetOld" "$targetNew";
		;;
	find)
		if [ "$#" -lt 3 ]; then cmd_usage "$1";
		elif [ "$#" -eq 3 ]; then
			find_items "$3" "$fNotes";
		elif [ "$#" -eq 4 ]; then
			find_items "$3" "$fNotes" "$4";
		fi
		;;
	*)
		cmd_usage "$1";
		;;
	esac
}

# $1 - filename;
ext_checks() {
	# if not defined/empty OR check if ends in '.md'
	if [ -z "$1" ] || [[ "$1" == *.md ]]; then
		printf "%s" "$1"; # spit back as is
	else
		printf "%s.md" "$1"; # append if not passed
	fi
}

# $1 - journal date;
get_week_monday() {
	local dow=$(date -d "$1" +"%u");
	local monday=$(date -d "$1 -$((dow-1)) days" +%Y-%m-%d);
	echo $monday;
}

# $1 - journal date;
open_yearly_journal() {
	local yr=$(date -d "$1" +"%Y")
	# ensure year folder exists
	mkdir --parents "$fJournals/$yr"
	# check and setup yearly future log file if dne
	local target="$fJournals/$yr/future.log";
	if [ ! -e "$target" ]; then
		cp "$fl" "$target";
		sed --in-place "s/{{YEAR}}/$yr/g" "$target";
	fi
	open_files "$target";
}

# $1 - journal date;
open_monthly_journal() {
	local yr=$(date -d "$1" +"%Y")
	local mnth=$(date -d "$1" +"%m")
	# ensure month/year folder exists
	mkdir --parents "$fJournals/$yr/$mnth"
	# check and setup monthly log file if dne
	local target="$fJournals/$yr/$mnth/monthly.log";
	if [ ! -e "$target" ]; then
		cp "$ml" "$target";
		mnth_full=$(date -d $1 +"%B")
		sed --in-place "s/{{MONTH}}/$mnth_full/g" "$target";
		sed --in-place "s/{{YEAR}}/$yr/g" "$target";
	fi
	open_files "$target";
}

# $1 - journal date;
open_weekly_journal() {
	local monday=$(get_week_monday "$1")
	local mnth=$(date -d "$monday" +"%m")
	local yr=$(date -d "$monday" +"%Y")
	local wk=$(date -d "$monday" +"%V")
	# ensure month/year folder exists
	mkdir --parents "$fJournals/$yr/$mnth"
	# check and setup weekly log file if dne
	local target="$fJournals/$yr/$mnth/wk$wk.log";
	if [ ! -e "$target" ]; then
		cp "$wl" "$target";
		sed --in-place "s/{{WEEKNO}}/$wk/g" "$target";
	fi
	open_files "$target";
}

# $1 - old name; $2 - new name;
update_internal_links() {
	# update internal links in all Notes, Journals, Templates and Bookmarks
	find "$fNotes" -type f -print0 | xargs -0 sed --in-place "s/$1/$2/g";
	find "$fJournals" -type f -print0 | xargs -0 sed --in-place "s/$1/$2/g";
	find "$fTemplates" -type f -print0 | xargs -0 sed --in-place "s/$1/$2/g";
	sed --in-place "s/$1/$2/g" "$fBookmarks";
}

# $1 - pattern; $2 - Folder of items to search over; $3 - verbose flag;
find_items() {
	if [ "$#" -eq 3 ] && [ "$3" = "--verbose" ]; then
		find "$2" -name "*.{md,log}" -exec grep --dereference-recursive --line-number --ignore-case "$1" '{}' \+ | sort | less;
	else
		find "$2" -name "*.{md,log}" -exec grep --dereference-recursive --line-number --ignore-case --files-with-matches "$1" '{}' \+ | sort;
	fi
}

# $1 - Error message to print;
print_err() {
	printf "%s\n" "$1" >&2;
	exit 1;
}


main "${@}";
