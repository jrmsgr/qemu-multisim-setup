#include <stdint.h>
#include "trap.h"
#include "encoding.h"
#include "plic.h"

extern volatile uint64_t tohost;
extern volatile uint64_t fromhost;

#define RTL_SIM_BASE_ADDRESS 0x100000000u
#define RTL_SIM_SIZE 0x100000000u

void print_str_internal(char* str, uint32_t length) {
  for (uint32_t i = 0; i < length; i++) {
    tohost = ((uint64_t)1 << 56) | ((uint64_t)1 << 48) | (uint64_t)str[i];
    while (fromhost == 0);
    fromhost = 0;
  }
}

#define print_str(str) print_str_internal(str, sizeof(str) / sizeof(char))
#define STRINGIFY_INTERNAL(str) #str
#define STRINGIFY(str) STRINGIFY_INTERNAL(str)
#define ASSERT(cond)                       \
  {                                        \
    if (!(cond)) {                         \
      print_str(__FILE__ ":" STRINGIFY(    \
          __LINE__) ": "                   \
                    "Assertion failed\n"); \
      exit(1);                             \
    }                                      \
  }

uint64_t xorshift64(uint64_t *state) {
  uint64_t x = *state;
  x ^= x << 13;
  x ^= x >> 7;
  x ^= x << 17;
  return *state = x;
}


void __attribute__((noreturn)) exit(int code) {
  uint64_t code_extended = (unsigned int)code;
  tohost = (code_extended << 1) | 1;

  while (1) {
    asm("wfi");
  }
}

uintptr_t const rtl_sim = RTL_SIM_BASE_ADDRESS;

void trap_handler(SAVED_CONTEXT* context) {
  // Claim interrupt
  uint32_t int_id = plic_claim_interrupt();
  print_str("interrupt fired!\n");
  *(volatile uint8_t*)rtl_sim = 0x0;
  // Complete interrtupt
  plic_complete_interrupt(int_id);
}

void  _init(void) {
  int code = 1;
  uint64_t val_u64 = 0xcafedecadeadbeef;
  uint32_t val_u32 = 0xf00dbabe;
  uint16_t val_u16 = 0xcad0;
  uint8_t val_u8 = 0xab;
  uint64_t expected_val;
  uint64_t mem_offset;
  uintptr_t mem_addr;

  // Enable external interrupts
  set_csr(CSR_MIE, MIP_MEIP);
  set_csr(CSR_MSTATUS, MSTATUS_MIE);
  plic_set_interrupt_priority(1, 7); // max priority
  plic_enable_interrupt(1);
                                                    //
  // Check AxSIZE work correctly
  *(volatile uint64_t*)rtl_sim = val_u64;
  *(volatile uint32_t*)rtl_sim = val_u32;
  *(volatile uint16_t*)rtl_sim = val_u16;
  *(volatile uint8_t*)rtl_sim = val_u8;

  expected_val = val_u8;
  ASSERT(expected_val == *(volatile uint8_t*)rtl_sim);
  expected_val |= (val_u16 & 0xff00);
  ASSERT(expected_val == *(volatile uint16_t*)rtl_sim);
  expected_val |= (val_u32 & 0xffff0000);
  ASSERT(expected_val == *(volatile uint32_t*)rtl_sim);
  expected_val |= (val_u64 & 0xffffffff00000000);
  ASSERT(expected_val == *(volatile uint64_t*)rtl_sim);


  // Check WSTRB + data shift work correctly
  *(volatile uint64_t*)rtl_sim = val_u64;
  *(volatile uint32_t*)(rtl_sim+4) = val_u32;
  *(volatile uint16_t*)(rtl_sim+6) = val_u16;
  *(volatile uint8_t*)(rtl_sim+7) = val_u8;

  expected_val = val_u8;
  ASSERT(expected_val == *(volatile uint8_t*)(rtl_sim+7));
  expected_val = (val_u16 & 0x00ff) | (expected_val << 8);
  ASSERT(expected_val == *(volatile uint16_t*)(rtl_sim+6));
  expected_val = (val_u32 & 0x0000ffff) | (expected_val << 16);
  ASSERT(expected_val == *(volatile uint32_t*)(rtl_sim+4));
  expected_val = (val_u64 & 0x00000000ffffffff) | (expected_val << 32);
  ASSERT(expected_val == *(volatile uint64_t*)rtl_sim);


  // Check AxADDR work properly
  expected_val = 0xcafedecadeadbeef;
  mem_offset = 0;
  while (mem_offset < RTL_SIM_SIZE) {
      mem_addr = RTL_SIM_BASE_ADDRESS+mem_offset;
      *(volatile uint64_t*)mem_addr = expected_val;
      ASSERT(expected_val == *(volatile uint64_t*)mem_addr);
      xorshift64(&expected_val);

      mem_offset = mem_offset << 1;
      if (mem_offset < 8) {
          mem_offset = 8;
      }
  }

  print_str("Match!\n");
  exit(0);
}
