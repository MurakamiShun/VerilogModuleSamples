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
    auto add_unit = std::make_unique<VFloatingPointAdd>();
    
    using fp_type = float;
    using fp_bit = uint32_t;

    //auto rnd_egn = std::mt19937_64(std::random_device{}());
    auto rnd_egn = std::random_device{};

    std::vector<std::array<fp_type, 2>> test_data = {
        {(fp_type)2.3, (fp_type)1.1},
        {(fp_type)2.3, (fp_type)-1.1},
        {(fp_type)-2.3, (fp_type)1.1},
        {(fp_type)1.0, (fp_type)0x1.0p-24},
        {(fp_type)0x1.FFFFFFFFFFFFFFFFFFFp0, (fp_type)0x1.0p-60},
        {(fp_type)6.543, (fp_type)6.3476e+10},
        {(fp_type)-0x1.249138p-127, (fp_type)-0x1.249138p-127},
        {(fp_type)-0x1.249138p-127, (fp_type)0x1.0b3e9ap-113},
        {(fp_type)-0x1.249138p127, (fp_type)0x1.0b3e9ap127}, // overflow
        {(fp_type)0x1.a181f4p-65, (fp_type)0x1.9bf2dcp-68}, // under flow
        {(fp_type)0x1.fb9e3ap+27, (fp_type)-0x1.bfcd04p+35},
        {(fp_type)0x1.5fb544p-16, (fp_type)-0x1.400c5p-10},

        {(fp_type)0x1.2584dp-128, (fp_type)-0x1.44e534p-126}, //denormal
        {(fp_type)-0x1.2f6e2p-128, (fp_type)0x1.f924p-131},
        {(fp_type)-0x1.4f060ep-126, (fp_type)0x1.18fcd4p-127},
        {(fp_type)-0x1.4f649p-128, (fp_type)0x1.59d6b4p-127},

        {(fp_type)-0x1.d9aaaep+29, (fp_type)0x1.352018p+30}, // 2path

        {(fp_type)0.0, (fp_type)0.0},
        {(fp_type)0.0, (fp_type)-0.0},
        {(fp_type)-0.0, (fp_type)-0.0},
        {(fp_type)1.0, (fp_type)-1.0},
        {(fp_type)0x1.FFFFFEp0, (fp_type)-0x1.FFFFFEp0}, // carry up on mantissa mul
        {(fp_type)0x1.FFFFFEp0, (fp_type)-0x1.000002p0},
        {(fp_type)0x1.FFFFFEp0, (fp_type)0x1.000002p0},
        {(fp_type)0x1.FFFFFEp120, (fp_type)0x1.000000p7},
        {(fp_type)0x1.FFFFFEp120, (fp_type)0x1.000000p8}, // overflow
        {(fp_type)0x1.f99bacp+127, (fp_type)0x1.0c2ad4p+122},
        {(fp_type)0x1.FFFFFEp-70, (fp_type)-0x1.000000p-110}, // under flow
        {(fp_type)0x1.FFFFFEp-63, (fp_type)0x1.000000p-63},
        {(fp_type)0x1.FFFFFEp-63, (fp_type)0x1.000000p-64},
        {std::numeric_limits<fp_type>::infinity(), (fp_type)0x1.FFFFFEp0}, // inf
        {std::numeric_limits<fp_type>::infinity(), std::numeric_limits<fp_type>::infinity()}, // inf
        {std::numeric_limits<fp_type>::infinity(), -std::numeric_limits<fp_type>::infinity()}, // inf
        {-std::numeric_limits<fp_type>::infinity(), std::numeric_limits<fp_type>::infinity()}, // inf
        {-std::numeric_limits<fp_type>::infinity(), -std::numeric_limits<fp_type>::infinity()}, // inf
        {(fp_type)0x1.FFFFFEp0, std::numeric_limits<fp_type>::infinity()}, // inf
        {-std::numeric_limits<fp_type>::infinity(), (fp_type)0x1.FFFFFEp0}, // -inf
        {(fp_type)-0x1.FFFFFEp0, std::numeric_limits<fp_type>::infinity()}, // -inf
        {std::numeric_limits<fp_type>::quiet_NaN(), (fp_type)0x1.FFFFFEp0}, // nan
        {(fp_type)-0x1.FFFFFEp0, std::numeric_limits<fp_type>::quiet_NaN()}, // nan
        {std::numeric_limits<fp_type>::infinity(), (fp_type)0.0}, // inf*0
        {(fp_type)0.0, std::numeric_limits<fp_type>::infinity()}, // 0*inf
    };
    
    for(int i = 0; i < 1000000; ++i){
        test_data.push_back(
            {std::bit_cast<fp_type>(rnd_egn()), std::bit_cast<fp_type>(rnd_egn())}
        );
    }

    std::fesetround(FE_TONEAREST);
    for(int i = 0; i < test_data.size(); ++i){
        add_unit->op1 = std::bit_cast<fp_bit>(test_data[i][0]);
        add_unit->op2 = std::bit_cast<fp_bit>(test_data[i][1]);
        add_unit->round_mode = 0;

        add_unit->eval();
        if(add_unit->result != std::bit_cast<fp_bit>(test_data[i][0] + test_data[i][1])){
            std::cout << "FE_TONEAREST: " << std::dec << i << " test" << std::endl;
            std::cout << "op1 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][0])
                << " : " << std::hexfloat << test_data[i][0] << std::endl;
            std::cout << "op2 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][1])
                << " : " << std::hexfloat << test_data[i][1] << std::endl;
            std::cout << "result = " << std::setfill('0') << std::right << std::hex << std::setw(8) << add_unit->result
                << " : " << std::hexfloat << std::bit_cast<fp_type>(add_unit->result) << std::endl;
            std::cout << "expect = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][0] + test_data[i][1])
                << " : " << std::hexfloat << test_data[i][0] + test_data[i][1] << std::endl;
        }
    }

    std::fesetround(FE_TOWARDZERO);
    for(int i = 0; i < test_data.size(); ++i){
        add_unit->op1 = std::bit_cast<fp_bit>(test_data[i][0]);
        add_unit->op2 = std::bit_cast<fp_bit>(test_data[i][1]);
        add_unit->round_mode = 1;

        add_unit->eval();
        if(add_unit->result != std::bit_cast<fp_bit>(test_data[i][0] + test_data[i][1])){
            std::cout << "FE_TOWARDZERO: " << std::dec << i << " test" << std::endl;
            std::cout << "op1 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][0])
                << " : " << std::hexfloat << test_data[i][0] << std::endl;
            std::cout << "op2 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][1])
                << " : " << std::hexfloat << test_data[i][1] << std::endl;
            std::cout << "result = " << std::setfill('0') << std::right << std::hex << std::setw(8) << add_unit->result
                << " : " << std::hexfloat << std::bit_cast<fp_type>(add_unit->result) << std::endl;
            std::cout << "expect = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][0] + test_data[i][1])
                << " : " << std::hexfloat << test_data[i][0] + test_data[i][1] << std::endl;
        }
    }
    std::fesetround(FE_DOWNWARD);
    for(int i = 0; i < test_data.size(); ++i){
        add_unit->op1 = std::bit_cast<fp_bit>(test_data[i][0]);
        add_unit->op2 = std::bit_cast<fp_bit>(test_data[i][1]);
        add_unit->round_mode = 2;

        add_unit->eval();
        if(add_unit->result != std::bit_cast<fp_bit>(test_data[i][0] + test_data[i][1])){
            std::cout << "FE_DOWNWARD: " << std::dec << i << " test" << std::endl;
            std::cout << "op1 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][0])
                << " : " << std::hexfloat << test_data[i][0] << std::endl;
            std::cout << "op2 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][1])
                << " : " << std::hexfloat << test_data[i][1] << std::endl;
            std::cout << "result = " << std::setfill('0') << std::right << std::hex << std::setw(8) << add_unit->result
                << " : " << std::hexfloat << std::bit_cast<fp_type>(add_unit->result) << std::endl;
            std::cout << "expect = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][0] + test_data[i][1])
                << " : " << std::hexfloat << test_data[i][0] + test_data[i][1] << std::endl;
        }
    }
    std::fesetround(FE_UPWARD);
    for(int i = 0; i < test_data.size(); ++i){
        add_unit->op1 = std::bit_cast<fp_bit>(test_data[i][0]);
        add_unit->op2 = std::bit_cast<fp_bit>(test_data[i][1]);
        add_unit->round_mode = 3;

        add_unit->eval();
        if(add_unit->result != std::bit_cast<fp_bit>(test_data[i][0] + test_data[i][1])){
            std::cout << "FE_UPWARD: " << std::dec << i << " test" << std::endl;
            std::cout << "op1 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][0])
                << " : " << std::hexfloat << test_data[i][0] << std::endl;
            std::cout << "op2 = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][1])
                << " : " << std::hexfloat << test_data[i][1] << std::endl;
            std::cout << "result = " << std::setfill('0') << std::right << std::hex << std::setw(8) << add_unit->result
                << " : " << std::hexfloat << std::bit_cast<fp_type>(add_unit->result) << std::endl;
            std::cout << "expect = " << std::setfill('0') << std::right << std::hex << std::setw(8) << std::bit_cast<fp_bit>(test_data[i][0] + test_data[i][1])
                << " : " << std::hexfloat << test_data[i][0] + test_data[i][1] << std::endl;
        }
    }


    add_unit->final();
}