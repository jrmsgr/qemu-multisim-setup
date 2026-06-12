#pragma once

/* Sifive PLIC util functions based on its instantiation inside ../../qemu/hw/riscv/axe_dv.c
 * For the full doc, see chapter 3.4.1.12 of the following pdf:
 * https://github.com/ganboing/EIC770x-Docs/blob/main/soc/EIC7700X_SoC_Technical_Reference_Manual_Part1.pdf
 */

#include <stdint.h>
#include "assert.h"

#define PLIC_BASE 0xc000000
#define PLIC_NUM_IRQ 520 // Max number of IRQs supported by Sifive's plic
#define PLIC_NUM_SOURCES (PLIC_NUM_IRQ+1) /* num_sources (incl. reserved source 0) */
#define PLIC_MAX_PRIORITY 7
#define PLIC_PRIORITY_BASE  0x00
#define PLIC_PENDING_BASE   0x1000
#define PLIC_ENABLE_BASE    0x2000
#define PLIC_CONTEXT_BASE   0x200000
#define PLIC_REG_SIZE_BYTE  4
#define PLIC_REG_SIZE_BIT   (8*PLIC_REG_SIZE_BYTE)

__attribute__((always_inline)) static inline void plic_set_interrupt_priority(uint32_t irq, uint32_t priority) {
    ASSERT(irq <= PLIC_NUM_IRQ);
    ASSERT(priority <= PLIC_MAX_PRIORITY);
    *(volatile uint32_t*)(uintptr_t)(PLIC_BASE+PLIC_PRIORITY_BASE+PLIC_REG_SIZE_BYTE*irq) = priority;
}

__attribute__((always_inline)) static inline void plic_enable_interrupt(uint32_t irq) {
    ASSERT(irq <= PLIC_NUM_IRQ);
    uint32_t plic_reg_offset = irq / PLIC_REG_SIZE_BIT;
    *(volatile uint32_t*)(uintptr_t)(PLIC_BASE+PLIC_ENABLE_BASE+plic_reg_offset*PLIC_REG_SIZE_BYTE) |= (uint32_t)(1<<(irq % PLIC_REG_SIZE_BIT));
}

__attribute__((always_inline)) static inline uint32_t plic_claim_interrupt(void) {
    uint32_t irq =  *(volatile uint32_t*)(PLIC_BASE+PLIC_CONTEXT_BASE+PLIC_REG_SIZE_BYTE);
    return irq;
}

__attribute__((always_inline)) static inline void plic_complete_interrupt(uint32_t irq) {
    ASSERT(irq <= PLIC_NUM_IRQ);
    *(volatile uint32_t*)(PLIC_BASE+PLIC_CONTEXT_BASE+PLIC_REG_SIZE_BYTE) = irq;
}


