#!/usr/bin/make
#
# Run this from the root directory like so:
# sudo make -f ./build/scripts/posix.make
# sudo make -f ./build/scripts/posix.make install
#
# TODO: Figure out why it rebuilds the library
vpath %.o ./build/objects
vpath %.di ./build/interfaces
vpath %.d ./source
vpath %.d ./source/types
vpath %.d ./source/types/universal
vpath %.d ./source/codecs
vpath %.d ./source/tools
vpath %.html ./documentation/html
vpath %.a ./build/libraries
vpath %.so ./build/libraries
vpath % ./build/executables

version = 1.0.0

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
	asn1 \
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

.SILENT : all libs tools asn1-$(version).a asn1-$(version).so $(encoders) $(decoders) install
all : libs tools
libs : asn1-$(version).a asn1-$(version).so
tools : $(encoders) $(decoders)

# You will most likely need to run this will root privileges
install : all
	cp ./build/libraries/asn1-$(version).so /usr/lib
	ln -s /usr/lib/asn1-$(version).so /usr/lib/asn1.so

asn1-$(version).a : $(sources)
	echo "Building the ASN.1 Library (static)... \c"
	dmd \
	./source/macros.ddoc \
	./source/asn1.d \
	./source/codec.d \
	./source/interfaces.d \
	./source/types/*.d \
	./source/types/universal/*.d \
	./source/codecs/*.d \
	-Dd./documentation/html \
	-Hd./build/interfaces \
	-op \
	-of./build/libraries/asn1.a \
	-Xf./documentation/asn1.json \
	-lib \
	-inline \
	-release \
	-O \
	-map \
	-d
	echo "\033[0;32mDone.\033[0m"

asn1-$(version).so : $(sources)
	echo "Building the ASN.1 Library (shared / dynamic)... \c"
	dmd \
	./source/macros.ddoc \
	./source/asn1.d \
	./source/codec.d \
	./source/interfaces.d \
	./source/types/*.d \
	./source/types/universal/*.d \
	./source/codecs/*.d \
	-Dd./documentation/html \
	-Hd./build/interfaces \
	-op \
	-of./build/libraries/asn1.so \
	-Xf./documentation/asn1.json \
	-lib \
	-inline \
	-release \
	-O \
	-map \
	-d
	echo "\033[0;32mDone.\033[0m"

$(encoders) : encode-% : encode_%.d encoder_mixin.d asn1-$(version).so
	echo "Building the ASN.1 Command-Line Tool, $@... \c"
	dmd \
	-I./build/interfaces/source \
	-I./build/interfaces/source/codecs \
	-L./build/libraries/asn1.so \
	./source/tools/encoder_mixin.d \
	$< \
	-of./build/executables/$@ \
	-inline \
	-release \
	-O \
	-d
	echo "\033[0;32mDone.\033[0m"

$(decoders) : decode-% : decode_%.d decoder_mixin.d asn1-$(version).so
	echo "Building the ASN.1 Command-Line Tool, $@... \c"
	dmd \
	-I./build/interfaces/source \
	-I./build/interfaces/source/codecs \
	-L./build/libraries/asn1.so \
	./source/tools/decoder_mixin.d \
	$< \
	-of./build/executables/$@ \
	-inline \
	-release \
	-O \
	-d
	echo "\033[0;32mDone.\033[0m"