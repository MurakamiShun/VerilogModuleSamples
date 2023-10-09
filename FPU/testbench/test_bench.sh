#!/bin/bash

verilator --cc --exe --build -CFLAGS "--std=c++20" ../FloatingPointAdd.sv FloatingPointAdd_tb.cpp -I.. 
./obj_dir/VFloatingPointMul