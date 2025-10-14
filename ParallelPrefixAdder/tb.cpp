#include <iostream>
#include <memory>
#include <vector>
#include <random>
#include <iomanip>
#include <verilated.h>
#include "VPrefixAdder.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    // Instance
    auto adder = std::make_unique<VPrefixAdder>();

    using integer = int16_t;
    using uint = uint16_t;

    std::mt19937 rnd(std::random_device{}());
    uint64_t a_prev = 0;
    std::cout << "====progress====" << std::endl;
    for(uint64_t a = 0; a < std::numeric_limits<uint>::max(); a += rnd()%(0x10<<(sizeof(uint)*8-16)) + 1){
        if((a & (0xf000<<(sizeof(uint)*8-16))) != (a_prev & (0xf000<<(sizeof(uint)*8-16)))){
            std::cout << "|" << std::flush;
        }
        a_prev = a;
    for(uint64_t b = 0; b < std::numeric_limits<uint>::max(); b += rnd()%(0x10<<(sizeof(uint)*8-16)) + 1){
        auto add_test = [&adder, &rnd](uint a_, uint b_){
            uint64_t carry = rnd()%2;
            adder->a = a_;
            adder->b = b_;
            adder->cin = carry;
            adder->sub = 0;
            adder->eval();
            uint64_t sum = (uint64_t)a_ + (uint64_t)b_ + carry;
            if(adder->sum != (uint)sum || adder->cout != (sum >> sizeof(uint)*8)){
                std::cout << "adder mismatch!!!"
                        << " a : " << std::hex << std::setw(8) << std::setfill('0') << a_ 
                        << " b : " << std::hex << std::setw(8) << std::setfill('0') << b_ <<std::endl;
                std::cout << "result : " << std::hex << std::setw(8) << std::setfill('0') << adder->sum << std::endl;
                std::cout << "expect : " << std::hex << std::setw(8) << std::setfill('0') << a_ + b_ + carry << std::endl;
                std::cout << "carry result : " << (int)adder->cout << std::endl;
                std::cout << "carry expect : " << (sum >> (sizeof(uint)*8)) << std::endl;
                return true;
            }
            return false;
        };

        auto sub_test = [&adder](integer a_, integer b_){
            adder->a = a_;
            adder->b = b_;
            adder->cin = 1;
            adder->sub = 1;
            adder->eval();
            int64_t sub = (int64_t)a_ - (int64_t)b_;
            if(integer(adder->sum) != (integer)sub){
                std::cout << "subtract mismatch!!!"
                        << " a : " << std::hex << std::setw(8) << std::setfill('0') << a_ 
                        << " b : " << std::hex << std::setw(8) << std::setfill('0') << b_ <<std::endl;
                std::cout << "result : " << std::hex << std::setw(8) << std::setfill('0') << adder->sum << std::endl;
                std::cout << "expect : " << std::hex << std::setw(8) << std::setfill('0') << sub << std::endl;
                return true;
            }
            return false;
        };
        
        if(add_test(a, b) | add_test(b, a)) goto loop_break;
        if(sub_test(a, b) | sub_test(b, a)) goto loop_break;
    }
    }
loop_break:
    
    std::cout << std::endl;
}