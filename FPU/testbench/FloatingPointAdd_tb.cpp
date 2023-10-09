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
#include "VFloatingPointAdd.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    // Instance
    auto mul_unit = std::make_unique<VFloatingPointAdd>();
    
    using fp_type = float;
    using fp_bit = uint32_t;

    //auto rnd_egn = std::mt19937_64(std::random_device{}());
    auto rnd_egn = std::random_device{};

    std::vector<std::array<fp_type, 2>> test_data = {
        {(fp_type)0.0, (fp_type)-0.0},
        {(fp_type)1.0, (fp_type)-1.0},
        {(fp_type)0x1.FFFFFEp0, (fp_type)-0x1.FFFFFEp0}, // carry up on mantissa mul
        {(fp_type)0x1.FFFFFEp0, (fp_type)-0x1.000002p0},
        {(fp_type)0x1.FFFFFEp0, (fp_type)0x1.000002p0},
        {(fp_type)0x1.FFFFFEp120, (fp_type)0x1.000000p7},
        {(fp_type)0x1.FFFFFEp120, (fp_type)0x1.000000p8}, // overflow
        {(fp_type)0x1.FFFFFEp-70, (fp_type)-0x1.000000p-110},
        {(fp_type)0x1.FFFFFEp-63, (fp_type)0x1.000000p-63},
        {(fp_type)0x1.FFFFFEp-63, (fp_type)0x1.000000p-64}, // under flow
        {std::numeric_limits<fp_type>::infinity(), (fp_type)0x1.FFFFFEp0}, // inf
        {(fp_type)0x1.FFFFFEp0, std::numeric_limits<fp_type>::infinity()}, // inf
        {-std::numeric_limits<fp_type>::infinity(), (fp_type)0x1.FFFFFEp0}, // -inf
        {(fp_type)-0x1.FFFFFEp0, std::numeric_limits<fp_type>::infinity()}, // -inf
        {std::numeric_limits<fp_type>::quiet_NaN(), (fp_type)0x1.FFFFFEp0}, // nan
        {(fp_type)-0x1.FFFFFEp0, std::numeric_limits<fp_type>::quiet_NaN()}, // nan
        {std::numeric_limits<fp_type>::infinity(), (fp_type)0.0}, // inf*0
        {(fp_type)0.0, std::numeric_limits<fp_type>::infinity()}, // 0*inf
        {std::bit_cast<fp_type>(rnd_egn()), std::bit_cast<fp_type>(rnd_egn())},
        {std::bit_cast<fp_type>(rnd_egn()), std::bit_cast<fp_type>(rnd_egn())},
        {std::bit_cast<fp_type>(rnd_egn()), std::bit_cast<fp_type>(rnd_egn())},
        {std::bit_cast<fp_type>(rnd_egn()), std::bit_cast<fp_type>(rnd_egn())},
        {std::bit_cast<fp_type>(rnd_egn()), std::bit_cast<fp_type>(rnd_egn())},
        {std::bit_cast<fp_type>(rnd_egn()), std::bit_cast<fp_type>(rnd_egn())},
        {std::bit_cast<fp_type>(rnd_egn()), std::bit_cast<fp_type>(rnd_egn())},
        {std::bit_cast<fp_type>(rnd_egn()), std::bit_cast<fp_type>(rnd_egn())},
        {std::bit_cast<fp_type>(rnd_egn()), std::bit_cast<fp_type>(rnd_egn())},
        {std::bit_cast<fp_type>(rnd_egn()), std::bit_cast<fp_type>(rnd_egn())},
        {std::bit_cast<fp_type>(rnd_egn()), std::bit_cast<fp_type>(rnd_egn())},
        {std::bit_cast<fp_type>(rnd_egn()), std::bit_cast<fp_type>(rnd_egn())},
    };

    std::fesetround(FE_TONEAREST);
    for(int i = 0; i < test_data.size(); ++i){
        mul_unit->op1 = std::bit_cast<fp_bit>(test_data[i][0]);
        mul_unit->op2 = std::bit_cast<fp_bit>(test_data[i][1]);
        mul_unit->round_mode = 0;

        mul_unit->eval();
        if(mul_unit->result != std::bit_cast<fp_bit>(test_data[i][0]* test_data[i][1])){
            std::cout << "FE_TONEAREST: " << std::dec << i << " test" << std::endl;
            std::cout << "op1 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][0])
                << " : " << std::hexfloat << test_data[i][0] << std::endl;
            std::cout << "op2 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][1])
                << " : " << std::hexfloat << test_data[i][1] << std::endl;
            std::cout << "result = " << std::setfill('0') << std::right << std::hex << std::setw(8) << mul_unit->result
                << " : " << std::hexfloat << std::bit_cast<fp_type>(mul_unit->result) << std::endl;
            std::cout << "expect = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][0] + test_data[i][1])
                << " : " << std::hexfloat << test_data[i][0] + test_data[i][1] << std::endl;
        }
    }

    std::fesetround(FE_TOWARDZERO);
    for(int i = 0; i < test_data.size(); ++i){
        mul_unit->op1 = std::bit_cast<fp_bit>(test_data[i][0]);
        mul_unit->op2 = std::bit_cast<fp_bit>(test_data[i][1]);
        mul_unit->round_mode = 1;

        mul_unit->eval();
        if(mul_unit->result != std::bit_cast<fp_bit>(test_data[i][0]* test_data[i][1])){
            std::cout << "FE_TOWARDZERO: " << std::dec << i << " test" << std::endl;
            std::cout << "op1 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][0])
                << " : " << std::hexfloat << test_data[i][0] << std::endl;
            std::cout << "op2 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][1])
                << " : " << std::hexfloat << test_data[i][1] << std::endl;
            std::cout << "result = " << std::setfill('0') << std::right << std::hex << std::setw(8) << mul_unit->result
                << " : " << std::hexfloat << std::bit_cast<fp_type>(mul_unit->result) << std::endl;
            std::cout << "expect = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][0] + test_data[i][1])
                << " : " << std::hexfloat << test_data[i][0] + test_data[i][1] << std::endl;
        }
    }
    std::fesetround(FE_DOWNWARD);
    for(int i = 0; i < test_data.size(); ++i){
        mul_unit->op1 = std::bit_cast<fp_bit>(test_data[i][0]);
        mul_unit->op2 = std::bit_cast<fp_bit>(test_data[i][1]);
        mul_unit->round_mode = 2;

        mul_unit->eval();
        if(mul_unit->result != std::bit_cast<fp_bit>(test_data[i][0]* test_data[i][1])){
            std::cout << "FE_DOWNWARD: " << std::dec << i << " test" << std::endl;
            std::cout << "op1 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][0])
                << " : " << std::hexfloat << test_data[i][0] << std::endl;
            std::cout << "op2 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][1])
                << " : " << std::hexfloat << test_data[i][1] << std::endl;
            std::cout << "result = " << std::setfill('0') << std::right << std::hex << std::setw(8) << mul_unit->result
                << " : " << std::hexfloat << std::bit_cast<fp_type>(mul_unit->result) << std::endl;
            std::cout << "expect = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][0] + test_data[i][1])
                << " : " << std::hexfloat << test_data[i][0] + test_data[i][1] << std::endl;
        }
    }
    std::fesetround(FE_UPWARD);
    for(int i = 0; i < test_data.size(); ++i){
        mul_unit->op1 = std::bit_cast<fp_bit>(test_data[i][0]);
        mul_unit->op2 = std::bit_cast<fp_bit>(test_data[i][1]);
        mul_unit->round_mode = 3;

        mul_unit->eval();
        if(mul_unit->result != std::bit_cast<fp_bit>(test_data[i][0]* test_data[i][1])){
            std::cout << "FE_UPWARD: " << std::dec << i << " test" << std::endl;
            std::cout << "op1 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][0])
                << " : " << std::hexfloat << test_data[i][0] << std::endl;
            std::cout << "op2 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][1])
                << " : " << std::hexfloat << test_data[i][1] << std::endl;
            std::cout << "result = " << std::setfill('0') << std::right << std::hex << std::setw(8) << mul_unit->result
                << " : " << std::hexfloat << std::bit_cast<fp_type>(mul_unit->result) << std::endl;
            std::cout << "expect = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][0] + test_data[i][1])
                << " : " << std::hexfloat << test_data[i][0] + test_data[i][1] << std::endl;
        }
    }


    mul_unit->final();
}