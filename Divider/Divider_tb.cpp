#include <iostream>
#include <memory>
#include <vector>
#include <iomanip>
#include <random>
#include <tuple>
#include <verilated.h>
#include "VDivider.h"


int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    // Instance
    auto top = std::make_unique<VDivider>();

    auto rnd_egn = std::random_device{};

    std::vector<std::tuple<int32_t, int32_t>> test_data = {

    };
    for(int i = 0; i < 100000; ++i){
        test_data.push_back(std::make_tuple(rnd_egn(), rnd_egn()));
    }

    // reset module
    top->clk = 0;
    top->rst_n = 0;
    top->eval();
    top->clk = 1;
    top->eval();
    top->clk = 0;
    top->rst_n = 1;
    top->eval();
    top->clk = 1;
    top->eval();

    if(top->busy){
        std::cout << "module should not be busy after reset !!!" << std::endl;
        exit(-1);
    }
    if(top->done){
        std::cout << "done should not deassert after reset !!!" << std::endl;
        exit(-1);
    }

    for(const auto& test : test_data){
        top->clk = 0;
        top->en = 1;
        top->op_dividend = std::get<0>(test) < 0 ? -std::get<0>(test) : std::get<0>(test);
        top->op_divisor = std::get<1>(test) < 0 ? -std::get<1>(test) : std::get<1>(test);
        top->eval();
        top->clk = 1;
        top->eval();

        top->en = 0;
        while(true){
            if(top->done){
                int32_t result = std::get<0>(test) / std::get<1>(test);
                int32_t rem    = std::get<0>(test) % std::get<1>(test);
                if(top->busy){
                    std::cout << "module should not be busy after finish!!!" << std::endl;
                    exit(-1);
                }
                if((((std::get<0>(test) < 0) ^ (std::get<1>(test) < 0))? -top->result : top->result) != result){
                    std::cout << std::dec << std::setw(8) << "dividend:" << (int32_t)std::get<0>(test) << ", divisor:" << (int32_t)std::get<1>(test) << std::endl;
                    std::cout << "result is invalid!!!" << std::endl;
                    std::cout << "expect:" << result << ", result : " << top->result << std::endl;
                    exit(-1);
                }
                if((std::get<0>(test) < 0? -top->rem : top->rem) != rem){
                    std::cout << "rem is invalid!!!" << std::endl;
                    std::cout << std::dec << "expect:" << rem << ", result : " << top->rem << std::endl;
                    exit(-1);
                }
                break;
            }
            else {
                if(top->busy == false){
                    std::cout << "module should be busy until calculate !!!" << std::endl;
                    exit(-1);
               }
            }
            top->clk = 0;
            top->eval();
            top->clk = 1;
            top->eval();
        }
    }
}