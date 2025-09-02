# Makefile for Fern - A knowledge management system
# Author: Andie Keller <andie@bugwhisperer.dev>

# Installation paths
PREFIX ?= $(HOME)/.local
BINDIR = $(PREFIX)/bin
MANDIR = $(PREFIX)/share/man/man1
BASH_COMPLETIONDIR = $(PREFIX)/share/bash-completion/completions
ZSH_COMPLETIONDIR = $(HOME)/.oh-my-zsh/custom/completions
FISH_COMPLETIONDIR = $(PREFIX)/share/fish/vendor_completions.d

# Source files
SRCDIR = src
DOCDIR = docs
SCRIPT = $(SRCDIR)/fern.sh
BASH_COMPLETION = $(SRCDIR)/fern_completion.bash
ZSH_COMPLETION = $(SRCDIR)/fern.zsh
FISH_COMPLETION = $(SRCDIR)/fern.fish
MANPAGE = $(DOCDIR)/fern.1

# Installed files
INSTALLED_SCRIPT = $(BINDIR)/fern
INSTALLED_MAN = $(MANDIR)/fern.1
INSTALLED_BASH_COMPLETION = $(BASH_COMPLETIONDIR)/fern
INSTALLED_ZSH_COMPLETION = $(ZSH_COMPLETIONDIR)/fern.zsh
INSTALLED_FISH_COMPLETION = $(FISH_COMPLETIONDIR)/fern.fish

.PHONY: all install uninstall help

all: help

help:
	@echo "Fern Installation Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  install         - Install fern to user directory ($(PREFIX))"
	@echo "  uninstall       - Remove fern from user directory"
	@echo "  help            - Show this help message"
	@echo ""
	@echo "Installation paths:"
	@echo "  Executable Script: $(BINDIR)/fern"
	@echo "  Manual: $(MANDIR)/fern.1"
	@echo "  Shell Completion: Installed for various supported shells"
	@echo ""
	@echo "You can override PREFIX: make install PREFIX=/usr/local"

install: $(INSTALLED_SCRIPT) $(INSTALLED_MAN)
	@echo "Installing completions for all supported shells..."
	@mkdir -p $(ZSH_COMPLETIONDIR)
	@cp $(ZSH_COMPLETION) $(INSTALLED_ZSH_COMPLETION)
	@mkdir -p $(FISH_COMPLETIONDIR)
	@cp $(FISH_COMPLETION) $(INSTALLED_FISH_COMPLETION)
	@mkdir -p $(BASH_COMPLETIONDIR)
	@cp $(BASH_COMPLETION) $(INSTALLED_BASH_COMPLETION)
	@echo "✓ Fern completion support installed for: Bash, ZSH, & Fish shells"
	@echo "✓ Fern executable installed successfully to $(PREFIX)"
	@echo ""
	@echo "To get started:"
	@echo "  1. Restart your terminal"
	@echo "  2. Create a vault: fern vault create ~/fern-vault"
	@echo "  3. Add to your shell RC file: export FERN_VAULT=~/fern-vault"

$(INSTALLED_SCRIPT): $(SCRIPT)
	@echo "Installing fern executable to $(BINDIR)..."
	@mkdir -p $(BINDIR)
	@cp $(SCRIPT) $(INSTALLED_SCRIPT)
	@chmod +x $(INSTALLED_SCRIPT)

$(INSTALLED_MAN): $(MANPAGE)
	@echo "Installing manual page to $(MANDIR)..."
	@mkdir -p $(MANDIR)
	@cp $(MANPAGE) $(INSTALLED_MAN)

uninstall:
	@echo "Removing fern executable from $(BINDIR)..."
	@rm -f $(INSTALLED_SCRIPT)
	@echo "Removing fern man page..."
	@rm -f $(INSTALLED_MAN)
	@echo "Removing fern completion files..."
	@rm -f $(INSTALLED_BASH_COMPLETION)
	@rm -f $(INSTALLED_ZSH_COMPLETION)
	@rm -f $(INSTALLED_FISH_COMPLETION)
	@echo "✓ Fern has been uninstalled"

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
