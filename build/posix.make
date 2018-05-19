#!/usr/bin/make
#
# Run this from the root directory like so:
# make -f ./output/scripts/posix.make
# sudo make -f ./output/scripts/posix.make install
#
root = .
version := $(shell cat $(root)/version)
vpath %.o $(root)/output/objects
vpath %.di $(root)/output/interfaces
vpath %.d $(root)/source/asn1
vpath %.d $(root)/source/asn1/types
vpath %.d $(root)/source/asn1/types/universal
vpath %.d $(root)/source/asn1/codecs
vpath %.d $(root)/source/tools
vpath %.html $(root)/documentation/html
vpath %.a $(root)/output/libraries
vpath %.so $(root)/output/libraries
vpath % $(root)/output/executables

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

.SILENT : all libs tools asn1-$(version).a asn1-$(version).so $(encoders) $(decoders) install purge unittest
all : libs tools
libs : asn1-$(version).a asn1-$(version).so
tools : $(encoders) $(decoders)

uname := $(shell uname)
ifeq ($(uname), Linux)
	echoflags = "-e"
endif
ifeq ($(uname), Darwin)
	echoflags = ""
endif

# You will most likely need to run this will root privileges
install : all
	cp $(root)/output/libraries/asn1-$(version).so /usr/local/lib
	-rm -f /usr/local/lib/asn1.so
	ln -s /usr/local/lib/asn1-$(version).so /usr/local/lib/asn1.so
	cp $(root)/output/executables/encode-* /usr/local/bin
	cp $(root)/output/executables/decode-* /usr/local/bin
	-cp $(root)/documentation/man/1/* /usr/local/share/man/1
	-cp $(root)/documentation/man/1/* /usr/local/share/man/man1
	mkdir -p /usr/local/share/asn1/{html,md,json}
	cp -r $(root)/documentation/html/* /usr/local/share/asn1/html
	cp -r $(root)/documentation/*.md /usr/local/share/asn1/md
	cp -r $(root)/documentation/asn1-$(version).json /usr/local/share/asn1/json/asn1-$(version).json
	cp $(root)/documentation/mit.license /usr/local/share/asn1
	cp $(root)/documentation/credits.csv /usr/local/share/asn1
	cp $(root)/documentation/releases.csv /usr/local/share/asn1

check : unittest
test : unittest
unittest : $(sources)
	echo $(echoflags) "Building the ASN.1 Unit Testing Executable... \c"
	dmd \
	$(root)/source/asn1/*.d \
	$(root)/source/asn1/types/*.d \
	$(root)/source/asn1/types/universal/*.d \
	$(root)/source/asn1/codecs/*.d \
	-of$(root)/unittest-executable \
	-unittest \
	-main \
	-d
	echo $(echoflags) "\033[32mDone.\033[0m"
	chmod +x $(root)/unittest-executable
	echo $(echoflags) "Running the ASN.1 unit tests... "
	$(root)/unittest-executable
	rm -f $(root)/unittest-executable.o
	rm -f $(root)/unittest-executable
	echo $(echoflags) "\033[32mDone.\033[0m"

# From the Debian New Maintainer's Guide, Version 1.2.40:
# clean target: to clean all compiled, generated, and useless files in the build-tree. (Required) 
clean :
	-rm -f $(root)/documentation/asn1-*.json
	-rm -rf $(root)/output/*
	-rm -rf $(root)/documentation/html/*

uninstall :
	-rm -f /usr/local/lib/asn1.so
	-rm -f /usr/local/lib/asn1-$(version).so
	-rm -f /usr/local/bin/decode-*
	-rm -f /usr/local/bin/encode-*
	-rm -rf /usr/local/share/asn1
	-rm -f /usr/local/share/man/man1/encode-*.1
	-rm -f /usr/local/share/man/man1/decode-*.1
	-rm -f /usr/local/share/man/1/encode-*.1
	-rm -f /usr/local/share/man/1/decode-*.1

asn1-$(version).a : $(sources)
	echo $(echoflags) "Building the ASN.1 Library (static)... \c"
	-mkdir -p $(root)/output
	-mkdir -p $(root)/output/interfaces
	-mkdir -p $(root)/output/libraries
	dmd \
	$(root)/source/macros.ddoc \
	$(root)/source/asn1/*.d \
	$(root)/source/asn1/types/*.d \
	$(root)/source/asn1/types/universal/*.d \
	$(root)/source/asn1/codecs/*.d \
	-Dd$(root)/documentation/html \
	-Hd$(root)/output/interfaces \
	-op \
	-of$(root)/output/libraries/asn1-$(version).a \
	-Xf$(root)/documentation/asn1-$(version).json \
	-lib \
	-inline \
	-release \
	-O \
	-map \
	-d
	echo $(echoflags) "\033[32mDone.\033[0m"

asn1-$(version).so : $(sources)
	echo $(echoflags) "Building the ASN.1 Library (shared / dynamic)... \c"
	-mkdir -p $(root)/output
	-mkdir -p $(root)/output/interfaces
	-mkdir -p $(root)/output/libraries
	dmd \
	$(root)/source/macros.ddoc \
	$(root)/source/asn1/*.d \
	$(root)/source/asn1/types/*.d \
	$(root)/source/asn1/types/universal/*.d \
	$(root)/source/asn1/codecs/*.d \
	-Dd$(root)/documentation/html \
	-Hd$(root)/output/interfaces \
	-op \
	-of$(root)/output/libraries/asn1-$(version).so \
	-lib \
	-inline \
	-release \
	-O \
	-map \
	-d
	echo $(echoflags) "\033[32mDone.\033[0m"

$(encoders) : encode-% : encode_%.d encoder_mixin.d asn1-$(version).so
	echo $(echoflags) "Building the ASN.1 Command-Line Tool, $@... \c"
	-mkdir -p $(root)/output
	-mkdir -p $(root)/output/executables
	dmd \
	-I$(root)/output/interfaces/source \
	-L$(root)/output/libraries/asn1-$(version).a \
	$(root)/source/tools/encoder_mixin.d \
	$< \
	-od$(root)/output/objects \
	-of$(root)/output/executables/$@ \
	-inline \
	-release \
	-O \
	-d
	chmod +x $(root)/output/executables/$@
	echo $(echoflags) "\033[32mDone.\033[0m"

$(decoders) : decode-% : decode_%.d decoder_mixin.d asn1-$(version).so
	echo $(echoflags) "Building the ASN.1 Command-Line Tool, $@... \c"
	-mkdir -p $(root)/output
	-mkdir -p $(root)/output/executables
	dmd \
	-I$(root)/output/interfaces/source \
	-L$(root)/output/libraries/asn1-$(version).a \
	$(root)/source/tools/decoder_mixin.d \
	$< \
	-od$(root)/output/objects \
	-of$(root)/output/executables/$@ \
	-inline \
	-release \
	-O \
	-d
	chmod +x $(root)/output/executables/$@
	echo $(echoflags) "\033[32mDone.\033[0m"

# How Phobos compiles only the JSON file:
# JSON = phobos.json
# json : $(JSON)
# $(JSON) : $(ALL_D_FILES)
# $(DMD) $(DFLAGS) -o- -Xf$@ $^