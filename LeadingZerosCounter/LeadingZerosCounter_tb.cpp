#include <iostream>
#include <memory>
#include <vector>
#include <iomanip>
#include <verilated.h>
#include "VLeadingZerosCounter.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    // Instance
    auto lzc = std::make_unique<VLeadingZerosCounter>();

    std::vector<uint32_t> test_data = {
        0x00,
        uint32_t(~0)
    };
    for(int i = 0; i < 32; ++i){
        test_data.push_back(test_data.back() >> 1);
    }

    for(const auto i : test_data){
        lzc->Di = i;
        lzc->eval();
        std::cout << i << " : " << (uint16_t)lzc->Do << std::endl;
    }



}