#!/bin/bash

rgbasm -v -o world.o world.asm
rgblink -d -n world.sym -l pokered.link -o world.gb world.o
