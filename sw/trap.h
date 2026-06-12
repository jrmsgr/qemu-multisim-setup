#pragma once

typedef struct {
  union {
    struct {
      long unused;
      long x1;
      long x2;
      long x3;
      long x4;
      long x5;
      long x6;
      long x7;
      long x8;
      long x9;
      long x10;
      long x11;
      long x12;
      long x13;
      long x14;
      long x15;
      long x16;
      long x17;
      long x18;
      long x19;
      long x20;
      long x21;
      long x22;
      long x23;
      long x24;
      long x25;
      long x26;
      long x27;
      long x28;
      long x29;
      long x30;
      long x31;
    };
    long caller_regs[32];
  };
  long mcause;
  long mepc;
  long mstatus;
  long mtval;

  // FPU state is not saved for now

} SAVED_CONTEXT;
