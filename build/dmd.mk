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
.DEFAULT_GOAL := all

# These lines are recommended by convention
# See Chapter 15 "Makefile Conventions" of the GNU Make Reference Manual
SHELL = /bin/sh
.SUFFIXES :

# The name SRCDIR is chosen because DESTDIR is a standard variable name.
# It should not point to the ./source directory, but rather, the root
# of this entire package. Note that this differs from the lowercase
# 'srcdir', which is the location where the source files are installed.
SRCDIR = .
DESTDIR =

PACKAGE_SLUG = asn1
VERSION := $(shell cat $(SRCDIR)/version)
include $(SRCDIR)/build/make/locale.mk
include $(SRCDIR)/build/make/os.mk

# REVIEW: I don't know if other operating systems do not support dynamic
# libraries. If you run an executable compiled with a dynamically-linked
# library on a Mac OS, you will get an error message upon running the
# executable that reads exactly as below:
#
# Shared libraries are not yet supported on OSX.
#
# Curiously enough, it still seems that the executable runs fine after writing
# that message to the console. Upon inspection of the executable size, it looks
# like the shared library is just getting compiled as though it were static,
# but I am unsure if this is possible.
ifeq ($(OS),osx)
	LIBRARY_TO_LINK_FOR_TOOLS := $(SRCDIR)/output/libraries/$(PACKAGE_SLUG)-$(VERSION).a
else
	LIBRARY_TO_LINK_FOR_TOOLS := $(SRCDIR)/output/libraries/$(PACKAGE_SLUG)-$(VERSION).so
endif

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
DCOMPILER = dmd
DFLAGS = -op $(SRCDIR)/source/macros.ddoc -Dd$(SRCDIR)/documentation/html -Hd$(SRCDIR)/output/interfaces -d
DFLAGS_RELEASE = -O -release -inline
DFLAGS_TEST = -unittest -debug
LINKER = ld
LINKERFLAGS =

# NOTE: "It is a good idea to avoid creating symbolic links in makefiles"
# TODO: Add code to download and install DMD, GDC, or LDC if no compiler is available
# TODO: Add .PHONY indicator

universaltypes = \
	$(PACKAGE_SLUG)/types/universal/characterstring \
	$(PACKAGE_SLUG)/types/universal/embeddedpdv \
	$(PACKAGE_SLUG)/types/universal/external \
	$(PACKAGE_SLUG)/types/universal/objectidentifier

types = \
	$(PACKAGE_SLUG)/types/alltypes \
	$(PACKAGE_SLUG)/types/identification \
	$(PACKAGE_SLUG)/types/oidtype

codecs = \
	$(PACKAGE_SLUG)/codecs/ber \
	$(PACKAGE_SLUG)/codecs/cer \
	$(PACKAGE_SLUG)/codecs/der

modules = \
	$(PACKAGE_SLUG)/constants \
	$(PACKAGE_SLUG)/codec \
	$(PACKAGE_SLUG)/compiler \
	$(PACKAGE_SLUG)/interfaces \
	$(universaltypes) \
	$(types) \
	$(codecs)

sources = 		$(addprefix $(SRCDIR)/source/,$(addsuffix .d,$(modules)))
interfaces = 	$(addprefix $(SRCDIR)/output/interfaces/source/,$(addsuffix .di,$(modules)))
objects = 		$(addprefix $(SRCDIR)/output/objects/source/,$(addsuffix .o,$(modules)))
htmldocs = 		$(addprefix $(SRCDIR)/documentation/html/source/,$(addsuffix .html,$(modules)))
jsondocs =		$(addprefix $(SRCDIR)/documentation/json/source/,$(addsuffix .json,$(modules)))
encoders = 		$(addprefix $(SRCDIR)/output/executables/,$(addprefix encode-,$(notdir $(codecs))))
decoders = 		$(addprefix $(SRCDIR)/output/executables/,$(addprefix decode-,$(notdir $(codecs))))
manpages = 		$(addprefix $(SRCDIR)/,$(addsuffix $(man1ext),$(encoders)) $(addsuffix $(man1ext),$(decoders)))

# This is--and always should be--the .DEFAULT_GOAL
all : libraries tools

#
# LIBRARIES
#

libs : libraries
libraries : statically_linked_library dynamically_linked_library

library : statically_linked_library
statically_linked_library : $(SRCDIR)/output/libraries/$(PACKAGE_SLUG)-$(VERSION).a
$(SRCDIR)/output/libraries/$(PACKAGE_SLUG)-$(VERSION).a : $(objects) $(interfaces) $(SRCDIR)/source/$(PACKAGE_SLUG)/types/oidtype.d
	-mkdir $(SRCDIR)/output
	-mkdir $(SRCDIR)/output/libraries
	$(DCOMPILER) $(DFLAGS_RELEASE) -lib -d -of$@ $(objects)

shared_library : dynamically_linked_library
dynamically_linked_library : $(SRCDIR)/output/libraries/$(PACKAGE_SLUG)-$(VERSION).so
$(SRCDIR)/output/libraries/$(PACKAGE_SLUG)-$(VERSION).so : $(objects) $(interfaces) $(SRCDIR)/source/$(PACKAGE_SLUG)/types/oidtype.d
	-mkdir $(SRCDIR)/output
	-mkdir $(SRCDIR)/output/libraries
	$(DCOMPILER) $(DFLAGS_RELEASE) -shared -d -defaultlib=libphobos2.so -L-ldl -L-rpath -L$(SRCDIR)/output/libraries -of$@ $(objects)

interfaces : $(interfaces)
$(interfaces) : $(SRCDIR)/output/interfaces/source/$(PACKAGE_SLUG)/%.di : $(SRCDIR)/source/$(PACKAGE_SLUG)/%.d
	$(DCOMPILER) -o- -op -d -I$(SRCDIR)/source -Hd$(SRCDIR)/output/interfaces $(addprefix $(SRCDIR)/,$<)

objects : $(objects)
$(objects) : $(SRCDIR)/output/objects/source/$(PACKAGE_SLUG)/%.o : $(SRCDIR)/source/$(PACKAGE_SLUG)/%.d
	$(DCOMPILER) -c -fPIC -op -d -I$(SRCDIR)/source -od$(SRCDIR)/output/objects $(addprefix $(SRCDIR)/,$<)

#
# EXECUTABLES
#

tools : executables
# executables : encoders decoders
# encoders : $(encoders)
# decoders : $(decoders)

# $(encoders) : $(SRCDIR)/output/executables/encode-% : $(SRCDIR)/source/tools/encode_%.d $(SRCDIR)/source/tools/encoder_mixin.d $(LIBRARY_TO_LINK_FOR_TOOLS)
# 	-mkdir $(SRCDIR)/output
# 	-mkdir $(SRCDIR)/output/executables
# 	# $(DCOMPILER) $(DFLAGS_RELEASE) -c -fPIC -op -d -I$(SRCDIR)/source -od$(SRCDIR)/output/objects $<

# 	$(DCOMPILER) $(DFLAGS_RELEASE) \
# 	$(SRCDIR)/source/$(PACKAGE_SLUG)/types/oidtype.d \
# 	$(SRCDIR)/source/$(PACKAGE_SLUG)/types/universal/objectidentifier.d \
# 	$(filter-out $(SRCDIR)/output/interfaces/source/$(PACKAGE_SLUG)/types/oidtype.di $(SRCDIR)/output/interfaces/source/$(PACKAGE_SLUG)/types/universal/objectidentifier.di,$(interfaces)) \
# 	-L$(LIBRARY_TO_LINK_FOR_TOOLS) \
# 	$(SRCDIR)/source/tools/encoder_mixin.d \
# 	$(SRCDIR)/$< \
# 	-od$(SRCDIR)/output/objects \
# 	-of$(SRCDIR)/$@ \
# 	-d
# 	chmod +x $@

encode-ber : $(SRCDIR)/output/executables/encode-ber
$(SRCDIR)/output/executables/encode-ber : $(SRCDIR)/output/executables/encode-ber.o $(LIBRARY_TO_LINK_FOR_TOOLS)
	$(DCOMPILER) $(DFLAGS_RELEASE) $< -L$(LIBRARY_TO_LINK_FOR_TOOLS) -of$@

$(SRCDIR)/output/executables/encode-ber.o : $(SRCDIR)/source/tools/encode_ber.d $(SRCDIR)/source/tools/encoder_mixin.d $(SRCDIR)/source/$(PACKAGE_SLUG)/types/oidtype.d $(interfaces)
	$(DCOMPILER) $(DFLAGS_RELEASE) -c -d -of$@ $<
	#$(SRCDIR)/source/$(PACKAGE_SLUG)/types/oidtype.d \
	$(filter-out $(SRCDIR)/output/interfaces/source/$(PACKAGE_SLUG)/types/oidtype.di,$(interfaces))

# $(decoders) : decode-% : decode_%.d decoder_mixin.d $(PACKAGE_SLUG)-$(VERSION).so
# 	-mkdir $(SRCDIR)/output
# 	-mkdir $(SRCDIR)/output/executables
# 	$(DCOMPILER) \
# 	-I$(SRCDIR)/output/interfaces/source \
# 	-L$(SRCDIR)/output/libraries/$(PACKAGE_SLUG)-$(VERSION).a \
# 	$(SRCDIR)/source/tools/decoder_mixin.d \
# 	$(SRCDIR)/$< \
# 	-od$(SRCDIR)/output/objects \
# 	-of$(SRCDIR)/output/executables/$@ \
# 	-inline \
# 	-release \
# 	-O \
# 	-d
# 	chmod +x $(SRCDIR)/output/executables/$@

#
# DOCUMENTATION
#

documentation : json_documentation html_documentation

json_documentation : $(jsondocs)
$(jsondocs) : $(SRCDIR)/documentation/json/source/$(PACKAGE_SLUG)/%.json : $(SRCDIR)/source/$(PACKAGE_SLUG)/%.d
	$(DCOMPILER) -o- -op -d -I$(SRCDIR)/source -Xf$@ $(SRCDIR)/$<

html_documentation : $(htmldocs) $(SRCDIR)/documentation/html/$(PACKAGE_SLUG)-$(VERSION).html
$(htmldocs) : $(SRCDIR)/documentation/html/source/$(PACKAGE_SLUG)/%.html : $(SRCDIR)/source/$(PACKAGE_SLUG)/%.d
	$(DCOMPILER) -o- -op -d -Df$@ -I$(SRCDIR)/source $(SRCDIR)/source/macros.ddoc $(addprefix $(SRCDIR)/,$<)

#
# ADDITIONAL TARGETS
#

clean :
	rm -rf $(SRCDIR)/documentation/html/*
	rm -rf $(SRCDIR)/documentation/json/*
	rm -rf $(SRCDIR)/output/*

check : unittest
test : unittest
unittest : $(sources)
	$(DCOMPILER) \
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

include $(SRCDIR)/build/make/install.mk