#include <stdint.h>

extern volatile uint64_t tohost;
extern volatile uint64_t fromhost;

#define RTL_SIM_BASE_ADDRESS 0x100000000u
#define RTL_SIM_SIZE 0x100000000u
#define ASSERT(cond) { \
    if (!(cond)) { \
      print_str("Mismatch\n", 9); \
      exit(1); \
    } \
  }

void print_str(char* str, uint32_t length) {
  for (uint32_t i = 0; i < length; i++) {
    tohost = ((uint64_t)1 << 56) | ((uint64_t)1 << 48) | (uint64_t)str[i];
    while (fromhost == 0);
    fromhost = 0;
  }
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

void  _init(void) {
  int code = 1;
  uintptr_t const rtl_sim = RTL_SIM_BASE_ADDRESS;
  uint64_t val_u64 = 0xcafedecadeadbeef;
  uint32_t val_u32 = 0xf00dbabe;
  uint16_t val_u16 = 0xcad0;
  uint8_t val_u8 = 0xab;
  uint64_t expected_val;
  uint64_t mem_offset;
  uintptr_t mem_addr;

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

  print_str("Match!\n", 7);
  exit(0);
}
