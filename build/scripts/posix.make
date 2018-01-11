# Don't run this script. It does not work yet.

vpath %.o ./build/objects
vpath %.di ./build/interfaces
vpath %.d ./source
vpath %.d ./source/types
vpath %.d ./source/types/universal
vpath %.d ./source/codecs

asn1.so : $(libraryobjects)
    dmd -of./build/libraries/asn1.so -shared -fPIC -inline -release $(libraryobjects) $(libraryinterfaces)

# I don't know if double targets will actually work.
%.o %.di : % : %.d
    dmd -inline -release -O $< -o $@