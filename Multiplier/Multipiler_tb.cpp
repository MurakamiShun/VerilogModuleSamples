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


    mul->rst_n = 0;
    mul->clk = 0;
    mul->eval();
    mul->clk = 1;
    mul->eval();
    
    mul->rst_n = 1;
    mul->clk = 0;
    mul->op1 = 0xffffffff80000000;
    mul->op2 = 0xffffffffffff8000;
    mul->op1_sign = 1;
    mul->op2_sign = 0;
    mul->eval();
    mul->clk = 1;
    mul->eval();
    std::cout << std::hex << std::setw(8) << std::setfill('0') << mul->result[3] << "_"
        << std::hex << std::setw(8) << std::setfill('0') << mul->result[2] << "_"
        << std::hex << std::setw(8) << std::setfill('0') << mul->result[1] << "_"
        << std::hex << std::setw(8) << std::setfill('0') << mul->result[0] << std::endl;
    mul->clk = 0;
    mul->eval();
    mul->clk = 1;
    mul->eval();
    std::cout << std::hex << std::setw(8) << std::setfill('0') << mul->result[3] << "_"
        << std::hex << std::setw(8) << std::setfill('0') << mul->result[2] << "_"
        << std::hex << std::setw(8) << std::setfill('0') << mul->result[1] << "_"
        << std::hex << std::setw(8) << std::setfill('0') << mul->result[0] << std::endl;
    mul->clk = 0;
    mul->eval();
    mul->clk = 1;
    mul->eval();
    std::cout << std::hex << std::setw(8) << std::setfill('0') << mul->result[3] << "_"
        << std::hex << std::setw(8) << std::setfill('0') << mul->result[2] << "_"
        << std::hex << std::setw(8) << std::setfill('0') << mul->result[1] << "_"
        << std::hex << std::setw(8) << std::setfill('0') << mul->result[0] << std::endl;
    
    // std::cout << std::hex << std::setw(16) << std::setfill('0') << mul->result << std::endl;
    // mul->clk = 0;
    // mul->eval();
    // mul->clk = 1;
    // mul->eval();
    // std::cout << std::hex << std::setw(16) << std::setfill('0') << mul->result << std::endl;
    // mul->clk = 0;
    // mul->eval();
    // mul->clk = 1;
    // mul->eval();
    // std::cout << std::hex << std::setw(16) << std::setfill('0') << mul->result << std::endl;
}