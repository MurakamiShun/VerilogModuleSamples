#include <iostream>
#include <memory>
#include <vector>
#include <iomanip>
#include <verilated.h>
#include "VMultiplier.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    // Instance
    auto mul = std::make_unique<VMultiplier>();

    const std::vector<std::tuple<uint64_t, uint32_t, uint32_t, bool, bool>> tests = {
        std::make_tuple(0xffff00810000ff7fUL, 0xaaaaaaab, 0x0002fe7d, true, true),
        std::make_tuple(0xffff00810000ff7fUL, 0x0002fe7d, 0xaaaaaaab, true, true),
        std::make_tuple(0x0000000000000000UL, 0x00000000, 0xffff8000, true, true),
        std::make_tuple(0x0000000000000000UL, 0x80000000, 0x00000000, true, true),
        std::make_tuple(0xffffffffffffffffUL, 0xffffffff, 0x00000001, true, true),
        std::make_tuple(0xffffffffffffffffUL, 0x00000001, 0xffffffff, true, true),

        std::make_tuple(0x0001fefe0000ff7fUL, 0xaaaaaaab, 0x0002fe7d, false, false),
        std::make_tuple(0x0001fefe0000ff7fUL, 0x0002fe7d, 0xaaaaaaab, false, false),
        std::make_tuple(0x0000000000000000UL, 0x00000000, 0xffff8000, false, false),
        std::make_tuple(0x0000000000000000UL, 0x80000000, 0x00000000, false, false),
        std::make_tuple(0x00000000ffffffffUL, 0xffffffff, 0x00000001, false, false),
        std::make_tuple(0x00000000ffffffffUL, 0x00000001, 0xffffffff, false, false),

        std::make_tuple(0xffff00810000ff7fUL, 0xaaaaaaab, 0x0002fe7d, true, false),
        std::make_tuple(0x0001fefe0000ff7fUL, 0x0002fe7d, 0xaaaaaaab, true, false),
        std::make_tuple(0x0000000000000000UL, 0x00000000, 0xffff8000, true, false),
        std::make_tuple(0x0000000000000000UL, 0x80000000, 0x00000000, true, false),
        std::make_tuple(0xffffffffffffffffUL, 0xffffffff, 0x00000001, true, false),
        std::make_tuple(0x00000000ffffffffUL, 0x00000001, 0xffffffff, true, false),

        std::make_tuple(0x0001fefe0000ff7fUL, 0xaaaaaaab, 0x0002fe7d, false, true),
        std::make_tuple(0xffff00810000ff7fUL, 0x0002fe7d, 0xaaaaaaab, false, true),
        std::make_tuple(0x0000000000000000UL, 0x00000000, 0xffff8000, false, true),
        std::make_tuple(0x0000000000000000UL, 0x80000000, 0x00000000, false, true),
        std::make_tuple(0x00000000ffffffffUL, 0xffffffff, 0x00000001, false, true),
        std::make_tuple(0xffffffffffffffffUL, 0x00000001, 0xffffffff, false, true),
    };

    mul->rst_n = 0;
    mul->clk = 0;
    mul->op1 = 0;
    mul->op2 = 0;
    mul->op1_sign = 0;
    mul->op2_sign = 0;
    mul->eval();
    mul->clk = 1;
    mul->eval();
    
    mul->rst_n = 1;
    for(const auto [expected, op1, op2, op1_sign, op2_sign] : tests){
        mul->clk = 0;
        mul->op1 = op1;
        mul->op2 = op2;
        mul->op1_sign = op1_sign;
        mul->op2_sign = op2_sign;
        mul->eval();
        mul->clk = 1;
        mul->eval();
        if(mul->result != 0){
            std::cout << "latency miss match!!!" << std::hex << std::setw(16) << std::setfill('0') << mul->result << std::endl;
            break;
        }
        
        mul->op1 = 0;
        mul->op2 = 0;
        mul->op1_sign = 0;
        mul->op2_sign = 0;
        mul->clk = 0;
        mul->eval();
        mul->clk = 1;
        mul->eval();
        if(mul->result != 0){
            std::cout << "latency miss match!!!" << std::hex << std::setw(16) << std::setfill('0') << mul->result << std::endl;
            break;
        }
        mul->clk = 0;
        mul->eval();
        mul->clk = 1;
        mul->eval();
        if(mul->result != expected){
            std::cout << "expected : " << std::hex << std::setw(16) << std::setfill('0') << expected << std::endl;
            std::cout << "result   : " << std::hex << std::setw(16) << std::setfill('0') << mul->result << std::endl;
            std::cout << "result   : " << std::hex << std::setw(8) << std::setfill('0') << op1 << (op1_sign ? " signed" : " unsigned") << std::endl;
            std::cout << "result   : " << std::hex << std::setw(8) << std::setfill('0') << op2 << (op2_sign ? " signed" : " unsigned") << std::endl;
            
            break;
        }
    }
    std::cout << "\u001b[32mtest passed!!" << std::endl;
}