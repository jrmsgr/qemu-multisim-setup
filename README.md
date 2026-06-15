# qemu ↔️ multisim setup

Test setup enabling RISCV test code running on `qemu-system-riscv64` to communicate with an rtl sim via DPI and [multisim](https://github.com/antoinemadec/multisim/tree/main).

## Description

Here is how the setup works:

![qemu setup](./.img/qemu_hello_world_setup.drawio_white.png)

A custom device, `axe-dv-rtl-sim`, is instantiated inside a machine (i.e. the emulated version of a chip) at address `0x100000000`. Its write and read methods have been overridden to connect to a rtl sim running in parallel. Every time the program performs accesses to the address range of `axe-dv-rtl-sim`, the latter forwards the access info to the testbench and waits for a response. That response is then passed back to the machine and the execution continues. Interrupts are handled by forwarding any state change to QEMU through a separate multisim channel. A dedicated thread takes care of triggering IRQs upon receiving packets.

Links to the different pieces:

- Custom device to communicate with QEMU: [axe-dv-rtl-sim.c](https://github.com/jrmsgr/qemu/blob/jrmsgr/axe-dv-rtl-sim/hw/misc/axe-dv-rtl-sim.c)
- Custom QEMU platform containing `axe-dv-rtl-sim`: [axe_dv.c](https://github.com/jrmsgr/qemu/blob/jrmsgr/axe-dv-rtl-sim/hw/riscv/axe_dv.c)
- RTL testbench: [top.sv](./tb/top.sv)
- QEMU packets to AXI adapter: [axe-dv-axi-adapter.sv](./tb/axe-dv-axi-adapter.sv)
- Interrupt forward block: [axe-dv-interrupt-adapter.sv](./tb/axe-dv-interrupt-adapter.sv)
- SW test running on QEMU: [main.c](./sw/src/main.c)


## How to run

- Checkout all submodules:
```bash
git submodule init
git pull --recurse-submodules
```
- Make sure `verilator`, `gcc/g++ >= 16.1.1`, `riscv64-elf-gcc` and `riscv64-elf-objdump` are installed.
- Execute `run.sh` to compile and run everything
