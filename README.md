> [!IMPORTANT]
> <b>[teervo](https://github.com/teervo) (the original author) transferred ownership to me, therefore development will continue here. Thank you!</b>

----

![showcase](https://github.com/user-attachments/assets/af930e0a-a710-4c26-828e-6daea7854654)

#### auto-installation:
```sh
curl -s https://raw.githubusercontent.com/yioannides/bitwig-fedora/main/bitwig-rpm.sh | bash -s --
```
#### manual installation:
```sh
wget https://raw.githubusercontent.com/yioannides/bitwig-fedora/main/bitwig-rpm.sh &&
chmod +x bitwig-rpm.sh && ./bitwig-rpm.sh
```

> [!NOTE]
> The script always defaults to the <b>latest stable version</b>.

#### optional arguments:

Both installation methods accept additional arguments at the end, for example:

| argument | description |
| --- | --- |
| `-b` or `--beta` | the latest beta* |
| `-p` or `--pre-release` | the latest pre-release* |
| (example) `5.1.3` | an older / specific version |
| `/path/to/local/bitwig-studio.deb` | your locally stored `.deb` file |

<sup>* when available

#### aliases:

You can manage easier future installations via aliases in `.bashrc` by running the commands below only once:

##### alias for auto-installation:
```sh
echo 'alias bitwig-update="curl -s https://raw.githubusercontent.com/yioannides/bitwig-fedora/main/bitwig-rpm.sh | bash -s --"' >> $HOME/.bashrc
```
##### alias for manual installation (change the script's path!):
```sh
echo 'alias bitwig-update="/path/to/bitwig-rpm.sh"' >> $HOME/.bashrc
```

Then simply use as:
```sh
user@linux:~$ bitwig-update
```
<sup>NOTE: Optional arguments still work with aliases!

#### acknowledgements:

[teervo](https://github.com/teervo): author of the original script / repo
