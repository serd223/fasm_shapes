#!/bin/sh
fasm main.asm
qemu-system-x86_64 -drive format=raw,file=main.bin
