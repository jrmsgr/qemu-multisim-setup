#!/usr/bin/env bash

set -e

source $(dirname $(realpath $(readlink -f "$0")))/utils.sh

cd $REPO_ROOT

MULTISIM_RELEASE_DIR=$(realpath "multisim_release/")

banner "building multisim shared libs"
source ./multisim/env.sh
make RELEASE_DIR=$MULTISIM_RELEASE_DIR TARGET=SW

# Append multisim .so files to shared library paths
export LD_LIBRARY_PATH="$MULTISIM_RELEASE_DIR:$LD_LIBRARY_PATH"

banner "building glib-2.0"
GLIB2_VERSION=2.66.8
GLIB2_INSTALL_DIR="$(realpath ./glib-$GLIB2_VERSION-release)"
glib2_archive="glib-$GLIB2_VERSION.tar.xz"
echo "Downloading GLIB2 v$GLIB2_VERSION"
wget "https://download.gnome.org/sources/glib/${GLIB2_VERSION%.*}/$glib2_archive"
tar -xf $glib2_archive
cd "${glib2_archive%.tar*}"
meson setup _build
meson configure --prefix="$GLIB2_INSTALL_DIR" _build
meson compile -C _build
meson install -C _build
cd ..

export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$GLIB2_INSTALL_DIR/lib64/pkgconfig"

# a recent version of gdbus-codegen is needed to build qemu
export PATH="$GLIB2_INSTALL_DIR/bin:$PATH"

banner "compiling qemu"
mkdir -p qemu/build
cd qemu/build
../configure -Dmultisim-release-dir=$MULTISIM_RELEASE_DIR
make qemu-system-riscv64 -j8
