#! /usr/bin/env bash
#
# Author: Andie Keller <andie@bugwhisperer.dev>

#{{{ Shell settings
set -o errexit;		# abort on nonzero exitstatus
set -o nounset;		# abort on unbound variable
#}}}

#{{{ Variables
fVersion="0.2.1";
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
	if [ "$editor" = "NONE" ]; then
		local editors='nano joe vim vi helix nvim'; # common terminal editors to check as fallback
		local display="${DISPLAY:-NONE}";
		if [ "$display" = "NONE" ]; then
			editors="$editors code subl gedit kate"; # add some common GUI editors to check too
		fi
		for e in $editors; do
			if type "$e" >/dev/null 2>/dev/null; then
				editor="$e";
			fi
			if [ "$editor" != "NONE" ]; then
				break;
			fi
		done
		# editor is still none after checking common ones, so raise an error
		print_error "Error: No default editor found! Set $EDITOR, $VISUAL or $FCEDIT to your default editor.";
	fi
	echo "$editor";
}

# open N file(s) in an editor, passed a list of files
# $@ - [file1, ..., fileN]
open_files() {
	local editor
	editor=$(default_editor);
	# if we are dealing with editor that can handle multiple windows, assume there's mutiple files
	if [ "$editor" == "nvim" ] || [ "$editor" == "vim" ] || [ "$editor" == "vi" ]; then
		exec "$editor" -O "$@";
	# special open commands for some editors
	elif [ "$editor" == "kate" ]; then
		exec "$editor" -b "$@";
	elif [ "$editor" == "code" ]; then
		exec "$editor" -n "$@";
	else
		# covers all other editors for multi-files
		# & also covers all single file openings
		exec "$editor" "$@";
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
	printf "USAGE:\n  fern COMMAND [ACTION [ARGS...]]\n\nCOMMANDS:\n  help\t\t\t\t\t\t\tdisplay Fern help\n\n  vault create <path>\t\t\t\t\tsetup a new Fern Vault\n  vault stat\t\t\t\t\t\tget stats of Fern Vault\n\n  bookmark list\t\t\t\t\t\tlist out all Bookmarks\n  bookmark add <note_name>\t\t\t\tadd a note to Bookmarks\n  bookmark del <note_name>\t\t\t\tremove a note from Bookmarks\n\n  find <pattern> [--verbose|-v] [--quiet|-q] [--notes|-n] [--journals|-j]\tsearch Notes and Journals for matching pattern (interactive by default)\n\n  journal\t\t\t\t\t\topens today's weekly Journal log\n  journal open <{this|next|last}-{week|month|year}>\topen commonly accessed Journal log\n  journal open <YYYY-MM-DD>\t\t\t\topen a specific Journal log\n  journal find <pattern> [--verbose|--quiet]\t\tsearch Journals for matching pattern\n  journal review <month|year>\t\t\t\topen Journal logs for year|month to review/reflect\n\n  note add <note> [<template>]\t\t\t\tadd a new Note\n  note del <note>\t\t\t\t\tdelete a Note\n  note open <note>\t\t\t\t\topen a Note\n  note move <old_note> <new_note>\t\t\tmove/rename a Note\n  note find <pattern> [--verbose|--quiet]\t\tsearch Notes for matching pattern\n\n  template list\t\t\t\t\t\tget list of Template files\n  template add <template>\t\t\t\tadd a new Template\n  template del <template>\t\t\t\tdelete a Template\n  template open <template>\t\t\t\topen a Template\n  template move <old_template> <new_template>\t\tmove/rename a Template\n\nFor more in-depth documentation and advanced usage see the fern(1) manpage (\"man fern\") and/or https://sr.ht/~bugwhisperer/fern/\n";
}

cmd_usage() {
	case "$1" in
	vault)
		printf "Usage:\n  fern vault stat\n  fern vault create <path>\n";
		;;
	bookmark)
		printf "Usage:\n  fern bookmark list\n  fern bookmark add|del <note_name>\n";
		;;
	find)
		printf "Usage:\n  fern find <pattern> [--verbose|-v] [--quiet|-q] [--notes|-n] [--journals|-j]\n  Search Notes and Journals for matching pattern.\n  Default: interactive file selection from search results\n  --verbose|-v: show matching lines with context (disables interactive mode)\n  --quiet|-q: show file list without interactive selection\n  --notes|-n: search only Notes\n  --journals|-j: search only Journals\n";
		;;
	journal)
		printf "Usage:\n  fern journal\n  fern journal open <{this|next|last}-{week|month|year}>\n  fern journal open <YYYY-MM-DD>\n  fern journal find <search_pattern> [--verbose|--quiet]\n  fern journal review <month|year>\n";
		;;
	note)
		printf "Usage:\n  fern note\n  fern note del|open <note_name>\n  fern note add <note_name> [<template_name>]\n  fern note find <search_pattern> [--verbose|--quiet]\n  fern note move <old_note> <new_note>\n  fern note append <template_name> [<note_name>]\n";
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
	find)
		process_find "$@";
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
		local cntB
		cntB=$(wc --lines < "$fBookmarks");
		local cntN
		cntN=$(find "$fNotes" | wc --lines);
		local cntJ
		cntJ=$(find "$fJournals" | wc --lines);
		local cntT
		cntT=$(find "$fTemplates" | wc --lines);
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
		local target
		target=$(ext_checks "$3");
		if [ ! -e "$fNotes/$target" ]; then
			print_err "Error: Note not found with the name '$target'.";
		elif [ "$(awk "/$target/" < "$fBookmarks" | wc --lines)" -eq 0 ]; then
			printf "%s" "$target" | tee --append "$fBookmarks" >/dev/null;
			sort "$fBookmarks" -o "$fBookmarks";
		fi
		;;
	del)
		if [ "$#" -ne 3 ]; then cmd_usage "$1"; fi
		local target
		target=$(ext_checks "$3");
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
	if [ "$#" -eq 2 ] && ["$2" == "list"]; then
		ls "$fTemplates" -1;
	elif [ "$#" -lt 3 ]; then
		cmd_usage "$1";
	fi
	case "$2" in
	open)
		local target
		target=$(ext_checks "$3");
		if [ ! -e "$fTemplates/$target" ]; then
			print_err "Error: Template not found with the name '$target'.";
		fi
		open_files "$fTemplates/$target";
		;;
	add)
		local target
		target=$(ext_checks "$3");
		if [ -e "$target" ]; then
			print_err "Error: Template already exists with that name '$target'.";
		fi
		open_files "$fTemplates/$target";
		;;
	del)
		local target
		target=$(ext_checks "$3");
		if [ ! -e "$fTemplates/$target" ]; then
			print_err "Error: Template not found with the name '$target'.";
		fi
		rm -f "$fTemplates/$target";
		;;
	move)
		local oldT
		oldT=$(ext_checks "$3");
		if [ "$#" -lt 4 ]; then cmd_usage "$1"; fi
		local newT
		newT=$(ext_checks "$4");
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
		local log
		log=$(get_weekly_log "$(date +"%Y-%m-%d")");
	elif [ "$#" -lt 3 ]; then
		cmd_usage "$1";
	fi
	case "$2" in
	review)
		case "$3" in
		month)
			# open previous monthly log & all of it's weekly logs
			local dt_start
			dt_start=$(date --date="1 month ago" +"%Y-%m-01")
			local files
			files="$fJournals/$(date --date="$dt_start" +"%Y/%m")/*.log"
			open_files $files;
			;;
		year)
			# open previous year's future log and all of last year's monthly logs
			local dt_start
			dt_start=$(date --date="1 year ago" +"%Y-01-01")
			local yearFile
			yearFile="$fJournals/$(date --date="$dt_start" +"%Y")/future.log"
			local monthFiles
			monthFiles="$fJournals/$(date --date="$dt_start" +"%Y")/*/monthly.log"
			open_files $yearFile $monthFiles;
			;;
		*)
			printf "Usage: fern journal review <month|year>\n";
			;;
		esac
		;;
	open)
		local log
		case "$3" in
		last-week)
			log=$(get_weekly_log "$(date --date="1 week ago" +"%Y-%m-%d")");
			;;
		this-week)
			log=$(get_weekly_log "$(date +"%Y-%m-%d")");
			;;
		next-week)
			log=$(get_weekly_log "$(date --date="1 week" +"%Y-%m-%d")");
			;;
		last-month)
			log=$(get_monthly_log "$(date --date="1 month ago" +"%Y-%m-%d")");
			;;
		this-month)
			log=$(get_monthly_log "$(date +"%Y-%m-%d")");
			;;
		next-month)
			log=$(get_monthly_log "$(date --date="1 month" +"%Y-%m-%d")");
			;;
		last-year)
			log=$(get_yearly_log "$(date --date="1 year ago" +"%Y-%m-%d")");
			;;
		this-year)
			log=$(get_yearly_log "$(date +"%Y-%m-%d")");
			;;
		next-year)
			log=$(get_yearly_log "$(date --date="1 year" +"%Y-%m-%d")");
			;;
		*)
			if date -d "$3" "+%Y-%m-%d" >/dev/null 2>&1; then
				log=$(get_weekly_log "$3");
			else
				printf "Usage: fern journal open <{this|next|last}-{week|month|year}>|<YYYY-MM-DD>\n";
				exit 1
			fi
			;;
		esac
		open_files $log;
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
	if [ "$#" -lt 3 ]; then cmd_usage "$1"; fi
	case "$2" in
	open)
		# try to open a note with the exact name provided
		local target
		target=$(ext_checks "$3");
		if [ ! -e "$fNotes/$target" ]; then
			print_err "Error: Note not found with the name '$target'.";
		fi
		open_files "$fNotes/$target";
		;;
	add)
		local targetF
		targetF=$(ext_checks "$3");
		if [ -e "$fNotes/$targetF" ]; then
			print_err "Error: Note already exists with the name '$targetF'.";
		fi
		# optional starting template provided
		if [ "$#" -eq 4 ]; then
			local targetT
			targetT=$(ext_checks "$4");
			if [ ! -e "$fTemplates/$targetT" ]; then
				print_err "Error: Template not found with the name '$targetT'.";
			fi
			# create a new Note from a Template file
			cp "$fTemplates/$targetT" "$fNotes/$targetF";
		fi
		open_files "$fNotes/$targetF";
		;;
	del)
		local target
		target=$(ext_checks "$3");
		if [ -e "$fNotes/$target" ]; then
			rm -f "$fNotes/$target";
			update_internal_links "$target" "\[!FILE REMOVED $target\]";
		else
			print_err "Error: Note not found with the name '$target'.";
		fi
		;;
	move)
		local targetOld
		targetOld=$(ext_checks "$3");
		if [ ! -e "$fNotes/$targetOld" ]; then
			print_err "Error: Note not found with the name '$targetOld'.";
		fi
		if [ "$#" -lt 4 ]; then cmd_usage "$1"; fi
		local targetNew
		targetNew=$(ext_checks "$4");
		if [ -e "$fNotes/$targetNew" ]; then
			print_err "Error: Note already exists with the name '$targetNew'.";
		fi
		mv "$fNotes/$targetOld" "$fNotes/$targetNew";
		update_internal_links "$targetOld" "$targetNew";
		;;
	find)
		if [ "$#" -eq 3 ]; then
			find_items "$3" "$fNotes";
		elif [ "$#" -eq 4 ]; then
			find_items "$3" "$fNotes" "$4";
		else
			cmd_usage "$1";
		fi
		;;
	*)
		cmd_usage "$1";
		;;
	esac
}

# $1 - command; $2+ - arguments (pattern and flags);
process_find() {
	if [ "$#" -lt 2 ]; then cmd_usage "$1"; fi

	local pattern=""
	local verbose=false
	local interactive=true  # Default to interactive for user commands
	local search_notes=false
	local search_journals=false

	# Parse arguments
	shift # remove 'find' command
	while [ "$#" -gt 0 ]; do
		case "$1" in
		--verbose|-v)
			verbose=true
			interactive=false  # verbose output incompatible with interactive
			;;
		--quiet|-q)
			interactive=false
			;;
		--notes|-n)
			search_notes=true
			;;
		--journals|-j)
			search_journals=true
			;;
		*)
			if [ -z "$pattern" ]; then
				pattern="$1"
			else
				cmd_usage "find"
			fi
			;;
		esac
		shift
	done

	if [ -z "$pattern" ]; then
		cmd_usage "find"
	fi

	# Default: search both if no specific flags were passed
	if [ "$search_notes" = false ] && [ "$search_journals" = false ]; then
		search_notes=true
		search_journals=true
	fi

	# Build search directories array
	local search_dirs=()
	if [ "$search_notes" = true ]; then
		search_dirs+=("$fNotes")
	fi
	if [ "$search_journals" = true ]; then
		search_dirs+=("$fJournals")
	fi

	# Execute search
	if [ "$interactive" = true ]; then
		# Capture file list for interactive selection
		local results
		results=$(find "${search_dirs[@]}" -regex ".*\.\(md\|log\)" -exec grep --dereference-recursive --line-number --ignore-case --files-with-matches "$pattern" '{}' \+ 2>/dev/null | sort)
		interactive_file_selection "$results"
	elif [ "$verbose" = true ]; then
		find "${search_dirs[@]}" -regex ".*\.\(md\|log\)" -exec grep --dereference-recursive --line-number --ignore-case "$pattern" '{}' \+ 2>/dev/null | sort | less;
	else
		local results
		results=$(find "${search_dirs[@]}" -regex ".*\.\(md\|log\)" -exec grep --dereference-recursive --line-number --ignore-case --files-with-matches "$pattern" '{}' \+ 2>/dev/null | sort)
		strip_vault_prefix "$results"
	fi
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
	local dow
	dow=$(date -d "$1" +"%u");
	local monday
	monday=$(date -d "$1 -$((dow-1)) days" +%Y-%m-%d);
	echo "$monday";
}

# $1 - journal date;
get_yearly_log() {
	local yr
	yr=$(date -d "$1" +"%Y")
	# ensure year folder exists
	mkdir --parents "$fJournals/$yr"
	# check and setup yearly future log file if dne
	local target="$fJournals/$yr/future.log";
	if [ ! -e "$target" ]; then
		cp "$fl" "$target";
		sed --in-place "s/{{YEAR}}/$yr/g" "$target";
	fi
	echo "$target";
}

# $1 - journal date;
get_monthly_log() {
	local yr
	yr=$(date -d "$1" +"%Y")
	local mnth
	mnth=$(date -d "$1" +"%m")
	# ensure month/year folder exists
	mkdir --parents "$fJournals/$yr/$mnth"
	# check and setup monthly log file if dne
	local target="$fJournals/$yr/$mnth/monthly.log";
	if [ ! -e "$target" ]; then
		cp "$ml" "$target";
		mnth_full=$(date -d "$1" +"%B")
		sed --in-place "s/{{MONTH}}/$mnth_full/g" "$target";
		sed --in-place "s/{{YEAR}}/$yr/g" "$target";
	fi
	echo "$target";
}

# $1 - journal date;
get_weekly_log() {
	local monday
	monday=$(get_week_monday "$1")
	local mnth
	mnth=$(date -d "$monday" +"%m")
	local yr
	yr=$(date -d "$monday" +"%Y")
	local wk
	wk=$(date -d "$monday" +"%V")
	# ensure month/year folder exists
	mkdir --parents "$fJournals/$yr/$mnth"
	# check and setup weekly log file if dne
	local target="$fJournals/$yr/$mnth/wk$wk.log";
	if [ ! -e "$target" ]; then
		cp "$wl" "$target";
		sed --in-place "s/{{WEEKNO}}/$wk/g" "$target";
		sed --in-place "s/{{YEAR}}/$yr/g" "$target";
	fi
	echo "$target";
}

# $1 - old name; $2 - new name;
update_internal_links() {
	# update internal links in all Notes, Journals, Templates and Bookmarks
	find "$fNotes" -type f -print0 | xargs -0 sed --in-place "s/$1/$2/g";
	find "$fJournals" -type f -print0 | xargs -0 sed --in-place "s/$1/$2/g";
	find "$fTemplates" -type f -print0 | xargs -0 sed --in-place "s/$1/$2/g";
	sed --in-place "s/$1/$2/g" "$fBookmarks";
}

# $1 - pattern; $2 - Folder of items to search over; $3 - optional flag (--verbose or --quiet);
find_items() {
	local pattern="$1"
	local search_dir="$2"
	local flag="${3:-}"

	if [ "$flag" = "--verbose" ]; then
		find "$search_dir" -regex ".*\.\(md\|log\)" -exec grep --dereference-recursive --line-number --ignore-case "$pattern" '{}' \+ | sort | less;
	elif [ "$flag" = "--quiet" ]; then
		local results
		results=$(find "$search_dir" -regex ".*\.\(md\|log\)" -exec grep --dereference-recursive --line-number --ignore-case --files-with-matches "$pattern" '{}' \+ | sort)
		strip_vault_prefix "$results"
	else
		# Default: interactive mode
		local results
		results=$(find "$search_dir" -regex ".*\.\(md\|log\)" -exec grep --dereference-recursive --line-number --ignore-case --files-with-matches "$pattern" '{}' \+ | sort)
		interactive_file_selection "$results"
	fi
}

# Interactive Utility Functions

# Strip FERN_VAULT prefix from file paths for display
# $1 - file path or newline-separated list of file paths
strip_vault_prefix() {
	if [ -n "$FERN_VAULT" ]; then
		echo "$1" | sed "s|^$FERN_VAULT/||g"
	else
		echo "$1"
	fi
}

# Simple yes/no prompt with customizable message
# $1 - prompt message; Returns: 0 for yes, 1 for no
prompt_yes_no() {
	local prompt_msg="$1"
	printf "%s (y/n): " "$prompt_msg"
	read -r choice
	case "$choice" in
		y|Y|yes|Yes|YES)
			return 0
			;;
		*)
			return 1
			;;
	esac
}


# Interactive file selection and opening with pagination
# $1 - newline-separated list of file paths
interactive_file_selection() {
	local file_list="$1"

	if [ -z "$file_list" ]; then
		printf "No matching files found.\n"
		return 1
	fi

	# Convert to array for numbering
	local files=()
	while IFS= read -r line; do
		[ -n "$line" ] && files+=("$line")
	done <<< "$file_list"

	local count=${#files[@]}

	if [ "$count" -eq 0 ]; then
		printf "No matching files found.\n"
		return 1
	elif [ "$count" -eq 1 ]; then
		local display_file
		display_file=$(strip_vault_prefix "${files[0]}")
		printf "Found 1 matching file:\n  %s\n\n" "$display_file"
		if prompt_yes_no "Open this file?"; then
			printf "Opening: %s\n" "$display_file"
			open_files "${files[0]}"
		fi
	else
		# Check if we need pagination
		local terminal_height
		terminal_height=$(tput lines 2>/dev/null || echo "24")
		local available_lines=$((terminal_height - 6)) # Reserve lines for header, prompt, etc.

		if [ "$count" -le "$available_lines" ]; then
			# Show all results at once
			while true; do
				printf "\033[2J\033[H"
				printf "Found %d matching files:\n\n" "$count"
				for i in "${!files[@]}"; do
					local display_file
					display_file=$(strip_vault_prefix "${files[i]}")
					printf "%2d) %s\n" $((i+1)) "$display_file"
				done

				# Show prompt and get selection
				printf "\nEnter the number of the file to open (1-%d), or 'q' to quit: " "$count"
				read -r choice

				# Validate and open selection
				if [[ "$choice" =~ ^[0-9]+$ ]]; then
					if [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
						local selected_file="${files[$((choice-1))]}"
						local display_file
						display_file=$(strip_vault_prefix "$selected_file")
						printf "Opening: %s\n" "$display_file"
						open_files "$selected_file"
						return 0
					else
						printf "Invalid selection. Please enter a number from 1-%d. Press Enter to continue..." "$count"
						read -r
					fi
				elif [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
					printf "Cancelled.\n"
					return 0
				else
					printf "Invalid input. Please enter a number (1-%d) or 'q' to quit. Press Enter to continue..." "$count"
					read -r
				fi
			done
		else
			# Use pagination for large result sets
			paginated_file_selection "${files[@]}"
		fi
	fi
}

# Paginated file selection for large result sets
# $@ - array of file paths
paginated_file_selection() {
	local files=("$@")
	local count=${#files[@]}
	local terminal_height
	terminal_height=$(tput lines 2>/dev/null || echo "24")
	local page_size=$((terminal_height - 8)) # Reserve more lines for navigation
	local current_page=0
	local total_pages=$(((count + page_size - 1) / page_size))

	while true; do
		printf "\033[2J\033[H"
		local start_idx=$((current_page * page_size))
		local end_idx=$(((current_page + 1) * page_size))
		if [ "$end_idx" -gt "$count" ]; then
			end_idx=$count
		fi

		printf "Found %d matching files (Page %d/%d):\n\n" "$count" $((current_page + 1)) "$total_pages"

		# Show files for current page
		for i in $(seq $start_idx $((end_idx - 1))); do
			local display_file
			display_file=$(strip_vault_prefix "${files[i]}")
			printf "%2d) %s\n" $((i + 1)) "$display_file"
		done

		# Build navigation options dynamically
		local nav_options=""
		if [ $((current_page + 1)) -lt "$total_pages" ]; then
			nav_options="[n]ext page"
		fi
		if [ "$current_page" -gt 0 ]; then
			if [ -n "$nav_options" ]; then
				nav_options="$nav_options, [p]revious page"
			else
				nav_options="[p]revious page"
			fi
		fi
		if [ -n "$nav_options" ]; then
			nav_options="$nav_options, "
		fi
		nav_options="${nav_options}[q]uit"

		printf "\nNavigation: %s\n" "$nav_options"
		printf "Enter file number (%d-%d) to open, or navigation command: " $((start_idx + 1)) "$end_idx"
		read -r choice

		case "$choice" in
			n|N|next)
				if [ $((current_page + 1)) -lt "$total_pages" ]; then
					current_page=$((current_page + 1))
				else
					printf "Already on last page. Press Enter to continue..."
					read -r
				fi
				;;
			p|P|prev|previous)
				if [ "$current_page" -gt 0 ]; then
					current_page=$((current_page - 1))
				else
					printf "Already on first page. Press Enter to continue..."
					read -r
				fi
				;;
			q|Q|quit)
				return 0
				;;
			*)
				if [[ "$choice" =~ ^[0-9]+$ ]]; then
					# Only accept numbers from the current page
					if [ "$choice" -ge $((start_idx + 1)) ] && [ "$choice" -le "$end_idx" ]; then
						local selected_file="${files[$((choice-1))]}"
						local display_file
						display_file=$(strip_vault_prefix "$selected_file")
						printf "Opening: %s\n" "$display_file"
						open_files "$selected_file"
						return 0
					else
						printf "Please enter a number from %d-%d for files on this page. Press Enter to continue..." $((start_idx + 1)) "$end_idx"
						read -r
					fi
				else
					printf "Invalid input. Press Enter to continue..."
					read -r
				fi
				;;
		esac
	done
}

# $1 - Error message to print;
print_err() {
	printf "%s\n" "$1" >&2;
	exit 1;
}


main "${@}";
