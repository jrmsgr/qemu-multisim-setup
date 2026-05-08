# qemu ↔️ multisim setup

Test setup enabling RISCV test code running on `qemu-system-riscv64` to communicate with an rtl sim via DPI and [multisim](https://github.com/antoinemadec/multisim/tree/main).

## Description

Here is how the setup works:

![qemu setup](./.img/qemu_hello_world_setup.drawio_white.png)

A custom device, `axe-dv-rtl-sim`, is instantiated inside a machine (i.e. the emulated version of a chip) at address `0x100000000`. Its write and read methods have been overridden to connect to a rtl sim running in parallel. Every time the program performs accesses to the address range of `axe-dv-rtl-sim`, the latter forwards the access info to the testbench and waits for a response. That response is then passed back to the machine and the execution continues.

## How to run

- Checkout all submodules:
```bash
git submodule init
git pull --recurse-submodules
```
- Make sure `verilator`, `riscv64-elf-gcc` and `riscv64-elf-objdump` are installed.
- Execute `run.sh` to compile and run everything
