#!/data/data/com.termux/files/usr/bin/bash

time1="$( date +"%r" )"

install_gentoo () {
    directory="gentoo-fs"
    TARBALL_URL="https://gentoo.osuosl.org/releases/arm64/autobuilds/latest-stage3-arm64-openrc.txt"
    TARBALL_NAME=$(curl -s $TARBALL_URL | grep -oP 'stage3-arm64-openrc-\d{8}T\d{6}Z\.tar\.xz')
    TARBALL_URL="https://gentoo.osuosl.org/releases/arm64/autobuilds/current-stage3-arm64-openrc/$TARBALL_NAME"
    TARBALL_SHA256=$(curl -s $TARBALL_URL.sha256 | awk '{print $1}')

    if [ -d "$directory" ]; then
        first=1
        printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;227m[WARNING]:\e[0m \x1b[38;5;87m Skipping the download and the extraction\n"
    elif [ -z "$(command -v proot)" ]; then
        printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;203m[ERROR]:\e[0m \x1b[38;5;87m Please install proot.\n"
        printf "\e[0m"
        exit 1
    elif [ -z "$(command -v wget)" ]; then
        printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;203m[ERROR]:\e[0m \x1b[38;5;87m Please install wget.\n"
        printf "\e[0m"
        exit 1
    fi

    if [ "$first" != 1 ]; then
        if [ -f "$TARBALL_NAME" ]; then
            rm -rf "$TARBALL_NAME"
        fi

        if [ ! -f "$TARBALL_NAME" ]; then
            printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;83m[Installer thread/INFO]:\e[0m \x1b[38;5;87m Downloading the Gentoo rootfs, please wait...\n"
            wget "$TARBALL_URL" -q -O "$TARBALL_NAME"
            if [ $? -ne 0 ]; then
                printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;203m[ERROR]:\e[0m \x1b[38;5;87m Failed to download the tarball.\n"
                exit 1
            fi
            printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;83m[Installer thread/INFO]:\e[0m \x1b[38;5;87m Download complete!\n"
        fi

        # Verificar o checksum
        printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;83m[Installer thread/INFO]:\e[0m \x1b[38;5;87m Verifying checksum...\n"
        checksum=$(sha256sum "$TARBALL_NAME" | awk '{print $1}')
        if [ "$checksum" != "$TARBALL_SHA256" ]; then
            printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;203m[ERROR]:\e[0m \x1b[38;5;87m Checksum verification failed!\n"
            exit 1
        else
            printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;83m[Installer thread/INFO]:\e[0m \x1b[38;5;87m Checksum verified!\n"
        fi

        cur=$(pwd)
        mkdir -p "$directory"
        cd "$directory"
        printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;83m[Installer thread/INFO]:\e[0m \x1b[38;5;87m Decompressing the Gentoo rootfs, please wait...\n"
        proot --link2symlink tar -xJf "$cur/$TARBALL_NAME" --exclude='dev' || :
        printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;83m[Installer thread/INFO]:\e[0m \x1b[38;5;87m The Gentoo rootfs has been successfully decompressed!\n"

        printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;83m[Installer thread/INFO]:\e[0m \x1b[38;5;87m Fixing resolv.conf for internet access...\n"
        echo "nameserver 8.8.8.8" > etc/resolv.conf
        echo "nameserver 8.8.4.4" >> etc/resolv.conf

        cd "$cur"
    fi

    mkdir -p gentoo-binds
    bin="startgentoo.sh"
    printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;83m[Installer thread/INFO]:\e[0m \x1b[38;5;87m Creating the start script, please wait...\n"
    cat > "$bin" <<- EOM
#!/bin/bash
cd \$(dirname \$0)
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r $directory"
if [ -n "\$(ls -A gentoo-binds)" ]; then
    for f in gentoo-binds/* ;do
      . \$f
    done
fi
command+=" -b /dev"
command+=" -b /proc"
command+=" -b /sys"
command+=" -b gentoo-fs/tmp:/dev/shm"
command+=" -b /data/data/com.termux"
command+=" -b /:/host-rootfs"
command+=" -b /sdcard"
command+=" -b /storage"
command+=" -b /mnt"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"
com="\$@"
if [ -z "\$1" ];then
    exec \$command
else
    \$command -c "\$com"
fi
EOM

    printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;83m[Installer thread/INFO]:\e[0m \x1b[38;5;87m The start script has been successfully created!\n"
    printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;83m[Installer thread/INFO]:\e[0m \x1b[38;5;87m Fixing shebang of startgentoo.sh, please wait...\n"
    termux-fix-shebang "$bin"
    printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;83m[Installer thread/INFO]:\e[0m \x1b[38;5;87m Successfully fixed shebang of startgentoo.sh!\n"
    printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;83m[Installer thread/INFO]:\e[0m \x1b[38;5;87m Making startgentoo.sh executable, please wait...\n"
    chmod +x "$bin"
    printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;83m[Installer thread/INFO]:\e[0m \x1b[38;5;87m Successfully made startgentoo.sh executable!\n"
    
    # Configuração automática do emerge --sync
    printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;83m[Installer thread/INFO]:\e[0m \x1b[38;5;87m Synchronizing packages, this can take a long time...\n"
    proot -r "$directory" -w / /bin/bash -c "emerge-webrsync"

    # Configuração automática do Portage
    printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;83m[Installer thread/INFO]:\e[0m \x1b[38;5;87m Configuring Portage, please wait...\n"
    
    # Usar proot para configurar o perfil do Gentoo
    proot -r "$directory" -w / /bin/bash -c "eselect profile list"
    proot -r "$directory" -w / /bin/bash -c "eselect profile set default/linux/arm64/23.0"

    # Configurar as opções básicas de compilação
    cat <<EOF > "$directory/etc/portage/make.conf"
# Configurações básicas do Portage
CFLAGS="-O2 -pipe -march=armv8-a"
CXXFLAGS="\${CFLAGS}"
CHOST="aarch64-unknown-linux-gnu"
MAKEOPTS="-j4"
USE="-X -gtk -gnome -qt5 -kde bindist"
FEATURES="parallel-fetch"
ACCEPT_LICENSE="*"
EOF

    # Atualizar o sistema básico
    proot -r "$directory" -w / /bin/bash -c "emerge --update --deep --newuse @world"

    printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;83m[Installer thread/INFO]:\e[0m \x1b[38;5;87m Portage configuration complete!\n"

    printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;83m[Installer thread/INFO]:\e[0m \x1b[38;5;87m Cleaning up, please wait...\n"
    rm -f "$TARBALL_NAME"
    printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;83m[Installer thread/INFO]:\e[0m \x1b[38;5;87m Successfully cleaned up!\n"
    printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;83m[Installer thread/INFO]:\e[0m \x1b[38;5;87m The installation has been completed! You can now launch Gentoo with ./startgentoo.sh\n"
    printf "\e[0m"
}

if [ "$1" = "-y" ]; then
    install_gentoo
elif [ "$1" = "" ]; then
    printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;127m[QUESTION]:\e[0m \x1b[38;5;87m Do you want to install Gentoo in Termux? [Y/n] "
    read cmd1
    if [ "$cmd1" = "y" ] || [ "$cmd1" = "Y" ]; then
        install_gentoo
    else
        printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;203m[ERROR]:\e[0m \x1b[38;5;87m Installation aborted.\n"
        printf "\e[0m"
        exit
    fi
else
    printf "\x1b[38;5;214m[${time1}]\e[0m \x1b[38;5;203m[ERROR]:\e[0m \x1b[38;5;87m Installation aborted.\n"
    printf "\e[0m"
fi
