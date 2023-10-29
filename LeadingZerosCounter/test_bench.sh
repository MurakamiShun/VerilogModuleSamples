verilator --cc --exe --build -CFLAGS "--std=c++20" LeadingZerosCounter.sv LeadingZerosCounter_tb.cpp 
./obj_dir/VLeadingZerosCounter