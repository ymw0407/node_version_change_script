#!/bin/bash

loading_animation() {
    local -r chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local -r delay=0.1
    local char

    i=0

    while true; do
        i=$((i + 1))
        char="${chars:i%10:1}"
        printf "\r[$char]"
        sleep $delay
    done
    printf "\r%*s\r" "${COLUMNS:-$(tput cols)}" ""
}

finish() {
    if [ -n "$loading_animation_pid" ]; then
        kill "$loading_animation_pid"
    fi
}

check_os_type() {
    if [ "x$(id -u)" != x0 ]; then
        echo "You might have to run it as root user."
        echo "Please run it again with 'sudo'."
        echo
        exit 1
    fi
    OPT="${@}"

    echo -n "    Checking OS..."
    loading_animation &
    loading_animation_pid=$!

    source /etc/os-release

    if [ ! -f /etc/os-release ]; then
        printf "\r%*s\r" "${COLUMNS:-$(tput cols)}" ""
        echo -e "\r[✘] Your distribution is not supported, so please install manually."
        echo
        exit 1
    fi

    distro=$(grep "^ID=" /etc/os-release | cut -d\= -f2 | sed -e 's/"//g')
    id_like=$(grep "^ID_LIKE=" /etc/os-release | cut -d\= -f2 | sed -e 's/"//g')

    case $distro in
    "ubuntu" | "debian")
        check_os_version $ID $VERSION_ID $PRETTY_NAME
        ;;
    *)
        printf "\r%*s\r" "${COLUMNS:-$(tput cols)}" ""
        echo -e "\r[✘] \"$PRETTY_NAME\" is not supported yet, so please install manually."
        exit 1
        ;;
    esac
    finish
}

check_os_version() {
    if [[ "$1" == "ubuntu" ]]; then
        major_version=${2%%.*}
        if [[ "$major_version" -ge 22 ]]; then
            echo -e "\r[✔] $3 $2 can use our service!"
        else
            echo -e "\r[✘] $3 $2 can't install node v18"
        fi
    elif [[ "$1" == "debian" ]]; then
        if [[ "$2" -ge 10 ]]; then
            echo -e "\r[✔] $3 can use our service!"
        else
            echo -e "\r[✘] $3 can't install node v18"
        fi
    else
        echo "This is not an Ubuntu or Debian-based Linux distribution."
    fi
}

check_nodejs_installed() {
    echo -n "    Checking Node.js installation..."
    loading_animation &
    loading_animation_pid=$!

    if ! command -v node &>/dev/null; then
        echo -e "\r[✘] Node.js is not installed!"
        finish
        install_nodejs_confirm
        exit 0
    else
        printf "\r%*s\r" "${COLUMNS:-$(tput cols)}" ""
        echo -e "\r[✔] Node.js is already installed!"
        finish
    fi
}

check_nodejs_version() {
    echo -n "    Checking Node.js version..."
    loading_animation &
    loading_animation_pid=$!

    node_version=$(node -v)
    version_without_v=${node_version#v}
    major_version=${version_without_v%%.*}

    if [ "$major_version" -ge 18 ]; then
        printf "\r%*s\r" "${COLUMNS:-$(tput cols)}" ""
        echo -e "\r[✔] Node.js version is $node_version!"
        finish
        install_nodejs_confirm
    else
        printf "\r%*s\r" "${COLUMNS:-$(tput cols)}" ""
        echo -e "\r[✔] Node.js version is $node_version!"
        finish
        install_nodejs_confirm
    fi
}

install_nodejs() {
    apt-get purge nodejs &&
        rm -r /etc/apt/sources.list.d/nodesource.list &&
        rm -r /etc/apt/keyrings/nodesource.gpg

    curl -SLO https://deb.nodesource.com/nsolid_setup_deb.sh
    chmod 500 nsolid_setup_deb.sh
    ./nsolid_setup_deb.sh $1
    apt-get install nodejs -y

    echo "-----------------------------------------"
    echo
    echo "node $(node -v) installed!"
    echo "Re-launch install.sh!"
    exit 0
}

install_nodejs_confirm() {
    options+=("18" "20" "21" "exit")

    select version in "${options[@]}"; do
        if [[ "$version" == "exit" ]]; then
            exit 0
        fi
        if [[ "$version" ]]; then
            install_nodejs $version
            break
        else
            exit 0
        fi
    done
}

check_os_type
check_nodejs_installed
check_nodejs_version
