#!/bin/bash
# Bash completion for fern command
#
# To manually install:
# Source this file in your .bashrc or copy to /etc/bash_completion.d/fern

_fern_completion() {
    local cur prev words cword
    _init_completion || return

    # all commands
    local commands="help vault bookmark journal note template find"
    # various Command Actions
    local vault_actions="create stat"
    local bookmark_actions="list add del"
    local journal_actions="open find review"
    local note_actions="add del open move find"
    local template_actions="list add del open move"
    # Journal Command date options
    local journal_dates="last-week this-week next-week last-month this-month next-month last-year this-year next-year"

    case $cword in
        1)
            # main command
            COMPREPLY=($(compgen -W "$commands" -- "$cur"))
            ;;
        2)
            # complete possible actions based on command
            case "${words[1]}" in
                vault)
                    COMPREPLY=($(compgen -W "$vault_actions" -- "$cur"))
                    ;;
                bookmark)
                    COMPREPLY=($(compgen -W "$bookmark_actions" -- "$cur"))
                    ;;
                journal)
                    COMPREPLY=($(compgen -W "$journal_actions" -- "$cur"))
                    ;;
                note)
                    COMPREPLY=($(compgen -W "$note_actions" -- "$cur"))
                    ;;
                template)
                    COMPREPLY=($(compgen -W "$template_actions" -- "$cur"))
                    ;;
            esac
            ;;
        3)
            # third-level arguments
            case "${words[1]}" in
                journal)
                    if [[ "${words[2]}" == "open" ]]; then
                        COMPREPLY=($(compgen -W "$journal_dates" -- "$cur"))
                    fi
                    ;;
                bookmark)
                    if [[ "${words[2]}" == "add" || "${words[2]}" == "del" ]]; then
                        if [[ -n "$FERN_VAULT" && -d "$FERN_VAULT/notes" ]]; then
                            local notes=$(find "$FERN_VAULT/notes" -name "*.md" -exec basename {} .md \; 2>/dev/null)
                            COMPREPLY=($(compgen -W "$notes" -- "$cur"))
                        fi
                    fi
                    ;;
                note)
                    if [[ "${words[2]}" == "open" || "${words[2]}" == "del" || "${words[2]}" == "move" ]]; then
                        if [[ -n "$FERN_VAULT" && -d "$FERN_VAULT/notes" ]]; then
                            local notes=$(find "$FERN_VAULT/notes" -name "*.md" -exec basename {} .md \; 2>/dev/null)
                            COMPREPLY=($(compgen -W "$notes" -- "$cur"))
                        fi
                    fi
                    ;;
                template)
                    if [[ "${words[2]}" == "open" || "${words[2]}" == "del" || "${words[2]}" == "move" ]]; then
                        if [[ -n "$FERN_VAULT" && -d "$FERN_VAULT/templates" ]]; then
                            local templates=$(find "$FERN_VAULT/templates" -name "*" -type f -exec basename {} \; 2>/dev/null)
                            COMPREPLY=($(compgen -W "$templates" -- "$cur"))
                        fi
                    fi
                    ;;
            esac
            ;;
        4)
            # fourth-level arguments
            case "${words[1]}" in
                note)
                    if [[ "${words[2]}" == "add" ]]; then
                        # template names for note add command
                        if [[ -n "$FERN_VAULT" && -d "$FERN_VAULT/templates" ]]; then
                            local templates=$(find "$FERN_VAULT/templates" -name "*" -type f -exec basename {} \; 2>/dev/null)
                            COMPREPLY=($(compgen -W "$templates" -- "$cur"))
                        fi
                    fi
                    ;;
            esac
            # we don't provide completion for new name (note/template)
            ;;
    esac
    return 0
}

# Handle special completion cases for partial matches
_fern_special_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    # Handle "j" -> "journal" completion
    if [[ "$cur" == "j" && ${#COMP_WORDS[@]} -eq 2 ]]; then
        COMPREPLY=("journal")
    # Handle "next-" prefix completions
    elif [[ "$cur" == next-* && "${COMP_WORDS[1]}" == "journal" && "${COMP_WORDS[2]}" == "open" ]]; then
        local next_options="next-week next-month next-year"
        COMPREPLY=($(compgen -W "$next_options" -- "$cur"))
    # Handle "last-" prefix completions
    elif [[ "$cur" == last-* && "${COMP_WORDS[1]}" == "journal" && "${COMP_WORDS[2]}" == "open" ]]; then
        local last_options="last-week last-month last-year"
        COMPREPLY=($(compgen -W "$last_options" -- "$cur"))
    # Handle "this-" prefix completions
    elif [[ "$cur" == this-* && "${COMP_WORDS[1]}" == "journal" && "${COMP_WORDS[2]}" == "open" ]]; then
        local this_options="this-week this-month this-year"
        COMPREPLY=($(compgen -W "$this_options" -- "$cur"))
    else
        # no match found
        return 1
    fi
    return 0
}

# Main completion function that handles both regular and special cases
_fern_main_completion() {
    # Try special completion first
    if _fern_special_completion; then
        return 0
    fi
    # Fall back to regular completion
    _fern_completion
}

# Register the completion function
complete -F _fern_main_completion fern
