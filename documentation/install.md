## Compile and Install

In `build/scripts` there are three scripts you can use to build the library.
When the library is built, it will be located in `build/libraries`.

### Installing `cli.lib`

This step is not technically necessary if you just want to build the library,
but it is required by all of the associated command line tools.

### On POSIX-Compliant Machines (Linux, Mac OS X)

Run `./build/scripts/build.sh`.
If you get a permissions error, you need to set that file to be executable
using the `chmod` command.

### On Windows

Run `.\build\scripts\build.bat` from a `cmd` or run `.\build\scripts\build.ps1`
from the PowerShell command line. If you get a warning about needing a
cryptographic signature for the PowerShell script, it is probably because
your system is blocking running unsigned PowerShell scripts. Just run the
other script if that is the case.