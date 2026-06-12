#include <stdarg.h>
#include <stdint.h>
#include "printf.h"

/* print chars out through spike front-end server mechanism */
void putchar(char c) {
    tohost = ((uint64_t)1 << 56) | ((uint64_t)1 << 48) | (uint64_t)c;
    while (fromhost == 0);
    fromhost = 0;
}

/* ------------------------------------------------------------------ */
/*  Internal helpers                                                    */
/* ------------------------------------------------------------------ */

static void emit_str(const char *s)
{
    if (!s) s = "(null)";
    while (*s) putchar(*s++);
}

/* Write an unsigned integer in the given base (2‥16).
   'upper' selects A-F vs a-f.
   Returns the number of characters emitted.                           */
static int emit_uint(unsigned long long val, int base, int upper,
                     int width, int zero_pad)
{
    static const char digits_lower[] = "0123456789abcdef";
    static const char digits_upper[] = "0123456789ABCDEF";
    const char *digits = upper ? digits_upper : digits_lower;

    /* Build the digits in a fixed-size stack buffer (64 bits in base 2
       is at most 64 characters, plus a NUL).                          */
    char buf[65];
    int  pos = 64;
    buf[pos] = '\0';

    if (val == 0) {
        buf[--pos] = '0';
    } else {
        while (val > 0) {
            buf[--pos] = digits[val % (unsigned)base];
            val /= (unsigned)base;
        }
    }

    int len     = 64 - pos;          /* digits already in buf */
    int padding = width - len;
    char pad_ch = zero_pad ? '0' : ' ';

    int written = 0;
    while (padding-- > 0) { putchar(pad_ch); written++; }

    const char *p = buf + pos;
    while (*p) { putchar(*p++); written++; }
    return written;
}

static int emit_int(long long val, int base, int upper,
                    int width, int zero_pad)
{
    if (val < 0) {
        putchar('-');
        /* Avoid UB on LLONG_MIN by casting before negation */
        return 1 + emit_uint((unsigned long long)(-(val + 1)) + 1,
                             base, upper, width > 0 ? width - 1 : 0,
                             zero_pad);
    }
    return emit_uint((unsigned long long)val, base, upper, width, zero_pad);
}

/* ------------------------------------------------------------------ */
/*  printf                                                         */
/* ------------------------------------------------------------------ */

int printf(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);

    int written = 0;

    for (; *fmt; fmt++) {
        if (*fmt != '%') {
            putchar(*fmt);
            written++;
            continue;
        }

        fmt++;   /* skip '%' */

        /* --- flags & width --- */
        int zero_pad = 0;
        int width    = 0;

        if (*fmt == '0') { zero_pad = 1; fmt++; }

        while (*fmt >= '1' && *fmt <= '9') {
            width = width * 10 + (*fmt - '0');
            fmt++;
        }

        /* --- length modifier --- */
        enum { LEN_INT, LEN_LONG, LEN_LLONG, LEN_SHORT, LEN_CHAR } length = LEN_INT;

        if (*fmt == 'h') {
            fmt++;
            if (*fmt == 'h') { length = LEN_CHAR;  fmt++; }
            else               length = LEN_SHORT;
        } else if (*fmt == 'l') {
            fmt++;
            if (*fmt == 'l') { length = LEN_LLONG; fmt++; }
            else               length = LEN_LONG;
        }

        /* --- conversion specifier --- */
        switch (*fmt) {

        case 'd': case 'i': {
            long long v;
            if      (length == LEN_LLONG) v = va_arg(ap, long long);
            else if (length == LEN_LONG)  v = va_arg(ap, long);
            else if (length == LEN_SHORT) v = (short)va_arg(ap, int);
            else if (length == LEN_CHAR)  v = (signed char)va_arg(ap, int);
            else                          v = va_arg(ap, int);
            written += emit_int(v, 10, 0, width, zero_pad);
            break;
        }

        case 'u': {
            unsigned long long v;
            if      (length == LEN_LLONG) v = va_arg(ap, unsigned long long);
            else if (length == LEN_LONG)  v = va_arg(ap, unsigned long);
            else if (length == LEN_SHORT) v = (unsigned short)va_arg(ap, unsigned int);
            else if (length == LEN_CHAR)  v = (unsigned char)va_arg(ap, unsigned int);
            else                          v = va_arg(ap, unsigned int);
            written += emit_uint(v, 10, 0, width, zero_pad);
            break;
        }

        case 'o': {
            unsigned long long v;
            if      (length == LEN_LLONG) v = va_arg(ap, unsigned long long);
            else if (length == LEN_LONG)  v = va_arg(ap, unsigned long);
            else                          v = va_arg(ap, unsigned int);
            written += emit_uint(v, 8, 0, width, zero_pad);
            break;
        }

        case 'x': case 'X': {
            int upper = (*fmt == 'X');
            unsigned long long v;
            if      (length == LEN_LLONG) v = va_arg(ap, unsigned long long);
            else if (length == LEN_LONG)  v = va_arg(ap, unsigned long);
            else                          v = va_arg(ap, unsigned int);
            written += emit_uint(v, 16, upper, width, zero_pad);
            break;
        }

        case 'p': {
            /* Pointer: emit as 0x<hex> */
            uintptr_t v = (uintptr_t)va_arg(ap, void *);
            putchar('0'); putchar('x'); written += 2;
            written += emit_uint((unsigned long long)v, 16, 0,
                                 width > 2 ? width - 2 : 0, 1);
            break;
        }

        case 'c': {
            putchar((char)va_arg(ap, int));
            written++;
            break;
        }

        case 's': {
            const char *s = va_arg(ap, const char *);
            if (!s) s = "(null)";
            int len = 0;
            const char *p = s;
            while (*p++) len++;
            int padding = width - len;
            while (padding-- > 0) { putchar(' '); written++; }
            emit_str(s);
            written += len;
            break;
        }

        case '%': {
            putchar('%');
            written++;
            break;
        }

        case 'n': {
            /* Store number of characters written so far */
            int *dest = va_arg(ap, int *);
            if (dest) *dest = written;
            break;
        }

        default:
            /* Unknown specifier — emit literally */
            putchar('%');
            putchar(*fmt);
            written += 2;
            break;
        }
    }

    va_end(ap);
    return written;
}
