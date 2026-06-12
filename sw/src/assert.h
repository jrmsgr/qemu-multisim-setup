#include "printf.h"

#define EXIT_SUCCESS 0
#define EXIT_FAILURE 1

void __attribute__((noreturn)) exit(int code);

#define STRINGIFY_INTERNAL(str) #str
#define STRINGIFY(str) STRINGIFY_INTERNAL(str)
#define ASSERT(cond)                       \
  {                                        \
    if (!(cond)) {                         \
      printf(__FILE__ ":" STRINGIFY(    \
          __LINE__) ": "                   \
                    "Assertion failed\n"); \
      exit(EXIT_FAILURE);                  \
    }                                      \
  }

