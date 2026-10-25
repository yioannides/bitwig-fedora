#!/usr/bin/env bash
SPEC=bitwig-studio.spec

BOLD="\e[1m"
BLUE="\e[34m"
BLUE_BG="\e[48;5;20m\e[38;5;255m\e[1m"
ESC_END="\e[0m"

STATIC_LINK="https://www.bitwig.com/dl/Bitwig%20Studio"

request_sudo()
{
	tput clear
	echo -e "${BLUE_BG} BITWIG-FEDORA ${ESC_END}"
	echo -e "${BOLD}by teervo & yioannides${ESC_END}\n"
	sleep 0.5
	sudo -v
	while sleep 60; do sudo -n true; done &
	trap 'kill $!' EXIT
}

check_dependencies()
{
	echo -e "${BOLD}Checking dependencies...${ESC_END}\n" 1>&2
	if ! dnf list --installed | grep -q "rpm-build"; then
		sudo dnf install rpm-build -y
	fi
	if ! dnf repo list | grep -q "aflyhorse:libjpeg"; then
		sudo dnf copr enable aflyhorse/libjpeg -y
	fi
}

pull_versions()
{
    echo "Gathering available packages..." >&2
    curl --silent --location https://bitwig.com/download/ |
        grep -Eo 'dl/Bitwig%20Studio/[0-9]+\.[0-9]+(\.[0-9]+)?/installer_linux' |
        head -n1 |
        grep -Eo '[0-9]+\.[0-9]+(\.[0-9]+)?'
}

url_exists()
{
    [[ $(curl --silent --output /dev/null --location --head \
        --write-out '%{http_code}' "$1") == 200 ]]
}

get_download_url()
{	
    local STABLE MAJOR MINOR POINT
    STABLE=$(pull_versions)
    IFS=. read -r MAJOR MINOR POINT <<< "$STABLE"
	
	case "$1" in
		"")
			echo "Determining latest stable version..." 1>&2
			RELATIVE_URL="$STABLE/installer_linux"
			;;
		-b | --beta)
			echo "Determining latest beta line..." 1>&2
			while url_exists "$STATIC_LINK/${MAJOR}.$((MINOR+1))%20Beta%201/installer_linux"; do
				MINOR=$((MINOR+1))
			done

			echo "Determining latest beta version..." 1>&2
			POINT=1
			while url_exists "$STATIC_LINK/${MAJOR}.${MINOR}%20Beta%20$((POINT+1))/installer_linux"; do
				POINT=$((POINT+1))
			done
			RELATIVE_URL="${MAJOR}.${MINOR}%20Beta%20${POINT}/installer_linux"
			;;
		-p | --pre-release)
			echo "Determining latest pre-release version..." 1>&2
			while url_exists "$STATIC_LINK/${MAJOR}.${MINOR}.$((POINT+1))/installer_linux"; do
				POINT=$((POINT+1))
			done
			RELATIVE_URL="${MAJOR}.${MINOR}.${POINT}/installer_linux"
			;;
		*)
			echo "Finding version $1..." 1>&2
			RELATIVE_URL=$1/installer_linux	
			;;
	esac

	FULL_URL=$STATIC_LINK/$RELATIVE_URL
	curl -L --head -w '%{url_effective}' $FULL_URL 2>/dev/null | tail -n1
}


download_bitwig()
{
    local DOWNLOAD_URL TARGET_PATH FILENAME VERSION CLEAN_URL

    DOWNLOAD_URL=$(get_download_url "$@") || return 1
    TARGET_PATH=rpmbuild/SOURCES
    CLEAN_URL=$(sed 's/?.*//' <<< "$DOWNLOAD_URL")
    FILENAME=$(basename "$CLEAN_URL")
    VERSION=$(grep -oP 'bitwig-studio-\K.*(?=\.deb)' <<< "$DOWNLOAD_URL")

    echo
    echo -e "\nDownloading ${BOLD}Bitwig Studio ${VERSION}${ESC_END}...\n${CLEAN_URL}" >&2
    curl --create-dirs --output-dir "$TARGET_PATH" \
        --remote-name -C - "$DOWNLOAD_URL" || return 1
    echo "$TARGET_PATH/$FILENAME"
}

rpm_basename()
{
	base=$(basename $DEBIAN_PKG .deb)
	fedora_release=$(cut -d ' ' -f 3 /etc/redhat-release)
	arch=$(uname -m)

	echo $base.fc$fedora_release.$arch.rpm
}

check_if_already_built()
{
	RPM=$(rpm_basename)
	if [ -f $RPM ]; then
		echo -e "${BLUE}RPM package already built! \n${ESC_END}" 1>&2
		install_rpm
		exit 0
	fi
}

extract_deb()
{
	echo -e "\nExtracting ${BOLD}$(basename $1)...${ESC_END}\n" 1>&2
	OUTPUT_DIRECTORY=rpmbuild/SOURCES
	rm -rf $OUTPUT_DIRECTORY/{*.xz,*.zst}
	mkdir -p $OUTPUT_DIRECTORY
	ar x --output $OUTPUT_DIRECTORY $1
}

create_rpmspec()
{
	TARBALL_CONTROL=control.tar.xz
	TARBALL_DATA=data.tar.xz
	if [ ! -f $OUTPUT_DIRECTORY/$TARBALL_CONTROL ]; then
		TARBALL_CONTROL=control.tar.zst
		TARBALL_DATA=data.tar.zst
	fi

	CONTROL=$(mktemp)
	tar axf $OUTPUT_DIRECTORY/$TARBALL_CONTROL ./control -O > $CONTROL

	DEB_VERSION=$(grep '^Version:' $CONTROL | cut -d' ' -f2)
	VERSION_MAIN=$(echo "$DEB_VERSION" | cut -d'-' -f1)
	VERSION_SUFFIX=$(echo "$DEB_VERSION" | cut -d'-' -f2-)
	RELEASE=$(echo "$VERSION_SUFFIX" | tr '-' '_')

	echo "%global _topdir ./rpmbuild"
	echo "%global __brp_mangle_shebangs %{nil}"
	echo "%global __brp_check_rpaths %{nil}"
	echo "%global debug_package %{nil}"
	echo "%undefine _missing_build_ids_terminate_build"
	echo

	echo "Name:    bitwig-studio"
	echo "Version: $VERSION_MAIN"
	echo "Release: 0.$RELEASE%{?dist}"
	echo "Summary: Digital Audio Workstation"
	echo

	echo "License: Proprietary"
	echo "URL:   $(grep Homepage $CONTROL | sed 's/Homepage: //')"
	echo "Source0:  rpmbuild/SOURCES/$TARBALL_DATA"
	echo

	echo "%description"
	grep Descript -A1 $CONTROL | sed 's/Description: //'
	echo

	echo "%install"
	echo "mkdir -p %{buildroot}/"
	echo "tar axf %{SOURCE0} -C %{buildroot}"
	echo "find %{buildroot} -name '*.css' -exec chmod 0644 {} \;"
	echo "find %{buildroot} -name '*.html' -exec chmod 0644 {} \;"
	echo "find %{buildroot} -name '*.js' -exec chmod 0644 {} \;"
	echo "find %{buildroot} -name '*.nckk' -exec chmod 0644 {} \;"
	echo "find %{buildroot} -name '*.txt' -exec chmod 0644 {} \;"
	echo

	echo "%files"
	echo "/opt/bitwig-studio"
	LIST=$(tar tf rpmbuild/SOURCES/$TARBALL_DATA | grep /usr | sed s/^.//g)
	for x in $LIST; do
		[ ! -d $x ] && echo $x
	done

	rm $CONTROL
}

build_rpm()
{
	echo -e "\n${BOLD}Building RPM...${ESC_END}\n" 1>&2
	QA_RPATHS=$(( 0x0001|0x0002 )) rpmbuild --build-in-place -bb $SPEC || return 1
	RPM_FILE=$(find rpmbuild/RPMS/x86_64 -name '*.rpm' -type f -print -quit) || return 1
	mv "$RPM_FILE" . || return 1
	RPM_FILE=$(basename "$RPM_FILE")
	rm -rf rpmbuild bitwig-studio.spec
	echo
	echo -e "RPM created: ${BOLD}$RPM_FILE${ESC_END}\n" >&2
}

install_rpm()
{
	echo -e "\n${BOLD}Installing RPM...${ESC_END}\n" 1>&2
	sudo dnf install -y "$RPM_FILE"
	echo -e "\n${BOLD}Installation complete! ${ESC_END}\n" 1>&2
}

case "$1" in
    *.deb)
    	request_sudo
        DEBIAN_PKG=$1
        ;;
    "")
    	request_sudo
        DEBIAN_PKG=$(download_bitwig)
        ;;
    -b | --beta | -p | --pre-release)
    	request_sudo
        DEBIAN_PKG=$(download_bitwig "$1")
        ;;
    *)
        if [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        	request_sudo
            DEBIAN_PKG=$(download_bitwig "$1")
        else
        		echo -e "\n${BOLD}ERROR: Unknown input${ESC_END}"
        		echo "Please refer to the README for instructions:"
        		echo "https://github.com/yioannides/bitwig-fedora#optional-arguments"
        		echo
        		exit 2
        fi
        ;;
esac

check_dependencies
check_if_already_built $DEBIAN_PKG
extract_deb $DEBIAN_PKG
create_rpmspec $DEBIAN_PKG > $SPEC
build_rpm
install_rpm
