#!/bin/bash

rgbasm -v -o main.o main.asm
rgblink -d -n reimp.sym -o reimp.gbc main.o
rgbfix -cjsv -k 01 -l 0x33 -m 0x1b -p 0 -r 03 reimp.gbc
