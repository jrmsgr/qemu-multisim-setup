#!/usr/bin/env bash

set -e

trace=0
gdb=0
gdb_cmd=""
gui=0
multisim_server_name="multisim_server"
elf_name=""
extra_args=()

while [[ $# > 0 ]]; do
    case "$1" in
        --gui)
            gui=1
            shift
            ;;
        --gdb)
            gdb=1
            shift
            ;;
        --enable-trace)
            trace=1
            shift
            ;;
        *)
            elf_name="$1"
            shift
            ;;
    esac
done

if [[ $elf_name == "" ]]; then
    echo "No elf to process"
    exit 1
fi

if [[ $gdb == 1 ]]; then
    gdb_cmd="gdb --args"
fi

if [[ $gui == 0 ]]; then 
    extra_args+=("-nographic")
    extra_args+=("-serial mon:stdio")
fi

# WARNING: Disasm and event traces will both be logged in the same file
if [[ $trace == 1 ]]; then
    extra_args+=("-trace 'axe_dv_rtl_sim_*'")
fi

eval "$gdb_cmd ../qemu/build/qemu-system-riscv64 \
    -machine axe_dv,axe-dv-rtl-multisim-server-prefix=$multisim_server_name,axe-dv-rtl-sim-irq-number=64 \
    -bios $elf_name ${extra_args[@]} -d in_asm -D trace.log"
