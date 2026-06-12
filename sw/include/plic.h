#pragma once

/* Sifive PLIC util functions based on its instantiation inside ../../qemu/hw/riscv/axe_dv.c
 * For the full doc, see chapter 3.4.1.12 of the following pdf:
 * https://github.com/ganboing/EIC770x-Docs/blob/main/soc/EIC7700X_SoC_Technical_Reference_Manual_Part1.pdf
 */

#include <stdint.h>

#define PLIC_BASE 0xc000000
#define PLIC_NUM_IRQ 1
#define PLIC_NUM_SOURCES (PLIC_NUM_IRQ+1) /* num_sources (incl. reserved source 0) */
#define PLIC_NUM_PRIORITIES 7
#define PLIC_PRIORITY_BASE  0x00
#define PLIC_PENDING_BASE   0x1000
#define PLIC_ENABLE_BASE    0x2000
#define PLIC_CONTEXT_BASE   0x200000
#define PLIC_REG_SIZE_BIT   32

__attribute__((always_inline)) static inline void plic_set_interrupt_priority(uint32_t irq, uint32_t priority) {
    // TODO: Add assert here
    *(volatile uint32_t*)(uintptr_t)(PLIC_BASE+PLIC_PRIORITY_BASE+4*irq) = priority;
}

__attribute__((always_inline)) static inline void plic_enable_interrupt(uint32_t irq) {
    // TODO: Add assert here
    uint32_t plic_reg_offset = irq / PLIC_REG_SIZE_BIT;
    *(volatile uint32_t*)(uintptr_t)(PLIC_BASE+PLIC_ENABLE_BASE+plic_reg_offset) |= (uint32_t)(1<<(irq % PLIC_REG_SIZE_BIT));
}

__attribute__((always_inline)) static inline uint32_t plic_claim_interrupt(void) {
    uint32_t irq =  *(volatile uint32_t*)(PLIC_BASE+PLIC_CONTEXT_BASE+4);
    return irq;
}

__attribute__((always_inline)) static inline void plic_complete_interrupt(uint32_t irq) {
    // TODO: Add assert here
    *(volatile uint32_t*)(PLIC_BASE+PLIC_CONTEXT_BASE+4) = irq;
}


