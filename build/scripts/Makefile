# TODO: Unittest target
# TODO: Clean target
# TODO: Install target
# TODO: Production target
# TODO: Tools target
# TODO: Read https://en.wikipedia.org/wiki/List_of_build_automation_software

# Global settings
SHELL = /bin/bash
DESTDIR = /usr/local/lib64

# Location and layout of the root directory for this library
rootdir = $(addprefix $(abspath ../..), /)
builddir = build/
assembliesdir = build/assemblies/
executablesdir = build/executables/
librariesdir = build/libraries/
logsdir = build/logs/
objectsdir = build/objects/

# Location of source files
sourcedir = source/
typesdir = types/
universaltypesdir = types/universal/

# Virtual paths to search for source and object files.
vpath %.d $(rootdir)$(sourcedir)
vpath %.d $(rootdir)$(sourcedir)$(typesdir)
vpath %.d $(rootdir)$(sourcedir)$(universaltypesdir)
vpath %.o $(rootdir)$(objectsdir)

rootobjects = \
	asn1.o \
	ber.o \
	codec.o
	
typeobjects = \
	alltypes.o \
	identification.o \
	oidtype.o \
	types.o

universaltypeobjects = \
	bitstring.o \
	bmpstring.o \
	boolean.o \
	characterstring.o \
	embeddedpdv.o \
	endofcontent.o \
	enumerated.o \
	external.o \
	generalizedtime.o \
	generalstring.o \
	graphicstring.o \
	ia5string.o \
	integer.o \
	nulltype.o \
	numericstring.o \
	objectdescriptor.o \
	objectidentifier.o \
	octetstring.o \
	printablestring.o \
	realtype.o \
	relativeobjectidentifier.o \
	sequence.o \
	set.o \
	teletexstring.o \
	universalstring.o \
	utctime.o \
	utf8string.o \
	videotexstring.o \
	visiblestring.o
	
allobjects = $(rootobjects) $(typeobjects) $(universaltypeobjects)

asn1.lib: $(rootobjects) $(typeobjects) $(universaltypeobjects)
	@ar -r $(addprefix $(rootdir)$(librariesdir), asn1.a) $(addprefix $(rootdir)$(objectsdir),$(allobjects)) && \
	echo Created the ASN.1 library in $(rootdir)$(librariesdir)

#NOTE: You MUST cd to the root source directory before running DMD.

$(rootobjects): %.o: %.d
	cd $(rootdir)$(sourcedir) && \
	dmd -c $(notdir $<) -of$(rootdir)$(objectsdir)$@ && \
	echo Compiled $(notdir $<)

$(typeobjects): %.o: %.d
	cd $(rootdir)$(sourcedir) && \
	dmd -c $(addprefix $(typesdir), $(notdir $<)) -of$(rootdir)$(objectsdir)$@ && \
	echo Compiled $(notdir $<)

$(universaltypeobjects): %.o: %.d
	cd $(rootdir)$(sourcedir) && \
	dmd -c $(addprefix $(universaltypesdir), $(notdir $<)) -of$(rootdir)$(objectsdir)$@ && \
	echo Compiled $(notdir $<)




