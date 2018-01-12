# Building and Installation

## Building

In `build/scripts` there are three scripts you can use to build the library.
All of the build scripts assume that you are using `dmd` and not `gdc` or
any other D compiler.

### On POSIX-Compliant Machines (Linux, Mac OS X)

Run `make -f ./build/scripts/posix.make` to build the static library,
shared library, and all command-line tools.

Run `sudo make -f ./build/scripts/posix.make install` to install the
shared library, command-line tools, and documentation.

Alternatively, you can run `./build/scripts/build.sh`.
If you get a permissions error, you need to set that file to be executable
using the `chmod` command.

### On Windows

Run `.\build\scripts\build.bat` from a `cmd` or run `.\build\scripts\build.ps1`
from the PowerShell command line. If you get a warning about needing a
cryptographic signature for the PowerShell script, it is probably because
your system is blocking running unsigned PowerShell scripts. Just run the
other script if that is the case.

Unfortunately, there is no install scripts, mostly because I don't really know
how to install something on Windows, other than just putting executables on the
`%PATH%`. I welcome suggestions or pull requests.

## Installation

When the library is built, it will be located in `build/libraries`. You may
want to place the shared library in `/lib`, `/usr/lib` or where ever you find
the `.so` files on your system. If you are using Windows, I don't know where
you should put the `.dll` file.

You will also need to put the `.di` files found in `build/interfaces` somewhere
in your source imports directory, which seems to vary a lot from system to
system.

Static libraries can be put where ever `phobos2` is on your system.

If the command-line executables are built too, they will be found in
`build/executables`. You may want to place this in `/usr/bin` or somewhere
else indicated by the `PATH` environment variable. Type `echo $PATH` on POSIX
systems to see your `PATH` variable.

If documentation was generated from the
[embedded documentation](https://dlang.org/spec/ddoc.html), or if it already
came with the ASN.1 Library package, it will be in `documentation/html`. Man
pages can be found in `documentation/man`; the man pages for executables will
be in `documentation/man/1`, and the man pages for library usage will be in
`documentation/man/8`. You may want to copy the man page files into
`/usr/share/man/1` and `/usr/share/man/3` respectively, or
`/usr/share/man/man1` and `/usr/share/man/man3` respectively, on some systems,
like Mac OS.