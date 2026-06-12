#pragma once

#include <stdint.h>

extern volatile uint64_t tohost;
extern volatile uint64_t fromhost;

int printf(const char *fmt, ...);
