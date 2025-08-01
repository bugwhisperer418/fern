# Fish completion for fern command
#
# To manually install:
# Copy this file to ~/.config/fish/completions/fern.fish
# or to /usr/share/fish/completions/fern.fish

# Main commands
complete -c fern -f -n '__fish_use_subcommand' -a 'help' -d 'Show help information'
complete -c fern -f -n '__fish_use_subcommand' -a 'vault' -d 'Vault operations'
complete -c fern -f -n '__fish_use_subcommand' -a 'bookmark' -d 'Bookmark management'
complete -c fern -f -n '__fish_use_subcommand' -a 'journal' -d 'Journal operations'
complete -c fern -f -n '__fish_use_subcommand' -a 'note' -d 'Note management'
complete -c fern -f -n '__fish_use_subcommand' -a 'template' -d 'Template management'

# Vault subcommands
complete -c fern -f -n '__fish_seen_subcommand_from vault' -a 'create' -d 'Create a new vault'
complete -c fern -f -n '__fish_seen_subcommand_from vault' -a 'stat' -d 'Show vault statistics'

# Bookmark subcommands
complete -c fern -f -n '__fish_seen_subcommand_from bookmark' -a 'list' -d 'List bookmarks'
complete -c fern -f -n '__fish_seen_subcommand_from bookmark' -a 'add' -d 'Add a bookmark'
complete -c fern -f -n '__fish_seen_subcommand_from bookmark' -a 'del' -d 'Delete a bookmark'

# Journal subcommands
complete -c fern -f -n '__fish_seen_subcommand_from journal' -a 'open' -d 'Open journal entry'
complete -c fern -f -n '__fish_seen_subcommand_from journal' -a 'find' -d 'Find journal entries'
complete -c fern -f -n '__fish_seen_subcommand_from journal' -a 'review' -d 'Review journal entries'

# Note subcommands
complete -c fern -f -n '__fish_seen_subcommand_from note' -a 'add' -d 'Add a new note'
complete -c fern -f -n '__fish_seen_subcommand_from note' -a 'del' -d 'Delete a note'
complete -c fern -f -n '__fish_seen_subcommand_from note' -a 'open' -d 'Open a note'
complete -c fern -f -n '__fish_seen_subcommand_from note' -a 'move' -d 'Move a note'
complete -c fern -f -n '__fish_seen_subcommand_from note' -a 'find' -d 'Find notes'

# Template subcommands
complete -c fern -f -n '__fish_seen_subcommand_from template' -a 'list' -d 'List templates'
complete -c fern -f -n '__fish_seen_subcommand_from template' -a 'add' -d 'Add a template'
complete -c fern -f -n '__fish_seen_subcommand_from template' -a 'del' -d 'Delete a template'
complete -c fern -f -n '__fish_seen_subcommand_from template' -a 'open' -d 'Open a template'
complete -c fern -f -n '__fish_seen_subcommand_from template' -a 'move' -d 'Move a template'

# Journal date options for 'journal open'
complete -c fern -f -n '__fish_seen_subcommand_from journal; and __fish_seen_subcommand_from open' -a 'last-week' -d 'Last week journal'
complete -c fern -f -n '__fish_seen_subcommand_from journal; and __fish_seen_subcommand_from open' -a 'this-week' -d 'This week journal'
complete -c fern -f -n '__fish_seen_subcommand_from journal; and __fish_seen_subcommand_from open' -a 'next-week' -d 'Next week journal'
complete -c fern -f -n '__fish_seen_subcommand_from journal; and __fish_seen_subcommand_from open' -a 'last-month' -d 'Last month journal'
complete -c fern -f -n '__fish_seen_subcommand_from journal; and __fish_seen_subcommand_from open' -a 'this-month' -d 'This month journal'
complete -c fern -f -n '__fish_seen_subcommand_from journal; and __fish_seen_subcommand_from open' -a 'next-month' -d 'Next month journal'
complete -c fern -f -n '__fish_seen_subcommand_from journal; and __fish_seen_subcommand_from open' -a 'last-year' -d 'Last year journal'
complete -c fern -f -n '__fish_seen_subcommand_from journal; and __fish_seen_subcommand_from open' -a 'this-year' -d 'This year journal'
complete -c fern -f -n '__fish_seen_subcommand_from journal; and __fish_seen_subcommand_from open' -a 'next-year' -d 'Next year journal'

# Function to complete note names from vault
function __fern_complete_notes
    if test -n "$FERN_VAULT" -a -d "$FERN_VAULT/notes"
        find "$FERN_VAULT/notes" -name "*.md" -exec basename {} .md \; 2>/dev/null
    end
end

# Function to complete template names from vault
function __fern_complete_templates
    if test -n "$FERN_VAULT" -a -d "$FERN_VAULT/templates"
        find "$FERN_VAULT/templates" -name "*" -type f -exec basename {} \; 2>/dev/null
    end
end

# Complete note names for bookmark add/del
complete -c fern -f -n '__fish_seen_subcommand_from bookmark; and __fish_seen_subcommand_from add' -a '(__fern_complete_notes)'
complete -c fern -f -n '__fish_seen_subcommand_from bookmark; and __fish_seen_subcommand_from del' -a '(__fern_complete_notes)'

# Complete note names for note open/del/move
complete -c fern -f -n '__fish_seen_subcommand_from note; and __fish_seen_subcommand_from open' -a '(__fern_complete_notes)'
complete -c fern -f -n '__fish_seen_subcommand_from note; and __fish_seen_subcommand_from del' -a '(__fern_complete_notes)'
complete -c fern -f -n '__fish_seen_subcommand_from note; and __fish_seen_subcommand_from move' -a '(__fern_complete_notes)'

# Complete template names for template open/del/move
complete -c fern -f -n '__fish_seen_subcommand_from template; and __fish_seen_subcommand_from open' -a '(__fern_complete_templates)'
complete -c fern -f -n '__fish_seen_subcommand_from template; and __fish_seen_subcommand_from del' -a '(__fern_complete_templates)'
complete -c fern -f -n '__fish_seen_subcommand_from template; and __fish_seen_subcommand_from move' -a '(__fern_complete_templates)'

# Complete template names for note add (fourth argument)
complete -c fern -f -n '__fish_seen_subcommand_from note; and __fish_seen_subcommand_from add' -a '(__fern_complete_templates)'