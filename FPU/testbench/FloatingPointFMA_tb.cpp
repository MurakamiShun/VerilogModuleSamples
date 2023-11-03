#include <iostream>
#include <memory>
#include <bit>
#include <array>
#include <vector>
#include <cfenv>
#include <random>
#include <iomanip>
#include <limits>
#include <verilated.h>
#include "VFloatingPointFMA.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    // Instance
    auto fma_unit = std::make_unique<VFloatingPointFMA>();
    
    using fp_type = float;
    using fp_bit = uint32_t;

    //auto rnd_egn = std::mt19937_64(std::random_device{}());
    auto rnd_egn = std::random_device{};

    std::vector<std::array<fp_type, 3>> test_data = {
        {(fp_type)1.0, (fp_type)1.0, (fp_type)1.0e-120},
        {(fp_type)0x1.FFFFFEp0, (fp_type)0x1.000002p0, (fp_type)1.0e-120},
        {(fp_type)1.0, (fp_type)1.0, (fp_type)0x1.0p-2},
        {(fp_type)1.0, (fp_type)1.0, (fp_type)0x1.0p2},
        {(fp_type)1.0, (fp_type)1.111, (fp_type)1.3},
        {(fp_type)1.0, (fp_type)1.111, (fp_type)-1.3},
        {(fp_type)0x1.FFFFFEp0, (fp_type)0x1.FFFFFEp0, (fp_type)1.0e-120},
    };

    for(int i = 0; i < 5; ++i){
        test_data.push_back(
            {std::bit_cast<fp_type>(rnd_egn()), std::bit_cast<fp_type>(rnd_egn()), std::bit_cast<fp_type>(rnd_egn())}
        );
    }

    std::fesetround(FE_TONEAREST);
    for(int i = 0; i < test_data.size(); ++i){
        fma_unit->op1 = std::bit_cast<fp_bit>(test_data[i][0]);
        fma_unit->op2 = std::bit_cast<fp_bit>(test_data[i][1]);
        fma_unit->op_sum = std::bit_cast<fp_bit>(test_data[i][2]);
        fma_unit->round_mode = 0;

        fma_unit->eval();
        if(fma_unit->result != std::bit_cast<fp_bit>(std::fma(test_data[i][0], test_data[i][1], test_data[i][2]))){
            std::cout << "FE_TONEAREST: " << std::dec << i << " test" << std::endl;
            std::cout << "op1 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][0])
                << " : " << std::hexfloat << test_data[i][0] << std::endl;
            std::cout << "op2 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][1])
                << " : " << std::hexfloat << test_data[i][1] << std::endl;
            std::cout << "opsum = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][2])
                << " : " << std::hexfloat << test_data[i][2] << std::endl;
            std::cout << "result = " << std::setfill('0') << std::right << std::hex << std::setw(8) << fma_unit->result
                << " : " << std::hexfloat << std::bit_cast<fp_type>(fma_unit->result) << std::endl;
            std::cout << "expect = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(std::fma(test_data[i][0], test_data[i][1], test_data[i][2]))
                << " : " << std::hexfloat << std::fma(test_data[i][0], test_data[i][1], test_data[i][2]) << std::endl;
        }
    }

    std::fesetround(FE_TOWARDZERO);
    for(int i = 0; i < test_data.size(); ++i){
        fma_unit->op1 = std::bit_cast<fp_bit>(test_data[i][0]);
        fma_unit->op2 = std::bit_cast<fp_bit>(test_data[i][1]);
        fma_unit->op_sum = std::bit_cast<fp_bit>(test_data[i][2]);
        fma_unit->round_mode = 1;

        fma_unit->eval();
        if(fma_unit->result != std::bit_cast<fp_bit>(std::fma(test_data[i][0], test_data[i][1], test_data[i][2]))){
            std::cout << "FE_TOWARDZERO: " << std::dec << i << " test" << std::endl;
            std::cout << "op1 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][0])
                << " : " << std::hexfloat << test_data[i][0] << std::endl;
            std::cout << "op2 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][1])
                << " : " << std::hexfloat << test_data[i][1] << std::endl;
            std::cout << "opsum = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][2])
                << " : " << std::hexfloat << test_data[i][2] << std::endl;
            std::cout << "result = " << std::setfill('0') << std::right << std::hex << std::setw(8) << fma_unit->result
                << " : " << std::hexfloat << std::bit_cast<fp_type>(fma_unit->result) << std::endl;
            std::cout << "expect = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(std::fma(test_data[i][0], test_data[i][1], test_data[i][2]))
                << " : " << std::hexfloat << std::fma(test_data[i][0], test_data[i][1], test_data[i][2]) << std::endl;
        }
    }
    std::fesetround(FE_DOWNWARD);
    for(int i = 0; i < test_data.size(); ++i){
        fma_unit->op1 = std::bit_cast<fp_bit>(test_data[i][0]);
        fma_unit->op2 = std::bit_cast<fp_bit>(test_data[i][1]);
        fma_unit->op_sum = std::bit_cast<fp_bit>(test_data[i][2]);
        fma_unit->round_mode = 2;

        fma_unit->eval();
        if(fma_unit->result != std::bit_cast<fp_bit>(std::fma(test_data[i][0], test_data[i][1], test_data[i][2]))){
            std::cout << "FE_DOWNWARD: " << std::dec << i << " test" << std::endl;
            std::cout << "op1 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][0])
                << " : " << std::hexfloat << test_data[i][0] << std::endl;
            std::cout << "op2 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][1])
                << " : " << std::hexfloat << test_data[i][1] << std::endl;
            std::cout << "opsum = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][2])
                << " : " << std::hexfloat << test_data[i][2] << std::endl;
            std::cout << "result = " << std::setfill('0') << std::right << std::hex << std::setw(8) << fma_unit->result
                << " : " << std::hexfloat << std::bit_cast<fp_type>(fma_unit->result) << std::endl;
            std::cout << "expect = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(std::fma(test_data[i][0], test_data[i][1], test_data[i][2]))
                << " : " << std::hexfloat << std::fma(test_data[i][0], test_data[i][1], test_data[i][2]) << std::endl;
        }
    }
    std::fesetround(FE_UPWARD);
    for(int i = 0; i < test_data.size(); ++i){
        fma_unit->op1 = std::bit_cast<fp_bit>(test_data[i][0]);
        fma_unit->op2 = std::bit_cast<fp_bit>(test_data[i][1]);
        fma_unit->op_sum = std::bit_cast<fp_bit>(test_data[i][2]);
        fma_unit->round_mode = 3;

        fma_unit->eval();
        if(fma_unit->result != std::bit_cast<fp_bit>(std::fma(test_data[i][0], test_data[i][1], test_data[i][2]))){
            std::cout << "FE_UPWARD: " << std::dec << i << " test" << std::endl;
            std::cout << "op1 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][0])
                << " : " << std::hexfloat << test_data[i][0] << std::endl;
            std::cout << "op2 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][1])
                << " : " << std::hexfloat << test_data[i][1] << std::endl;
            std::cout << "opsum = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][2])
                << " : " << std::hexfloat << test_data[i][2] << std::endl;
            std::cout << "result = " << std::setfill('0') << std::right << std::hex << std::setw(8) << fma_unit->result
                << " : " << std::hexfloat << std::bit_cast<fp_type>(fma_unit->result) << std::endl;
            std::cout << "expect = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(std::fma(test_data[i][0], test_data[i][1], test_data[i][2]))
                << " : " << std::hexfloat << std::fma(test_data[i][0], test_data[i][1], test_data[i][2]) << std::endl;
        }
    }


    fma_unit->final();
}