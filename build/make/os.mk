# Copied from: https://github.com/dlang/dmd/blob/master/src/osmodel.mak
# OS         = one of {osx,linux,freebsd,openbsd,netbsd,dragonflybsd,solaris}
# MODEL      = one of { 32, 64 }

ifeq (,$(OS))
  uname_S:=$(shell uname -s)
  ifeq (Darwin,$(uname_S))
    OS:=osx
  endif
  ifeq (Linux,$(uname_S))
    OS:=linux
  endif
  ifeq (FreeBSD,$(uname_S))
    OS:=freebsd
  endif
  ifeq (OpenBSD,$(uname_S))
    OS:=openbsd
  endif
  ifeq (NetBSD,$(uname_S))
    OS:=netbsd
  endif
  ifeq (DragonFly,$(uname_S))
    OS:=dragonflybsd
  endif
  ifeq (Solaris,$(uname_S))
    OS:=solaris
  endif
  ifeq (SunOS,$(uname_S))
    OS:=solaris
  endif
  ifeq (,$(OS))
    $(error Unrecognized or unsupported OS for uname: $(uname_S))
  endif
endif

# When running make from XCode it may set environment var OS=MACOS.
# Adjust it here:
ifeq (MACOS,$(OS))
  OS:=osx
endif

ifeq (,$(MODEL))
  ifeq ($(OS), solaris)
    uname_M:=$(shell isainfo -n)
  else
    uname_M:=$(shell uname -m)
  endif
  ifneq (,$(findstring $(uname_M),x86_64 amd64))
    MODEL:=64
  endif
  ifneq (,$(findstring $(uname_M),i386 i586 i686))
    MODEL:=32
  endif
  ifeq (,$(MODEL))
    $(error Cannot figure 32/64 model from uname -m: $(uname_M))
  endif
endif