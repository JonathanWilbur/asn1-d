#!/usr/bin/make
#
# Run this from the root directory like so:
# make -f ./build/scripts/posix.make
# sudo make -f ./build/scripts/posix.make install
#
version = 2.4.1
root = .
vpath %.o $(root)/build/objects
vpath %.di $(root)/build/interfaces
vpath %.d $(root)/source/asn1
vpath %.d $(root)/source/asn1/types
vpath %.d $(root)/source/asn1/types/universal
vpath %.d $(root)/source/asn1/codecs
vpath %.d $(root)/source/tools
vpath %.html $(root)/documentation/html
vpath %.a $(root)/build/libraries
vpath %.so $(root)/build/libraries
vpath % $(root)/build/executables

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
	cp $(root)/build/libraries/asn1-$(version).so /usr/local/lib
	-rm -f /usr/local/lib/asn1.so
	ln -s /usr/local/lib/asn1-$(version).so /usr/local/lib/asn1.so
	cp $(root)/build/executables/encode-* /usr/local/bin
	cp $(root)/build/executables/decode-* /usr/local/bin
	-cp $(root)/documentation/man/1/* /usr/local/share/man/1
	-cp $(root)/documentation/man/1/* /usr/local/share/man/man1
	mkdir -p /usr/local/share/asn1/{html,md,json}
	cp -r $(root)/documentation/html/* /usr/local/share/asn1/html
	cp -r $(root)/documentation/*.md /usr/local/share/asn1/md
	cp -r $(root)/documentation/asn1-$(version).json /usr/local/share/asn1/json/asn1-$(version).json
	cp $(root)/documentation/mit.license /usr/local/share/asn1
	cp $(root)/documentation/credits.csv /usr/local/share/asn1
	cp $(root)/documentation/releases.csv /usr/local/share/asn1

unittest : $(sources)
	echo $(echoflags) "Building the ASN.1 Unit Testing Executable... \c"
	dmd \
	$(root)/source/asn1/*.d \
	$(root)/source/asn1/types/*.d \
	$(root)/source/asn1/types/universal/*.d \
	$(root)/source/asn1/codecs/*.d \
	-of$(root)/asn1-d-unittest-executable \
	-unittest \
	-main \
	-d
	echo $(echoflags) "\033[32mDone.\033[0m"
	echo $(echoflags) "Running the ASN.1 unit tests... "
	$(root)/asn1-d-unittest-executable
	rm -f $(root)/asn1-d-unittest-executable
	echo $(echoflags) "\033[32mDone.\033[0m"

clean :
	-rm -f $(root)/build/objects/*.o
	-rm -rf $(root)/documentation/html/source
	-rm -f $(root)/documentation/asn1-*.json

purge :
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
	dmd \
	$(root)/source/macros.ddoc \
	$(root)/source/asn1/*.d \
	$(root)/source/asn1/types/*.d \
	$(root)/source/asn1/types/universal/*.d \
	$(root)/source/asn1/codecs/*.d \
	-Dd$(root)/documentation/html \
	-Hd$(root)/build/interfaces \
	-op \
	-of$(root)/build/libraries/asn1-$(version).a \
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
	dmd \
	$(root)/source/macros.ddoc \
	$(root)/source/asn1/*.d \
	$(root)/source/asn1/types/*.d \
	$(root)/source/asn1/types/universal/*.d \
	$(root)/source/asn1/codecs/*.d \
	-Dd$(root)/documentation/html \
	-Hd$(root)/build/interfaces \
	-op \
	-of$(root)/build/libraries/asn1-$(version).so \
	-lib \
	-inline \
	-release \
	-O \
	-map \
	-d
	echo $(echoflags) "\033[32mDone.\033[0m"

$(encoders) : encode-% : encode_%.d encoder_mixin.d asn1-$(version).so
	echo $(echoflags) "Building the ASN.1 Command-Line Tool, $@... \c"
	dmd \
	-I$(root)/build/interfaces/source \
	-L$(root)/build/libraries/asn1-$(version).a \
	$(root)/source/tools/encoder_mixin.d \
	$< \
	-od$(root)/build/objects \
	-of$(root)/build/executables/$@ \
	-inline \
	-release \
	-O \
	-d
	chmod +x $(root)/build/executables/$@
	echo $(echoflags) "\033[32mDone.\033[0m"

$(decoders) : decode-% : decode_%.d decoder_mixin.d asn1-$(version).so
	echo $(echoflags) "Building the ASN.1 Command-Line Tool, $@... \c"
	dmd \
	-I$(root)/build/interfaces/source \
	-L$(root)/build/libraries/asn1-$(version).a \
	$(root)/source/tools/decoder_mixin.d \
	$< \
	-od$(root)/build/objects \
	-of$(root)/build/executables/$@ \
	-inline \
	-release \
	-O \
	-d
	chmod +x $(root)/build/executables/$@
	echo $(echoflags) "\033[32mDone.\033[0m"

# How Phobos compiles only the JSON file:
# JSON = phobos.json
# json : $(JSON)
# $(JSON) : $(ALL_D_FILES)
# $(DMD) $(DFLAGS) -o- -Xf$@ $^