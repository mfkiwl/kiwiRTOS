TARGET := i386-elf
PREFIX := /usr/local

AS := nasm
LD := ld
OBJCOPY := objcopy

KERNEL := kernel.bin
ISO := myos.iso

all: iso

iso: $(KERNEL)
    mkdir -p iso/boot/grub
    cp $(KERNEL) iso/boot/
    cp grub.cfg iso/boot/grub/
    grub-mkrescue -o $(ISO) iso

$(KERNEL): build
    zig build

run: iso
    qemu-system-i386 -cdrom $(ISO)

clean:
    rm -rf iso
    zig build clean
