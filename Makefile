# Makefile for Fern - A knowledge management system
# Author: Andie Keller <andie@bugwhisperer.dev>

# Installation paths
PREFIX ?= $(HOME)/.local
BINDIR = $(PREFIX)/bin
MANDIR = $(PREFIX)/share/man/man1
BASH_COMPLETIONDIR = $(PREFIX)/share/bash-completion/completions
ZSH_COMPLETIONDIR = $(PREFIX)/share/zsh/site-functions
FISH_COMPLETIONDIR = $(PREFIX)/share/fish/completions

# System-wide installation paths (requires sudo)
SYSTEM_PREFIX = /usr/local
SYSTEM_BINDIR = $(SYSTEM_PREFIX)/bin
SYSTEM_MANDIR = $(SYSTEM_PREFIX)/share/man/man1
SYSTEM_BASH_COMPLETIONDIR = /etc/bash_completion.d
SYSTEM_ZSH_COMPLETIONDIR = /usr/local/share/zsh/site-functions
SYSTEM_FISH_COMPLETIONDIR = /usr/local/share/fish/completions

# Source files
SRCDIR = src
DOCDIR = docs
SCRIPT = $(SRCDIR)/fern.sh
BASH_COMPLETION = $(SRCDIR)/fern_completion.bash
ZSH_COMPLETION = $(SRCDIR)/_fern
FISH_COMPLETION = $(SRCDIR)/fern.fish
MANPAGE = $(DOCDIR)/fern.1

# Installed files
INSTALLED_SCRIPT = $(BINDIR)/fern
INSTALLED_MAN = $(MANDIR)/fern.1
INSTALLED_BASH_COMPLETION = $(BASH_COMPLETIONDIR)/fern
INSTALLED_ZSH_COMPLETION = $(ZSH_COMPLETIONDIR)/_fern
INSTALLED_FISH_COMPLETION = $(FISH_COMPLETIONDIR)/fern.fish

SYSTEM_INSTALLED_SCRIPT = $(SYSTEM_BINDIR)/fern
SYSTEM_INSTALLED_MAN = $(SYSTEM_MANDIR)/fern.1
SYSTEM_INSTALLED_BASH_COMPLETION = $(SYSTEM_BASH_COMPLETIONDIR)/fern
SYSTEM_INSTALLED_ZSH_COMPLETION = $(SYSTEM_ZSH_COMPLETIONDIR)/_fern
SYSTEM_INSTALLED_FISH_COMPLETION = $(SYSTEM_FISH_COMPLETIONDIR)/fern.fish

.PHONY: all install install-system uninstall uninstall-system clean help

all: help

help:
	@echo "Fern Installation Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  install         - Install fern to user directory ($(PREFIX))"
	@echo "  install-system  - Install fern system-wide (requires sudo)"
	@echo "  uninstall       - Remove fern from user directory"
	@echo "  uninstall-system - Remove fern from system (requires sudo)"
	@echo "  clean           - Clean temporary files"
	@echo "  help            - Show this help message"
	@echo ""
	@echo "Installation paths (user):"
	@echo "  Binary: $(BINDIR)/fern"
	@echo "  Manual: $(MANDIR)/fern.1"
	@echo "  Completion: Installed for current shell ($(SHELL))"
	@echo ""
	@echo "You can override PREFIX: make install PREFIX=/usr/local"

install: $(INSTALLED_SCRIPT) $(INSTALLED_MAN)
	@echo "Installing completion for current shell..."
	@if echo "$(SHELL)" | grep -q "zsh"; then \
		echo "Installing ZSH completion..."; \
		mkdir -p $(ZSH_COMPLETIONDIR); \
		cp $(ZSH_COMPLETION) $(INSTALLED_ZSH_COMPLETION); \
		echo "✓ ZSH completion installed"; \
	elif echo "$(SHELL)" | grep -q "fish"; then \
		echo "Installing Fish completion..."; \
		mkdir -p $(FISH_COMPLETIONDIR); \
		cp $(FISH_COMPLETION) $(INSTALLED_FISH_COMPLETION); \
		echo "✓ Fish completion installed"; \
	else \
		echo "Installing Bash completion..."; \
		mkdir -p $(BASH_COMPLETIONDIR); \
		cp $(BASH_COMPLETION) $(INSTALLED_BASH_COMPLETION); \
		echo "✓ Bash completion installed"; \
	fi
	@echo ""
	@echo "✓ Fern installed successfully to $(PREFIX)"
	@echo ""
	@echo "To get started:"
	@echo "  1. Restart your terminal"
	@echo "  2. Create a vault: fern vault create ~/fern-vault"
	@echo "  3. Add to your shell RC file: export FERN_VAULT=~/fern-vault"

$(INSTALLED_SCRIPT): $(SCRIPT)
	@echo "Installing fern binary to $(BINDIR)..."
	@mkdir -p $(BINDIR)
	@cp $(SCRIPT) $(INSTALLED_SCRIPT)
	@chmod +x $(INSTALLED_SCRIPT)

$(INSTALLED_MAN): $(MANPAGE)
	@echo "Installing manual page to $(MANDIR)..."
	@mkdir -p $(MANDIR)
	@cp $(MANPAGE) $(INSTALLED_MAN)


install-system: $(SYSTEM_INSTALLED_SCRIPT) $(SYSTEM_INSTALLED_MAN)
	@echo "Installing completion for current shell..."
	@if echo "$(SHELL)" | grep -q "zsh"; then \
		echo "Installing ZSH completion..."; \
		sudo mkdir -p $(SYSTEM_ZSH_COMPLETIONDIR); \
		sudo cp $(ZSH_COMPLETION) $(SYSTEM_INSTALLED_ZSH_COMPLETION); \
		echo "✓ ZSH completion installed"; \
	elif echo "$(SHELL)" | grep -q "fish"; then \
		echo "Installing Fish completion..."; \
		sudo mkdir -p $(SYSTEM_FISH_COMPLETIONDIR); \
		sudo cp $(FISH_COMPLETION) $(SYSTEM_INSTALLED_FISH_COMPLETION); \
		echo "✓ Fish completion installed"; \
	else \
		echo "Installing Bash completion..."; \
		sudo mkdir -p $(SYSTEM_BASH_COMPLETIONDIR); \
		sudo cp $(BASH_COMPLETION) $(SYSTEM_INSTALLED_BASH_COMPLETION); \
		echo "✓ Bash completion installed"; \
	fi
	@echo ""
	@echo "✓ Fern installed system-wide to $(SYSTEM_PREFIX)"
	@echo ""
	@echo "To get started:"
	@echo "  1. Restart your terminal"
	@echo "  2. Create a vault: fern vault create ~/fern-vault"
	@echo "  3. Add to your shell RC file: export FERN_VAULT=~/fern-vault"

$(SYSTEM_INSTALLED_SCRIPT): $(SCRIPT)
	@echo "Installing fern binary to $(SYSTEM_BINDIR)... (requires sudo)"
	@sudo mkdir -p $(SYSTEM_BINDIR)
	@sudo cp $(SCRIPT) $(SYSTEM_INSTALLED_SCRIPT)
	@sudo chmod +x $(SYSTEM_INSTALLED_SCRIPT)

$(SYSTEM_INSTALLED_MAN): $(MANPAGE)
	@echo "Installing manual page to $(SYSTEM_MANDIR)... (requires sudo)"
	@sudo mkdir -p $(SYSTEM_MANDIR)
	@sudo cp $(MANPAGE) $(SYSTEM_INSTALLED_MAN)


uninstall:
	@echo "Removing fern from $(PREFIX)..."
	@rm -f $(INSTALLED_SCRIPT)
	@rm -f $(INSTALLED_MAN)
	@echo "Removing completion files..."
	@rm -f $(INSTALLED_BASH_COMPLETION)
	@rm -f $(INSTALLED_ZSH_COMPLETION)
	@rm -f $(INSTALLED_FISH_COMPLETION)
	@echo "✓ Fern uninstalled from user directory"

uninstall-system:
	@echo "Removing fern from system directories... (requires sudo)"
	@sudo rm -f $(SYSTEM_INSTALLED_SCRIPT)
	@sudo rm -f $(SYSTEM_INSTALLED_MAN)
	@echo "Removing completion files..."
	@sudo rm -f $(SYSTEM_INSTALLED_BASH_COMPLETION)
	@sudo rm -f $(SYSTEM_INSTALLED_ZSH_COMPLETION)
	@sudo rm -f $(SYSTEM_INSTALLED_FISH_COMPLETION)
	@echo "✓ Fern uninstalled from system"

clean:
	@echo "Nothing to clean (no build artifacts)"

# Check if required files exist
$(SCRIPT):
	@test -f $(SCRIPT) || (echo "Error: $(SCRIPT) not found!" && exit 1)

$(BASH_COMPLETION):
	@test -f $(BASH_COMPLETION) || (echo "Error: $(BASH_COMPLETION) not found!" && exit 1)

$(ZSH_COMPLETION):
	@test -f $(ZSH_COMPLETION) || (echo "Error: $(ZSH_COMPLETION) not found!" && exit 1)

$(FISH_COMPLETION):
	@test -f $(FISH_COMPLETION) || (echo "Error: $(FISH_COMPLETION) not found!" && exit 1)

$(MANPAGE):
	@test -f $(MANPAGE) || (echo "Error: $(MANPAGE) not found!" && exit 1)