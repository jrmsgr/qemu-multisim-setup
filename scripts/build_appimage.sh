#!/usr/bin/env

set -e

source $(dirname $(realpath $(readlink -f "$0")))/utils.sh

cd $REPO_ROOT

banner "Downloading appimagetool and linuxdeploy from github"
if  ! [ -d appimage_utils ]; then
    mkdir appimage_utils/
    cd appimage_utils/
    wget https://github.com/AppImage/appimagetool/releases/latest/download/appimagetool-x86_64.AppImage
    wget https://github.com/linuxdeploy/linuxdeploy/releases/latest/download/linuxdeploy-x86_64.AppImage
    chmod +x *.AppImage
    cd ..
fi

banner "Creating AppImage dir structure"
./appimage_utils/linuxdeploy-x86_64.AppImage --appdir QemuMultisim.AppDir/  \
                                             -e qemu/build/qemu-system-riscv64 \
                                             -d ./QemuMultisim.AppDir/qemu-multisim.desktop \
                                             -i ./QemuMultisim.AppDir/qemu.svg

# Override copied libs as linuxdeploy incorrectly infer which ones to copy
# TODO: Call `strip` on copied to reduce size
cp multisim_release/*.so usr/lib
cp -r ./glib-*-release/lib64/ usr/lib

banner "Building AppImage"
./appimage_utils/appimagetool-x86_64.AppImage QemuMultisim.AppDir/
