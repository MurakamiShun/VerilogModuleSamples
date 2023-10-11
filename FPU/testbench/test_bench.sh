#!/bin/bash

verilator --cc --exe --build --Mdir add_build -CFLAGS "--std=c++20" ../FloatingPointAdd.sv FloatingPointAdd_tb.cpp -I.. &&\
./add_build/VFloatingPointAdd && printf '\033[32m%s\033[m\n' 'Add test succeed.'

verilator --cc --exe --build --Mdir mul_build -CFLAGS "--std=c++20" ../FloatingPointMul.sv FloatingPointMul_tb.cpp -I.. &&\
./mul_build/VFloatingPointMul