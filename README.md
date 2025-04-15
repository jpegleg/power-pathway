# power-pathway 🐉

PowerShell may be Windows centric, but can be run on Linux and MacOS.
Both Kali and Alpine have "powershell" packages available to install from within the standard repositories.
It can also be used on Debian-based systems, although is a direct .deb install.

The project https://github.com/jpegleg/elvish-pathway is related to this project, with
significant overlap in script functionality but using [Elvish](https://elv.sh/) instead of PowerShell.
Both Elvish and PowerShell have some common design choices, including my favorite aspects of each
which is the ability to have built-in parallelism and structured data objects.

## Additional tools

Simmilarly to the elvish-pathway, there are tools used from the [dwarven-toolbox](https://github.com/jpegleg/dwarven-toolbox/), [file_encryption_AES256](https://github.com/jpegleg/file_encryption_AES256/), and [wormsign](https://github.com/jpegleg/wormsign) projects.

The installer script compiles those tools with `cargo` and deploys them to `/usr/local/bin/`.

