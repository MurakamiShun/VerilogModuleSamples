#include <iostream>
#include <memory>
#include <vector>
#include <random>
#include <bitset>
#include <bit>
#include <iomanip>
#include <verilated.h>
#include "VPopCounter.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    // Instance
    auto pop_cntr = std::make_unique<VPopCounter>();

    std::minstd_rand rnd_egn(45345);
    for(uint64_t i = 0; i < UINT32_MAX; i+=rnd_egn()%0x100){
        pop_cntr->i_data = i;
        pop_cntr->eval();
        if(pop_cntr->o_data != std::popcount(i)){
            std::cout << "Error!!!!!!!!!!!!!" << std::endl;
            std::cout << "input : "  << std::hex << pop_cntr->i_data << std::endl;
            std::cout << "result : " << std::dec << pop_cntr->o_data << std::endl;
            std::cout << "expect : " << std::dec << std::popcount(i) << std::endl;
            exit(1);
        }
    }

}

