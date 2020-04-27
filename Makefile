ROOT_DIR=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))

DESTDIR:=/
PREFIX:=/
BINDIR:=bin
LIBDIR:=lib

.PHONY: install
install:
	@mkdir -p $(DESTDIR)/$(PREFIX)/$(LIBDIR)/expac-builder/
	@install -Dm644 $(ROOT_DIR)lib/*.sh $(DESTDIR)/$(PREFIX)/$(LIBDIR)/expac-builder/
	@mkdir -p $(DESTDIR)/$(PREFIX)/$(BINDIR)/
