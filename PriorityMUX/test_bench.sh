verilator --cc --exe --build -CFLAGS "--std=c++20" PriorityMUX.v tb.cpp --top PriorityMUX
./obj_dir/VPriorityMUX