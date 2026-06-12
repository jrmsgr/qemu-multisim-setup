#include <stdint.h>
#include "printf.h"
#include "encoding.h"
#include "assert.h"
#include "plic.h"

// Setup exit handler
void __attribute__((noreturn)) exit(int code) {
  uint64_t code_extended = (unsigned int)code;
  tohost = (code_extended << 1) | 1;

  while (1) {
    asm("wfi");
  }
}

// Default handler for external IRQs
void __attribute__((weak)) external_irq_handler(uint32_t irq) {
    (void)irq;
    printf("No ISR for external IRQs\n");
    exit(EXIT_FAILURE);
}


void trap_handler(void) {
  uint32_t mcause = read_csr(CSR_MCAUSE);
  uint32_t irq;
  if (mcause != IRQ_M_EXT) {
    printf("Unhandled exception: %u\n", mcause);
    exit(EXIT_FAILURE);
  }
  // Claim interrupt
  irq = plic_claim_interrupt();
  external_irq_handler(irq);
  // Complete interrupt
  plic_complete_interrupt(irq);
}

int main(void);

void _init(void) {
  // Enable external IRQs to reach the CPU
  set_csr(CSR_MIE, MIP_MEIP);
  set_csr(CSR_MSTATUS, MSTATUS_MIE);

  exit(main());
}
