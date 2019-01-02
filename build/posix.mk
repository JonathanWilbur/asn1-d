#!/usr/bin/make
#
# Run this from the root directory like so:
# make -f ./output/scripts/posix.make
# sudo make -f ./output/scripts/posix.make install
#
# NOTE:
# "It is traditional to use upper case letters in variable names, but we
# recommend using lower case letters for variable names that serve internal
# purposes in the makefile, and reserving upper case for parameters that
# control implicit rules or for parameters that the user should override
# with command options[...]."
# -- GNU Make Reference Manual, Chapter 6: "How to Use Variables"
#

# These lines are recommended by convention
# See Chapter 15 "Makefile Conventions" of the GNU Make Reference Manual
SHELL = /bin/sh
.SUFFIXES:

# The name SRCDIR is chosen because DESTDIR is a standard variable name.
# It should not point to the ./source directory, but rather, the root
# of this entire package. Note that this differs from the lowercase
# 'srcdir', which is the location where the source files are installed.
SRCDIR = .
DESTDIR =

PACKAGE_SLUG = asn1
VERSION := $(shell cat $(SRCDIR)/version)
include $(SRCDIR)/build/make/locale.mk

# "Running make install" with a diff value of exec_prefix should not recompile"
prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
sbindir = $(exec_prefix)/sbin

# Per Chapter 15 "Makefile Conventions" of the GNU Make Reference Manual:
# Files are typically installed in a package-name subdirectory under
# libexecdir, and sometimes further divided into separate versions under that.
libexecdir = $(exec_prefix)/libexec

# Per Chapter 15 "Makefile Conventions" of the GNU Make Reference Manual:
# datarootdir and datadir are kept as separate variables so a user could
# install program-specific data files to a different location, but keep
# the man and info pages in the same place, for instance.
datarootdir = $(prefix)/share
datadir = $(datarootdir)

# All files that go here should be ASCII-only text files
sysconfdir = $(prefix)/etc

sharedstatedir = $(prefix)/com
localstatedir = $(prefix)/var
runstatedir = $(localstatedir)/run

# REVIEW: I don't get the difference here...
includedir = $(prefix)/include
oldincludedir = /usr/include

docdir = $(datarootdir)/doc/$(PACKAGE_SLUG)
infodir = $(datarootdir)/info
htmldir = $(docdir)/$(language)
dvidir = $(docdir)/$(language)
pdfdir = $(docdir)/$(language)
psdir = $(docdir)/$(language)

libdir = $(exec_prefix)/lib

localedir = $(datarootdir)/locale

mandir = $(datarootdir)/man
man1dir = $(mandir)/man1
man2dir = $(mandir)/man2
man3dir = $(mandir)/man3
man4dir = $(mandir)/man4
man5dir = $(mandir)/man5
man6dir = $(mandir)/man6
man7dir = $(mandir)/man7
man8dir = $(mandir)/man8

manext = .1
man1ext = .1
man2ext = .2
man3ext = .3
man4ext = .4
man5ext = .5
man6ext = .6
man7ext = .7
man8ext = .8

srcdir = $(prefix)/src

# Command choices
INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644
MAKE = make
D_COMPILER = dmd
LINKER = ld

# NOTE: "It is a good idea to avoid creating symbolic links in makefiles"
# TODO: Add code to download and install DMD, GDC, or LDC if no compiler is available
# FIXME: Remove mkdir -p (Some systems do not support it)
# TODO: Eliminate dependency on excessive vpaths
vpath %.o $(SRCDIR)/output/objects
vpath %.di $(SRCDIR)/output/interfaces
vpath %.d $(SRCDIR)/source/$(PACKAGE_SLUG)
vpath %.d $(SRCDIR)/source/$(PACKAGE_SLUG)/types
vpath %.d $(SRCDIR)/source/$(PACKAGE_SLUG)/types/universal
vpath %.d $(SRCDIR)/source/$(PACKAGE_SLUG)/codecs
vpath %.d $(SRCDIR)/source/tools
vpath %.html $(SRCDIR)/documentation/html
vpath %.a $(SRCDIR)/output/libraries
vpath %.so $(SRCDIR)/output/libraries
vpath %.1 $(SRCDIR)/documentation/man/1
vpath % $(SRCDIR)/output/executables

universaltypes = \
	characterstring \
	embeddedpdv \
	external \
	objectidentifier

types = \
	alltypes \
	identification \
	oidtype

codecs = \
	ber \
	cer \
	der

modules = \
	constants \
	codec \
	compiler \
	interfaces \
	$(universaltypes) \
	$(types) \
	$(codecs)

sources = $(addsuffix .d,$(modules))
interfaces = $(addsuffix .di,$(modules))
objects = $(addsuffix .o,$(modules))
htmldocs = $(addsuffix .html,$(modules))
encoders = $(addprefix encode-,$(codecs))
decoders = $(addprefix decode-,$(codecs))
manpages = $(addsuffix $(man1ext),$(encoders)) $(addsuffix $(man1ext),$(decoders))
# I don't know if this includes tools
htmldocs = $(addsuffix .html,$(modules))

#.SILENT : all libs tools $(PACKAGE_SLUG)-$(VERSION).a $(PACKAGE_SLUG)-$(VERSION).so $(encoders) $(decoders) install purge unittest
all : libs tools
libs : $(PACKAGE_SLUG)-$(VERSION).a $(PACKAGE_SLUG)-$(VERSION).so
tools : $(encoders) $(decoders)

# From the Debian New Maintainer's Guide, Version 1.2.40:
# clean target: to clean all compiled, generated, and useless files in the build-tree. (Required)
clean :
	rm -f $(SRCDIR)/documentation/$(PACKAGE_SLUG)-*.json
	rm -rf $(SRCDIR)/output/*
	rm -rf $(SRCDIR)/documentation/html/*

# You will most likely need to run this will root privileges
# TODO: Break this up into installman, installdoc, installsource, etc.
install : installlibs installsource installdocumentation installinterfaces

installlibs : libs
	$(INSTALL_DATA) $(SRCDIR)/output/libraries/$(PACKAGE_SLUG)-$(VERSION).so $(DESTDIR)$(libdir)
	-rm -f $(DESTDIR)$(libdir)/$(PACKAGE_SLUG).so
	ln -s $(DESTDIR)$(libdir)/$(PACKAGE_SLUG)-$(VERSION).so $(DESTDIR)$(libdir)/$(PACKAGE_SLUG).so

# FIXME: The problem here is that vpath does not recurse to the subdirectories of output/interfaces
installinterfaces :
	mkdir -p $(DESTDIR)$(includedir)/$(PACKAGE_SLUG)
	cp -r $(SRCDIR)/output/interfaces/* $(DESTDIR)$(includedir)/$(PACKAGE_SLUG)

installsource : $(sources)
	mkdir -p $(DESTDIR)$(srcdir)/$(PACKAGE_SLUG)
	cp -r $(SRCDIR)/source/* $(DESTDIR)$(srcdir)/$(PACKAGE_SLUG)

installexecutables : tools
	$(INSTALL_PROGRAM) $(SRCDIR)/output/executables/encode-* $(DESTDIR)$(bindir)
	$(INSTALL_PROGRAM) $(SRCDIR)/output/executables/decode-* $(DESTDIR)$(bindir)

installdocumentation : installman installhtml installmarkdown
	mkdir -p $(DESTDIR)$(docdir)/$(PACKAGE_SLUG)
	$(INSTALL_DATA) $(SRCDIR)/documentation/mit.license $(DESTDIR)$(docdir)/$(PACKAGE_SLUG)
	$(INSTALL_DATA) $(SRCDIR)/documentation/credits.csv $(DESTDIR)$(docdir)/$(PACKAGE_SLUG)
	$(INSTALL_DATA) $(SRCDIR)/documentation/releases.csv $(DESTDIR)$(docdir)/$(PACKAGE_SLUG)

# TODO: Figure out where the manpages are ahead of time
installman : $(manpages)
	$(INSTALL_DATA) $(SRCDIR)/documentation/man/1/* $(DESTDIR)$(man1dir)

# FIXME: The problem here is that vpath does not recurse to the subdirectories of documentation/html
installhtml :
	mkdir -p $(DESTDIR)$(docdir)/$(PACKAGE_SLUG)
	cp -r $(SRCDIR)/documentation/html/* $(DESTDIR)$(docdir)/$(PACKAGE_SLUG)

# FIXME:
installmarkdown :
	mkdir -p $(DESTDIR)$(docdir)/$(PACKAGE_SLUG)
	$(INSTALL_DATA) $(SRCDIR)/documentation/*.md $(DESTDIR)$(docdir)/$(PACKAGE_SLUG)

installjsondocs :
	mkdir -p $(DESTDIR)$(docdir)/$(PACKAGE_SLUG)
	$(INSTALL_DATA) $(SRCDIR)/documentation/$(PACKAGE_SLUG)-$(VERSION).json $(DESTDIR)$(docdir)/$(PACKAGE_SLUG)

uninstall :
	-rm -f $(DESTDIR)$(libdir)/$(PACKAGE_SLUG).so
	-rm -f $(DESTDIR)$(libdir)/$(PACKAGE_SLUG)-$(VERSION).so
	rm -f $(DESTDIR)$(bindir)/decode-*
	rm -f $(DESTDIR)$(bindir)/encode-*
	rm -rf $(DESTDIR)$(docdir)/$(PACKAGE_SLUG)
	rm -f $(DESTDIR)$(mandir)/encode-*$(man1ext)
	rm -f $(DESTDIR)$(mandir)/decode-*$(man1ext)

check : unittest
test : unittest
unittest : $(sources)
	$(D_COMPILER) \
	$(SRCDIR)/source/$(PACKAGE_SLUG)/*.d \
	$(SRCDIR)/source/$(PACKAGE_SLUG)/types/*.d \
	$(SRCDIR)/source/$(PACKAGE_SLUG)/types/universal/*.d \
	$(SRCDIR)/source/$(PACKAGE_SLUG)/codecs/*.d \
	-of$(SRCDIR)/unittest-executable \
	-unittest \
	-main \
	-d
	chmod +x $(SRCDIR)/unittest-executable
	$(SRCDIR)/unittest-executable
	rm -f $(SRCDIR)/unittest-executable.o
	rm -f $(SRCDIR)/unittest-executable

$(PACKAGE_SLUG)-$(VERSION).a : $(sources)
	-mkdir -p $(SRCDIR)/output
	-mkdir -p $(SRCDIR)/output/interfaces
	-mkdir -p $(SRCDIR)/output/libraries
	$(D_COMPILER) \
	$(SRCDIR)/source/macros.ddoc \
	$(SRCDIR)/source/$(PACKAGE_SLUG)/*.d \
	$(SRCDIR)/source/$(PACKAGE_SLUG)/types/*.d \
	$(SRCDIR)/source/$(PACKAGE_SLUG)/types/universal/*.d \
	$(SRCDIR)/source/$(PACKAGE_SLUG)/codecs/*.d \
	-Dd$(SRCDIR)/documentation/html \
	-Hd$(SRCDIR)/output/interfaces \
	-op \
	-of$(SRCDIR)/output/libraries/$(PACKAGE_SLUG)-$(VERSION).a \
	-Xf$(SRCDIR)/documentation/$(PACKAGE_SLUG)-$(VERSION).json \
	-lib \
	-inline \
	-release \
	-O \
	-map \
	-d

$(PACKAGE_SLUG)-$(VERSION).so : $(sources)
	-mkdir -p $(SRCDIR)/output
	-mkdir -p $(SRCDIR)/output/interfaces
	-mkdir -p $(SRCDIR)/output/libraries
	$(D_COMPILER) \
	$(SRCDIR)/source/macros.ddoc \
	$(SRCDIR)/source/$(PACKAGE_SLUG)/*.d \
	$(SRCDIR)/source/$(PACKAGE_SLUG)/types/*.d \
	$(SRCDIR)/source/$(PACKAGE_SLUG)/types/universal/*.d \
	$(SRCDIR)/source/$(PACKAGE_SLUG)/codecs/*.d \
	-Dd$(SRCDIR)/documentation/html \
	-Hd$(SRCDIR)/output/interfaces \
	-op \
	-of$(SRCDIR)/output/libraries/$(PACKAGE_SLUG)-$(VERSION).so \
	-lib \
	-inline \
	-release \
	-O \
	-map \
	-d

$(encoders) : encode-% : encode_%.d encoder_mixin.d $(PACKAGE_SLUG)-$(VERSION).so
	-mkdir -p $(SRCDIR)/output
	-mkdir -p $(SRCDIR)/output/executables
	$(D_COMPILER) \
	-I$(SRCDIR)/output/interfaces/source \
	-L$(SRCDIR)/output/libraries/$(PACKAGE_SLUG)-$(VERSION).a \
	$(SRCDIR)/source/tools/encoder_mixin.d \
	$(SRCDIR)/$< \
	-od$(SRCDIR)/output/objects \
	-of$(SRCDIR)/output/executables/$@ \
	-inline \
	-release \
	-O \
	-d
	chmod +x $(SRCDIR)/output/executables/$@

$(decoders) : decode-% : decode_%.d decoder_mixin.d $(PACKAGE_SLUG)-$(VERSION).so
	-mkdir -p $(SRCDIR)/output
	-mkdir -p $(SRCDIR)/output/executables
	$(D_COMPILER) \
	-I$(SRCDIR)/output/interfaces/source \
	-L$(SRCDIR)/output/libraries/$(PACKAGE_SLUG)-$(VERSION).a \
	$(SRCDIR)/source/tools/decoder_mixin.d \
	$(SRCDIR)/$< \
	-od$(SRCDIR)/output/objects \
	-of$(SRCDIR)/output/executables/$@ \
	-inline \
	-release \
	-O \
	-d
	chmod +x $(SRCDIR)/output/executables/$@

# How Phobos compiles only the JSON file:
# JSON = phobos.json
# json : $(JSON)
# $(JSON) : $(ALL_D_FILES)
# $(DMD) $(DFLAGS) -o- -Xf$@ $^