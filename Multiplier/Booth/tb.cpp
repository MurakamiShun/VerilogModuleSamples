#include <iostream>
#include <memory>
#include <vector>
#include <random>
#include <iomanip>
#include <verilated.h>
#include "VMultiplier.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    // Instance
    auto multiplier = std::make_unique<VMultiplier>();

    using integer = int32_t;
    using uint = uint32_t;
    constexpr auto width = 23;
    const uint64_t mask = ~((~(uint64_t)0) << width);

    std::mt19937 rnd(std::random_device{}());
    uint64_t a_prev = 0;
    std::cout << "====progress====" << std::endl;
    for(uint64_t a = 0; a < std::numeric_limits<uint>::max(); a += rnd()%(0x10<<(sizeof(uint)*8-16)) + 1){
        if((a & (0xf000<<(sizeof(uint)*8-16))) != (a_prev & (0xf000<<(sizeof(uint)*8-16)))){
            std::cout << "|" << std::flush;
        }
        a_prev = a;
    for(uint64_t b = 0; b < std::numeric_limits<uint>::max(); b += rnd()%(0x10<<(sizeof(uint)*8-16)) + 1){
        auto mul_test = [&multiplier, &rnd](uint64_t a_, uint64_t b_){
            multiplier->a = a_;
            multiplier->b = b_;
            multiplier->eval();
            uint64_t mul = (uint64_t)a_ * (uint64_t)b_;
            if(multiplier->result != mul){
                std::cout << "multiplier mismatch!!!"
                        << " a : " << std::hex << std::setw(8) << std::setfill('0') << a_ 
                        << " b : " << std::hex << std::setw(8) << std::setfill('0') << b_ <<std::endl;
                std::cout << "result : " << std::hex << std::setw(8) << std::setfill('0') << multiplier->result << std::endl;
                std::cout << "expect : " << std::hex << std::setw(8) << std::setfill('0') << (uint64_t)a_ * (uint64_t)b_ << std::endl;
                return true;
            }
            return false;
        };
        
        if(mul_test(a & mask, b & mask) | mul_test(b & mask, a & mask)) goto loop_break;
    }
    }
loop_break:
    
    std::cout << std::endl;
}