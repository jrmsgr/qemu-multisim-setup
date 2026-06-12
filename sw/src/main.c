#include <stdint.h>
#include <stdbool.h>
#include "plic.h"
#include "printf.h"
#include "assert.h"

#define RTL_SIM_BASE_ADDRESS 0x100000000u
#define RTL_SIM_SIZE 0x100000000u
#define RTL_SIM_IRQ_TRIGGER_OFFSET (1000*8) // i_dv_axi_ram.mem[1000] address
#define RTL_SIM_IRQ_NUMBER 64 // Number of interrupts connected to i_axe_dv_interrupt_adapter
uintptr_t const rtl_sim = RTL_SIM_BASE_ADDRESS;
volatile uint64_t* irq_reg = (volatile uint64_t*)(rtl_sim+RTL_SIM_IRQ_TRIGGER_OFFSET);
volatile bool irq_fired;
uint64_t expected_irq = 0;

void external_irq_handler(uint32_t irq) {
  ASSERT((irq <= RTL_SIM_IRQ_NUMBER) && (irq >= 1));
  // Clear interrupt coming from axe-dv-rtl-sim
  *irq_reg &= ~((uint64_t)1<<(irq-1)); // Bit 0 triggers IRQ 1
  irq_fired=(expected_irq == irq);
}

uint64_t xorshift64(uint64_t *state) {
  uint64_t x = *state;
  x ^= x << 13;
  x ^= x >> 7;
  x ^= x << 17;
  return *state = x;
}

int main(void) {
  uint64_t val_u64 = 0xcafedecadeadbeef;
  uint32_t val_u32 = 0xf00dbabe;
  uint16_t val_u16 = 0xcad0;
  uint8_t val_u8 = 0xab;
  uint64_t expected_val;
  uint64_t mem_offset;
  uintptr_t mem_addr;
  uint32_t counter;

  printf("Testing AxSIZE...\n");
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


  printf("Testing WSTRB + data shift...\n");
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


  printf("Testing AxADDR...\n");
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

  printf("Testing interrupts...");

  // Enable external interrupts
  for (uint64_t irq=1; irq<= RTL_SIM_IRQ_NUMBER; irq++) {
    plic_set_interrupt_priority(irq, PLIC_MAX_PRIORITY); // max priority
    plic_enable_interrupt(irq);
  }

  for (uint64_t irq=1; irq<= RTL_SIM_IRQ_NUMBER; irq++) {
    irq_fired = false;
    counter = 0;
    expected_irq = irq;
    *irq_reg |= ((uint64_t)1<<(irq-1));
    while(!irq_fired && (counter < 100000)) {
      counter++;
    }

    if (!irq_fired) {
      printf("IRQ %lu did not fire!\n", irq);
      exit(EXIT_FAILURE);
    }
  }
  printf("All %d interrupts fired!\n", RTL_SIM_IRQ_NUMBER);

  printf("Test finished successfully!\n");
  return EXIT_SUCCESS;
}
