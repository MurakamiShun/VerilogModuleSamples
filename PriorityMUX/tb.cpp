#include <iostream>
#include <memory>
#include <vector>
#include <bitset>
#include <iomanip>
#include <verilated.h>
#include "VPriorityMUX.h"
#include "VPriorityMUX___024root.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    // Instance
    auto mux = std::make_unique<VPriorityMUX>();
    constexpr auto N = 19;

    for(int i = 0; i < N; ++i){
        mux->i_data[i] = i;
    }

    std::array<uint64_t, 8> test_sel = {
        0b000000001,
        0b000000011,
        0b000000101,
        0b000001111,
        0b000100101,
        0b100100111,
        0b010000101,
        0b11001110111,
    };

    for(const auto sel : test_sel){
        for(int t = 0; t < N; ++t){
            mux->sel = sel << t;
            mux->eval();
            if(mux->o_data != ((sel << t) == 0 ? mux->i_data[N-1] : mux->i_data[t])){
                std::cout << "Error!!!!!!!!!!!!!" << std::endl;
                std::cout << mux->o_data << std::endl;
                std::cout << std::bitset<N>(sel << t) << std::endl;
                exit(1);
            }
        }
    }

}

