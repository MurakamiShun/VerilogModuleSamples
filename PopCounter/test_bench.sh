verilator --cc --exe --build -CFLAGS "--std=c++20" PopCounter.sv tb.cpp --top PopCounter
./obj_dir/VPopCounter