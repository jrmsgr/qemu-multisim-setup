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

# Append multisim .so files to shared library paths
export LD_LIBRARY_PATH="$MULTISIM_RELEASE_DIR:$LD_LIBRARY_PATH"

# Add compiled QEMU to PATH
export PATH="$(realpath qemu/build/):$PATH"

banner "compiling sw"
cd sw
make example.elf

banner "running test"
cd ../tb
rm -rf .multisim
./run_verilator.sh &> sim.log &
./run_qemu.sh ../sw/example.elf

sleep 2 # Leave some time to verilator to exit

clean_exit=0
grep -E "^exiting!" sim.log &> /dev/null || clean_exit=1

if [[ $clean_exit != 0 ]]; then
    echo "simulation failed!"
    exit 1
fi
