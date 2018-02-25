#!/usr/bin/make
#
# Run this from the root directory like so:
# make -f ./build/scripts/posix.make
# sudo make -f ./build/scripts/posix.make install
#
vpath %.o ./build/objects
vpath %.di ./build/interfaces
vpath %.d ./source/asn1
vpath %.d ./source/asn1/types
vpath %.d ./source/asn1/types/universal
vpath %.d ./source/asn1/codecs
vpath %.d ./source/tools
vpath %.html ./documentation/html
vpath %.a ./build/libraries
vpath %.so ./build/libraries
vpath % ./build/executables

version = 2.2.0

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

.SILENT : all libs tools asn1-$(version).a asn1-$(version).so $(encoders) $(decoders) install purge
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
	cp ./build/libraries/asn1-$(version).so /usr/local/lib
	-rm -f /usr/local/lib/asn1.so
	ln -s /usr/local/lib/asn1-$(version).so /usr/local/lib/asn1.so
	cp ./build/executables/encode-* /usr/local/bin
	cp ./build/executables/decode-* /usr/local/bin
	-cp ./documentation/man/1/* /usr/local/share/man/1
	-cp ./documentation/man/1/* /usr/local/share/man/man1
	mkdir -p /usr/local/share/asn1/{html,md,json}
	cp -r ./documentation/html/* /usr/local/share/asn1/html
	cp -r ./documentation/*.md /usr/local/share/asn1/md
	cp -r ./documentation/asn1-$(version).json /usr/local/share/asn1/json/asn1-$(version).json
	cp ./documentation/mit.license /usr/local/share/asn1
	cp ./documentation/credits.csv /usr/local/share/asn1
	cp ./documentation/releases.csv /usr/local/share/asn1

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
	./source/macros.ddoc \
	./source/asn1/*.d \
	./source/asn1/types/*.d \
	./source/asn1/types/universal/*.d \
	./source/asn1/codecs/*.d \
	-Dd./documentation/html \
	-Hd./build/interfaces \
	-op \
	-of./build/libraries/asn1-$(version).a \
	-Xf./documentation/asn1-$(version).json \
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
	./source/macros.ddoc \
	./source/asn1/*.d \
	./source/asn1/types/*.d \
	./source/asn1/types/universal/*.d \
	./source/asn1/codecs/*.d \
	-Dd./documentation/html \
	-Hd./build/interfaces \
	-op \
	-of./build/libraries/asn1-$(version).so \
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
	-I./build/interfaces/source \
	-L./build/libraries/asn1-$(version).a \
	./source/tools/encoder_mixin.d \
	$< \
	-od./build/objects \
	-of./build/executables/$@ \
	-inline \
	-release \
	-O \
	-d
	chmod +x ./build/executables/$@
	echo $(echoflags) "\033[32mDone.\033[0m"

$(decoders) : decode-% : decode_%.d decoder_mixin.d asn1-$(version).so
	echo $(echoflags) "Building the ASN.1 Command-Line Tool, $@... \c"
	dmd \
	-I./build/interfaces/source \
	-L./build/libraries/asn1-$(version).a \
	./source/tools/decoder_mixin.d \
	$< \
	-od./build/objects \
	-of./build/executables/$@ \
	-inline \
	-release \
	-O \
	-d
	chmod +x ./build/executables/$@
	echo $(echoflags) "\033[32mDone.\033[0m"

# How Phobos compiles only the JSON file:
# JSON = phobos.json
# json : $(JSON)
# $(JSON) : $(ALL_D_FILES)
# $(DMD) $(DFLAGS) -o- -Xf$@ $^