verilator --cc --exe --build -CFLAGS "--std=c++20" Multiplier.v tb.cpp --top Multiplier
./obj_dir/VMultiplier