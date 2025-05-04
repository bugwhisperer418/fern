# directories
SRCDIR = src
BLDDIR = build
TSTDIR = tests

# compiler & flags
CC=gcc
CFLAGS=-Wall -Wextra -Werror -Wpedantic -std=c99 -g3 -I.
LDFLAGS = -lpthread

# target executable
TARGET=$(BLDDIR)/fern

# files involved in build
SRCS = $(wildcard $(SRCDIR)/*.c)
OBJS = $(patsubst $(SRCDIR)/%.c,$(BLDDIR)/%.o,$(SRCS))
DEPS = $(wildcard $(SRCDIR)/*.h)

###############################
##           RULES           ##
###############################
.PHONY: all clean install uninstall

all: $(TARGET)

$(BLDDIR)/%.o: $(SRCDIR)/%.c $(DEPS)
	@mkdir -p $(BLDDIR)
	$(CC) -c -o $@ $< $(CFLAGS) $(LDFLAGS)

clean:
	rm -f $(BLDDIR)/*.o $(TARGET)

install:
	mkdir -p /usr/local/bin
	cp fern $/usr/local/bin/
	chmod 755 /usr/local/bin/fern

uninstall:
	rm -f /usr/local/bin/fern

