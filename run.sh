#!/bin/bash
fasm main.asm
qemu-system-x86_64 main.bin
