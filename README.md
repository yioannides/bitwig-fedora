# bitwig-fedora
Downloads the latest Bitwig Studio and creates an RPM for it.

Only depends on rpm-build, not on Debian tools.
```sh
$ sudo dnf install rpm-build
```

Bitwig depends on the v8 implementation of JPEG, i.e. libjpeg.so.8. The
implementation shipping with Fedora is v6, so you need to first enable an additional COPR repository by running
```sh
$ sudo dnf copr enable aflyhorse/libjpeg
```

To create the RPM package for the latest stable release, run:
```sh
$ ./bitwig-rpm.sh
Determining latest stable version...
Downloading Bitwig Studio 6.0.11...
[...]
RPM created.
Install using sudo dnf install bitwig-studio-6.0.11.fc44.x86_64.rpm
```

If you want to download the latest beta release, run:
```sh
$ ./bitwig-rpm.sh --beta
Determining latest beta line...
Determining latest beta version...
Downloading Bitwig Studio 6.1-beta-4...
[...]
RPM created.
Install using sudo dnf install bitwig-studio-6.1-beta-4.fc44.x86_64.rpm
```

If you want to download a specific version, supply the version number to download as the first argument:
```sh
$ ./bitwig-rpm.sh 4.4.10
Finding version 4.4.10...
Downloading https://downloads.bitwig.com/4.4.10/bitwig-studio-4.4.10.deb
[...]
RPM created.
Install using sudo dnf install bitwig-studio-4.4.10-1.fc44.x86_64.rpm
```

If you already have downloaded the .deb package (e.g. for a beta pre-release), supply the path as the first argument:
```sh
$ ./bitwig-rpm.sh ~/Downloads/bitwig-studio-6.1beta1.deb
Extracting bitwig-studio-9.1beta1.deb...
Building RPM...
[...]
RPM created.
Install using sudo dnf install bitwig-studio-6.1beta1-1.fc44.x86_64.rpm
```

Automatically install the created RPM package by using command substitution to execute the script and pass the name of the RPM to a `dnf install` command
```sh
$ sudo dnf install $(./bitwig-rpm.sh) -y
$ sudo dnf install $(./bitwig-rpm.sh 4.4.10) -y
$ sudo dnf install $(./bitwig-rpm.sh ~/Downloads/bitwig-studio-9.1beta1.deb) -y
```
