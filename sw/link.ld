OUTPUT_ARCH( "riscv" )
ENTRY(_start)
MEMORY {
  dram (rwx) : ORIGIN = 0x80000000, LENGTH = 0x100000000 /* 4 GB */
}

SECTIONS {
  .text.init : ALIGN(64) {
    *(.text.init)
  } > dram
  ASSERT(
    ADDR(.text.init) == ORIGIN(dram),
    "Error: Boot code not at start of DRAM"
  )
  .tohost : ALIGN(0x1000) {
    *(.tohost)
    *(.*.tohost)
    . = ALIGN(0x1000);
  } > dram
  .text : ALIGN(64) {
    *(.text .text.*)
  } > dram
  .rodata : ALIGN(64) {
    *(.rodata .rodata.*)
  } > dram
  .data : ALIGN(64) {
    *(.data .data.*)
  } > dram
  .sdata : ALIGN(64) {
    __global_pointer$ = . + 0x800;
    *(.srodata .srodata.*)
    *(.sdata .sdata.*)
    *(.gnu.linkonce.s.*)
  } > dram
  .sbss : ALIGN(64) {
    _bss_begin = .;
    *(.sbss .sbss.*)
    *(.scommon .scommon.*)
    *(.gnu.linkonce.sb.*)
  } > dram
  .bss : ALIGN(64) {
    *(.bss)
    . = ALIGN(64);
    _bss_end = .;
  } > dram
  . = ALIGN(64);
  _thread_pointer = .;
  .tdata : ALIGN(4096) {
    _tdata_segment_begin = .;
    _tdata_begin = .;
    *(.tdata .tdata.*)
    . = ALIGN(64);
    _tdata_end = .;
    _tbss_begin = .;
    *(.tbss .tbss.*)
    . = ALIGN(64);
    _tbss_end = .;
    . = ALIGN(4096);
  . = ALIGN(4096);
  } > dram
  .runtime.tls (NOLOAD): ALIGN(4096) {
    _tls_begin = .;
    . = . + 6 * (_tbss_end - _tdata_begin);
    _tls_end = .;
  } > dram
  .runtime.stack (NOLOAD) : ALIGN(64) {
    _stack_begin = .;
    . = . + 6 * (1 << 17);
    _stack_end = .;
  } > dram
}
