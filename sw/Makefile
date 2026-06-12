.PHONY: clean

CC=riscv64-elf-gcc
OBJDUMP=riscv64-elf-objdump

HEADER_FILES := $(wildcard include/*.h)

SOURCE_FILES := crt.S hello.c

LINKER_SCRIPT := link.ld

MULTISIM_SERVER_NAME := multisim_server

C_FLAGS := -O2 \
	-mcmodel=large \
	-march=rv64gc \
	-mabi=lp64d \
	-static \
	-std=gnu99 \
	-ggdb \
	-ffreestanding \
	-fno-common \
	-Wall \
	-Wno-unknown-warning-option \
	-Wextra \
	-Werror \
	-Wno-cast-function-type-mismatch \
	-Wno-unused-variable \
	-Wno-unused-function \
	-Wno-unused-parameter \
	-fuse-ld=bfd \
	-static \
	-nostdlib \
	-lgcc \
	-Wl,--no-warn-rwx-segments \
	-Wl,--no-relax

COMPILE_FLAGS := $(C_FLAGS) -Iinclude/

.PHONY: compile_flags
compile_flags:
	echo "$(COMPILE_FLAGS)" | tr ' ' '\n' > compile_flags.txt

hello.elf: $(SOURCE_FILES) $(HEADER_FILES) $(LINKER_SCRIPT) compile_flags
	$(CC) $(COMPILE_FLAGS) -o $@ $(SOURCE_FILES) -T $(LINKER_SCRIPT)
	$(OBJDUMP) -D $@ > $@.S

clean:
	rm -f *.o *.elf *.elf.S compile_flags.txt
