# Makefile for Fern - A knowledge management system
# Author: Andie Keller <andie@bugwhisperer.dev>

# Installation paths
PREFIX ?= $(HOME)/.local
BINDIR = $(PREFIX)/bin
MANDIR = $(PREFIX)/share/man/man1
COMPLETIONDIR = $(PREFIX)/share/bash-completion/completions

# System-wide installation paths (requires sudo)
SYSTEM_PREFIX = /usr/local
SYSTEM_BINDIR = $(SYSTEM_PREFIX)/bin
SYSTEM_MANDIR = $(SYSTEM_PREFIX)/share/man/man1
SYSTEM_COMPLETIONDIR = /etc/bash_completion.d

# Source files
SRCDIR = src
DOCDIR = docs
SCRIPT = $(SRCDIR)/fern.sh
COMPLETION = $(SRCDIR)/fern_completion.bash
MANPAGE = $(DOCDIR)/fern.1

# Installed files
INSTALLED_SCRIPT = $(BINDIR)/fern
INSTALLED_MAN = $(MANDIR)/fern.1
INSTALLED_COMPLETION = $(COMPLETIONDIR)/fern

SYSTEM_INSTALLED_SCRIPT = $(SYSTEM_BINDIR)/fern
SYSTEM_INSTALLED_MAN = $(SYSTEM_MANDIR)/fern.1
SYSTEM_INSTALLED_COMPLETION = $(SYSTEM_COMPLETIONDIR)/fern

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
	@echo "  Completion: $(COMPLETIONDIR)/fern"
	@echo ""
	@echo "You can override PREFIX: make install PREFIX=/usr/local"

install: $(INSTALLED_SCRIPT) $(INSTALLED_MAN) $(INSTALLED_COMPLETION)
	@echo ""
	@echo "✓ Fern installed successfully to $(PREFIX)"
	@echo ""
	@echo "To get started:"
	@echo "  1. Restart your terminal or run: source $(INSTALLED_COMPLETION)"
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

$(INSTALLED_COMPLETION): $(COMPLETION)
	@echo "Installing bash completion to $(COMPLETIONDIR)..."
	@mkdir -p $(COMPLETIONDIR)
	@cp $(COMPLETION) $(INSTALLED_COMPLETION)

install-system: $(SYSTEM_INSTALLED_SCRIPT) $(SYSTEM_INSTALLED_MAN) $(SYSTEM_INSTALLED_COMPLETION)
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

$(SYSTEM_INSTALLED_COMPLETION): $(COMPLETION)
	@echo "Installing bash completion to $(SYSTEM_COMPLETIONDIR)... (requires sudo)"
	@sudo mkdir -p $(SYSTEM_COMPLETIONDIR)
	@sudo cp $(COMPLETION) $(SYSTEM_INSTALLED_COMPLETION)

uninstall:
	@echo "Removing fern from $(PREFIX)..."
	@rm -f $(INSTALLED_SCRIPT)
	@rm -f $(INSTALLED_MAN)
	@rm -f $(INSTALLED_COMPLETION)
	@echo "✓ Fern uninstalled from user directory"

uninstall-system:
	@echo "Removing fern from system directories... (requires sudo)"
	@sudo rm -f $(SYSTEM_INSTALLED_SCRIPT)
	@sudo rm -f $(SYSTEM_INSTALLED_MAN)
	@sudo rm -f $(SYSTEM_INSTALLED_COMPLETION)
	@echo "✓ Fern uninstalled from system"

clean:
	@echo "Nothing to clean (no build artifacts)"

# Check if required files exist
$(SCRIPT):
	@test -f $(SCRIPT) || (echo "Error: $(SCRIPT) not found!" && exit 1)

$(COMPLETION):
	@test -f $(COMPLETION) || (echo "Error: $(COMPLETION) not found!" && exit 1)

$(MANPAGE):
	@test -f $(MANPAGE) || (echo "Error: $(MANPAGE) not found!" && exit 1)