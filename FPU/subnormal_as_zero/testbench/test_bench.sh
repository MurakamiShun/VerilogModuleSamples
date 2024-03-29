#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)

verilator --cc --exe --build --Mdir mul_build -CFLAGS "--std=c++20" $SCRIPT_DIR/../FloatingPointMul.sv $SCRIPT_DIR/FloatingPointMul_tb.cpp -I.. &&\
$SCRIPT_DIR/mul_build/VFloatingPointMul && printf '\033[32m%s\033[m\n' 'Mul test succeed.'