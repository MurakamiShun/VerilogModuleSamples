#include <cmath>
#include <cstdio>
#include <cstdint>
#include <bit>
#include <stdfloat>
#include <cfenv>

void make_table_float(uint32_t precision){
    for(int t = 0; t < 4; ++t){
        int jj = 0;
        printf("const float pos_table%d[%d] = {\n", t, 1<<precision);
        for(float i = 0; i < ldexp(1.0f, 7-precision*t); i+=ldexp(1.0f, 7-precision*(t+1))){
            float exp_tmp = std::exp((double)i);
            if(std::isinf(exp_tmp)) printf("%15s, ", "FP_INFINITE");
            else printf("%15a, ", exp_tmp);
            jj = (jj+1)%4;
            if(jj == 0) putchar('\n');
        }
        puts("};\n");
    }

    for(int t = 0; t < 4; ++t){
        int jj = 0;
        printf("const float neg_table%d[%d] = {\n", t, 1<<precision);
        for(float i = 0; i < ldexp(1.0f, 7-precision*t); i+=ldexp(1.0f, 7-precision*(t+1))){
            printf("%15a, ", (float)std::exp(-(double)i));
            jj = (jj+1)%4;
            if(jj == 0) putchar('\n');
        }
        puts("};\n");
    }
}

void make_table_double(uint32_t precision){
    for(int t = 0; t < 8; ++t){
        int jj = 0;
        printf("const double pos_table%d[%d] = {\n", t, 1<<precision);
        for(double i = 0; i < ldexp(1.0f, 7-precision*t); i+=ldexp(1.0f, 7-precision*(t+1))){
            double exp_tmp = std::exp((std::float128_t)i);
            if(std::isinf(exp_tmp)) printf("%30s, ", "FP_INFINITE");
            else printf("%22a, ", exp_tmp);
            jj = (jj+1)%4;
            if(jj == 0) putchar('\n');
        }
        puts("};\n");
    }

    for(int t = 0; t < 8; ++t){
        int jj = 0;
        printf("const double neg_table%d[%d] = {\n", t, 1<<precision);
        for(double i = 0; i < ldexp(1.0f, 7-precision*t); i+=ldexp(1.0f, 7-precision*(t+1))){
            printf("%22a, ", (double)std::exp(-(std::float128_t)i));
            jj = (jj+1)%4;
            if(jj == 0) putchar('\n');
        }
        puts("};\n");
    }
}

int main(){
    make_table_float(7);
}


// float aprx_exp2(float x){
//     const uint32_t depth = 7;
//     if(x > 0x1p+7) return FP_INFINITE;
//     if(x < -0x1p+7) return FP_ZERO;
//     float tmp = x + 0x1p+7; // 128.0
//     uint32_t b = std::bit_cast<uint32_t>(tmp);
//     uint8_t idx_upper = (b >> (23-depth)) & ((1 << depth) - 1);
//     uint8_t idx_lower = (b >> (23-depth*2)) & ((1 << depth) - 1);

//     if(x < 0.0) return neg_upper_table[idx_upper] * neg_lower_table[idx_lower];
//     else        return pos_upper_table[idx_upper] * pos_lower_table[idx_lower];
// }
