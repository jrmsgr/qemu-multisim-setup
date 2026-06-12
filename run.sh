#!/usr/bin/env bash

set -e

error() {
    echo "ERROR: $1" >&2
    exit 1
}

banner() {
    echo "##########################################"
    echo "$1"
    echo "##########################################"
}

check_cmd_exist() {
    cmd="$1"
    if ! command -v $cmd &> /dev/null; then
        error "Command '$1' does not exist"
    fi
}

# dependencies needed to run the tb
check_cmd_exist 'verilator'
check_cmd_exist 'riscv64-elf-gcc'
check_cmd_exist 'riscv64-elf-objdump'

MULTISIM_RELEASE_DIR=$(realpath "multisim_release/")

banner "building multisim shared libs"
source ./multisim/env.sh
make RELEASE_DIR=$MULTISIM_RELEASE_DIR TARGET=SW

# Append multisim .so files to shared library paths
export LD_LIBRARY_PATH="$MULTISIM_RELEASE_DIR:$LD_LIBRARY_PATH"

banner "building glib-2.0"
GLIB2_VERSION=2.66.8
GLIB2_INSTALL_DIR="$(realpath ./glib-$GLIB2_VERSION-release)"
export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$GLIB2_INSTALL_DIR/lib64/pkgconfig"
if ! pkg-config --atleast-version $GLIB2_VERSION glib-2.0; then
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
fi

# a recent version of gdbus-codegen is needed to build qemu
export PATH="$GLIB2_INSTALL_DIR/bin:$PATH"

banner "compiling qemu"
cd qemu
if ! [ -d build ]; then
    mkdir build
    cd build
    ../configure -Dmultisim-release-dir=$MULTISIM_RELEASE_DIR
else
    # qemu automatically reconfigures itself if a build is already present
    cd build
fi

make qemu-system-riscv64 -j8
cd ../..

banner "compiling sw"
cd sw
make hello.elf HETZNER=$hetzner

banner "running test"
cd ../tb
rm -rf .multisim
./run_verilator.sh &> sim.log &
./run_qemu.sh ../sw/hello.elf

clean_exit=0
grep -E "^exiting!" sim.log || clean_exit=1

if [[ $clean_exit != 0 ]]; then
    echo "simulation failed!"
    exit 1
fi
