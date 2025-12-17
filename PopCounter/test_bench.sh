verilator --cc --exe --build -Wall -CFLAGS "--std=c++20" PopCounter.sv tb.cpp --top PopCounter
./obj_dir/VPopCounter