#include <cmath>
#include <cstdio>
#include <cstdint>
#include <bit>
#include <chrono>

const float pos_table0[128] = {
         0x1p+0,   0x1.5bf0a8p+1,   0x1.d8e64cp+2,   0x1.415e5cp+4, 
  0x1.b4c902p+5,   0x1.28d38ap+7,   0x1.936dc6p+8,  0x1.122886p+10, 
 0x1.749ea8p+11,  0x1.fa7158p+12,  0x1.5829dcp+14,  0x1.d3c448p+15, 
 0x1.3de166p+17,  0x1.b00b5ap+18,  0x1.259ac4p+20,  0x1.8f0ccap+21, 
 0x1.0f2ebep+23,  0x1.709348p+24,   0x1.f4f22p+25,   0x1.546d9p+27, 
 0x1.ceb088p+28,   0x1.3a6e2p+30,  0x1.ab5adcp+31,  0x1.226af4p+33, 
 0x1.8ab7fcp+34,  0x1.0c3d3ap+36,  0x1.6c9326p+37,   0x1.ef823p+38, 
 0x1.50bba4p+40,  0x1.c9aae4p+41,   0x1.37047p+43,  0x1.a6b766p+44, 
 0x1.1f43fcp+46,  0x1.866f34p+47,  0x1.0953e2p+49,  0x1.689e22p+50, 
 0x1.ea215ap+51,  0x1.4d13fcp+53,  0x1.c4b334p+54,  0x1.33a43ep+56, 
 0x1.a220d4p+57,  0x1.1c25c8p+59,  0x1.823256p+60,  0x1.0672a4p+62, 
 0x1.64b41cp+63,  0x1.e4cf76p+64,  0x1.49767cp+66,  0x1.bfc952p+67, 
 0x1.304d6ap+69,  0x1.9d9702p+70,  0x1.19103ep+72,  0x1.7e013cp+73, 
 0x1.039966p+75,  0x1.60d4f6p+76,  0x1.df8c5ap+77,  0x1.45e308p+79, 
 0x1.baed16p+80,   0x1.2cffep+82,  0x1.9919cap+83,  0x1.160346p+85, 
 0x1.79dbcap+86,   0x1.00c81p+88,  0x1.5d0094p+89,  0x1.da57dep+90, 
 0x1.425982p+92,  0x1.b61e5cp+93,  0x1.29bb82p+95,  0x1.94a90ep+96, 
 0x1.12fec8p+98,  0x1.75c1dcp+99, 0x1.fbfd22p+100, 0x1.5936d4p+102, 
0x1.d531d8p+103, 0x1.3ed9d2p+105, 0x1.b15cfep+106, 0x1.268038p+108, 
0x1.9044a8p+109, 0x1.1002acp+111, 0x1.71b354p+112, 0x1.f6799ep+113, 
0x1.55779cp+115, 0x1.d01a22p+116, 0x1.3b63dap+118, 0x1.aca8d6p+119, 
0x1.234deap+121, 0x1.8bec76p+122, 0x1.0d0edap+124, 0x1.6db012p+125, 
0x1.f1056ep+126,     FP_INFINITE,     FP_INFINITE,     FP_INFINITE, 
    FP_INFINITE,     FP_INFINITE,     FP_INFINITE,     FP_INFINITE, 
    FP_INFINITE,     FP_INFINITE,     FP_INFINITE,     FP_INFINITE, 
    FP_INFINITE,     FP_INFINITE,     FP_INFINITE,     FP_INFINITE, 
    FP_INFINITE,     FP_INFINITE,     FP_INFINITE,     FP_INFINITE, 
    FP_INFINITE,     FP_INFINITE,     FP_INFINITE,     FP_INFINITE, 
    FP_INFINITE,     FP_INFINITE,     FP_INFINITE,     FP_INFINITE, 
    FP_INFINITE,     FP_INFINITE,     FP_INFINITE,     FP_INFINITE, 
    FP_INFINITE,     FP_INFINITE,     FP_INFINITE,     FP_INFINITE, 
    FP_INFINITE,     FP_INFINITE,     FP_INFINITE,     FP_INFINITE, 
};

const float pos_table1[128] = {
         0x1p+0,   0x1.020202p+0,   0x1.04080ap+0,   0x1.061224p+0, 
  0x1.082056p+0,   0x1.0a32a8p+0,   0x1.0c4924p+0,    0x1.0e63dp+0, 
  0x1.1082b6p+0,   0x1.12a5dep+0,    0x1.14cd5p+0,   0x1.16f916p+0, 
  0x1.192938p+0,   0x1.1b5dbep+0,    0x1.1d96bp+0,   0x1.1fd41ap+0, 
  0x1.221604p+0,   0x1.245c76p+0,   0x1.26a77ap+0,   0x1.28f718p+0, 
  0x1.2b4b58p+0,   0x1.2da448p+0,   0x1.3001ecp+0,   0x1.326452p+0, 
  0x1.34cb82p+0,   0x1.373784p+0,   0x1.39a862p+0,   0x1.3c1e28p+0, 
  0x1.3e98dep+0,    0x1.41189p+0,   0x1.439d44p+0,   0x1.462708p+0, 
  0x1.48b5e4p+0,   0x1.4b49e2p+0,   0x1.4de30ep+0,   0x1.508172p+0, 
  0x1.532518p+0,   0x1.55ce0ap+0,   0x1.587c54p+0,      0x1.5b3p+0, 
  0x1.5de918p+0,   0x1.60a7a8p+0,   0x1.636bbap+0,   0x1.66355ap+0, 
  0x1.690492p+0,    0x1.6bd97p+0,   0x1.6eb3fcp+0,   0x1.719444p+0, 
  0x1.747a52p+0,    0x1.77663p+0,   0x1.7a57eep+0,   0x1.7d4f94p+0, 
   0x1.804d3p+0,   0x1.8350cep+0,   0x1.865a78p+0,   0x1.896a3cp+0, 
  0x1.8c8024p+0,    0x1.8f9c4p+0,   0x1.92be9ap+0,   0x1.95e73ep+0, 
  0x1.99163ap+0,   0x1.9c4b9cp+0,   0x1.9f876ep+0,   0x1.a2c9bep+0, 
  0x1.a61298p+0,   0x1.a9620cp+0,   0x1.acb826p+0,   0x1.b014f2p+0, 
  0x1.b3787ep+0,   0x1.b6e2d8p+0,   0x1.ba540ep+0,   0x1.bdcc2cp+0, 
  0x1.c14b44p+0,   0x1.c4d15ep+0,   0x1.c85e8ep+0,   0x1.cbf2dep+0, 
  0x1.cf8e5ep+0,   0x1.d3311cp+0,   0x1.d6db26p+0,   0x1.da8c8ep+0, 
  0x1.de455ep+0,   0x1.e205a8p+0,   0x1.e5cd7ap+0,   0x1.e99ce2p+0, 
  0x1.ed73f2p+0,   0x1.f152b8p+0,   0x1.f53942p+0,   0x1.f927a2p+0, 
  0x1.fd1de6p+0,    0x1.008e1p+1,   0x1.02912ep+1,   0x1.049856p+1, 
  0x1.06a392p+1,   0x1.08b2e8p+1,    0x1.0ac66p+1,   0x1.0cde04p+1, 
  0x1.0ef9dcp+1,   0x1.1119eep+1,   0x1.133e46p+1,   0x1.1566eap+1, 
  0x1.1793e4p+1,   0x1.19c53cp+1,   0x1.1bfafcp+1,   0x1.1e352cp+1, 
  0x1.2073d4p+1,   0x1.22b6fep+1,   0x1.24feb2p+1,   0x1.274afcp+1, 
  0x1.299be2p+1,   0x1.2bf16ep+1,   0x1.2e4baap+1,    0x1.30aaap+1, 
  0x1.330e58p+1,   0x1.3576dcp+1,   0x1.37e438p+1,    0x1.3a567p+1, 
  0x1.3ccd94p+1,   0x1.3f49aap+1,   0x1.41cabep+1,   0x1.4450d8p+1, 
  0x1.46dc04p+1,   0x1.496c4cp+1,   0x1.4c01bap+1,   0x1.4e9c56p+1, 
  0x1.513c2ep+1,   0x1.53e14cp+1,   0x1.568bb8p+1,   0x1.593b7ep+1, 
};

const float pos_table2[128] = {
         0x1p+0,     0x1.0004p+0,     0x1.0008p+0,     0x1.000cp+0, 
     0x1.001p+0,     0x1.0014p+0,   0x1.001802p+0,   0x1.001c02p+0, 
  0x1.002002p+0,   0x1.002402p+0,   0x1.002804p+0,   0x1.002c04p+0, 
  0x1.003004p+0,   0x1.003406p+0,   0x1.003806p+0,   0x1.003c08p+0, 
  0x1.004008p+0,   0x1.00440ap+0,   0x1.00480ap+0,   0x1.004c0cp+0, 
  0x1.00500cp+0,   0x1.00540ep+0,    0x1.00581p+0,    0x1.005c1p+0, 
  0x1.006012p+0,   0x1.006414p+0,   0x1.006816p+0,   0x1.006c16p+0, 
  0x1.007018p+0,   0x1.00741ap+0,   0x1.00781cp+0,   0x1.007c1ep+0, 
   0x1.00802p+0,   0x1.008422p+0,   0x1.008824p+0,   0x1.008c26p+0, 
  0x1.009028p+0,   0x1.00942ap+0,   0x1.00982ep+0,    0x1.009c3p+0, 
  0x1.00a032p+0,   0x1.00a434p+0,   0x1.00a838p+0,   0x1.00ac3ap+0, 
  0x1.00b03cp+0,    0x1.00b44p+0,   0x1.00b842p+0,   0x1.00bc46p+0, 
  0x1.00c048p+0,   0x1.00c44cp+0,   0x1.00c84ep+0,   0x1.00cc52p+0, 
  0x1.00d054p+0,   0x1.00d458p+0,   0x1.00d85cp+0,   0x1.00dc5ep+0, 
  0x1.00e062p+0,   0x1.00e466p+0,   0x1.00e86ap+0,   0x1.00ec6cp+0, 
   0x1.00f07p+0,   0x1.00f474p+0,   0x1.00f878p+0,   0x1.00fc7cp+0, 
   0x1.01008p+0,   0x1.010484p+0,   0x1.010888p+0,   0x1.010c8cp+0, 
   0x1.01109p+0,   0x1.011494p+0,   0x1.01189ap+0,   0x1.011c9ep+0, 
  0x1.0120a2p+0,   0x1.0124a6p+0,   0x1.0128acp+0,    0x1.012cbp+0, 
  0x1.0130b4p+0,   0x1.0134bap+0,   0x1.0138bep+0,   0x1.013cc4p+0, 
  0x1.0140c8p+0,   0x1.0144cep+0,   0x1.0148d2p+0,   0x1.014cd8p+0, 
  0x1.0150dcp+0,   0x1.0154e2p+0,   0x1.0158e8p+0,   0x1.015cecp+0, 
  0x1.0160f2p+0,   0x1.0164f8p+0,   0x1.0168fep+0,   0x1.016d04p+0, 
  0x1.017108p+0,   0x1.01750ep+0,   0x1.017914p+0,   0x1.017d1ap+0, 
   0x1.01812p+0,   0x1.018526p+0,   0x1.01892cp+0,   0x1.018d32p+0, 
  0x1.01913ap+0,    0x1.01954p+0,   0x1.019946p+0,   0x1.019d4cp+0, 
  0x1.01a152p+0,   0x1.01a55ap+0,    0x1.01a96p+0,   0x1.01ad66p+0, 
  0x1.01b16ep+0,   0x1.01b574p+0,   0x1.01b97ap+0,   0x1.01bd82p+0, 
  0x1.01c188p+0,    0x1.01c59p+0,   0x1.01c998p+0,   0x1.01cd9ep+0, 
  0x1.01d1a6p+0,   0x1.01d5acp+0,   0x1.01d9b4p+0,   0x1.01ddbcp+0, 
  0x1.01e1c4p+0,   0x1.01e5cap+0,   0x1.01e9d2p+0,   0x1.01eddap+0, 
  0x1.01f1e2p+0,   0x1.01f5eap+0,   0x1.01f9f2p+0,   0x1.01fdfap+0, 
};

const float pos_table3[128] = {
         0x1p+0,   0x1.000008p+0,    0x1.00001p+0,   0x1.000018p+0, 
   0x1.00002p+0,   0x1.000028p+0,    0x1.00003p+0,   0x1.000038p+0, 
   0x1.00004p+0,   0x1.000048p+0,    0x1.00005p+0,   0x1.000058p+0, 
   0x1.00006p+0,   0x1.000068p+0,    0x1.00007p+0,   0x1.000078p+0, 
   0x1.00008p+0,   0x1.000088p+0,    0x1.00009p+0,   0x1.000098p+0, 
   0x1.0000ap+0,   0x1.0000a8p+0,    0x1.0000bp+0,   0x1.0000b8p+0, 
   0x1.0000cp+0,   0x1.0000c8p+0,    0x1.0000dp+0,   0x1.0000d8p+0, 
   0x1.0000ep+0,   0x1.0000e8p+0,    0x1.0000fp+0,   0x1.0000f8p+0, 
    0x1.0001p+0,   0x1.000108p+0,    0x1.00011p+0,   0x1.000118p+0, 
   0x1.00012p+0,   0x1.000128p+0,    0x1.00013p+0,   0x1.000138p+0, 
   0x1.00014p+0,   0x1.000148p+0,    0x1.00015p+0,   0x1.000158p+0, 
   0x1.00016p+0,   0x1.000168p+0,    0x1.00017p+0,   0x1.000178p+0, 
   0x1.00018p+0,   0x1.000188p+0,    0x1.00019p+0,   0x1.000198p+0, 
   0x1.0001ap+0,   0x1.0001a8p+0,    0x1.0001bp+0,   0x1.0001b8p+0, 
   0x1.0001cp+0,   0x1.0001c8p+0,    0x1.0001dp+0,   0x1.0001d8p+0, 
   0x1.0001ep+0,   0x1.0001e8p+0,    0x1.0001fp+0,   0x1.0001f8p+0, 
    0x1.0002p+0,   0x1.000208p+0,    0x1.00021p+0,   0x1.000218p+0, 
   0x1.00022p+0,   0x1.000228p+0,    0x1.00023p+0,   0x1.000238p+0, 
   0x1.00024p+0,   0x1.000248p+0,    0x1.00025p+0,   0x1.000258p+0, 
   0x1.00026p+0,   0x1.000268p+0,    0x1.00027p+0,   0x1.000278p+0, 
   0x1.00028p+0,   0x1.000288p+0,    0x1.00029p+0,   0x1.000298p+0, 
   0x1.0002ap+0,   0x1.0002a8p+0,    0x1.0002bp+0,   0x1.0002b8p+0, 
   0x1.0002cp+0,   0x1.0002c8p+0,    0x1.0002dp+0,   0x1.0002d8p+0, 
   0x1.0002ep+0,   0x1.0002e8p+0,    0x1.0002fp+0,   0x1.0002f8p+0, 
    0x1.0003p+0,   0x1.000308p+0,    0x1.00031p+0,   0x1.000318p+0, 
   0x1.00032p+0,   0x1.000328p+0,    0x1.00033p+0,   0x1.000338p+0, 
   0x1.00034p+0,   0x1.000348p+0,    0x1.00035p+0,   0x1.000358p+0, 
   0x1.00036p+0,   0x1.000368p+0,    0x1.00037p+0,   0x1.000378p+0, 
   0x1.00038p+0,   0x1.000388p+0,    0x1.00039p+0,   0x1.000398p+0, 
   0x1.0003ap+0,   0x1.0003a8p+0,    0x1.0003bp+0,   0x1.0003b8p+0, 
   0x1.0003cp+0,   0x1.0003c8p+0,    0x1.0003dp+0,   0x1.0003d8p+0, 
   0x1.0003ep+0,   0x1.0003e8p+0,    0x1.0003fp+0,   0x1.0003f8p+0, 
};

const float neg_table0[128] = {
         0x1p+0,   0x1.78b564p-2,   0x1.152aaap-3,   0x1.97db0cp-5, 
  0x1.2c155cp-6,   0x1.b993fep-8,    0x1.44e52p-9,  0x1.de16bap-11, 
  0x1.5fc21p-12,  0x1.02cf22p-13,  0x1.7cd79cp-15,  0x1.183542p-16, 
 0x1.9c54c4p-18,  0x1.2f6054p-19,   0x1.be6c7p-21,  0x1.4875cap-22, 
 0x1.e355bcp-24,  0x1.639e32p-25,  0x1.05a628p-26,   0x1.81057p-28, 
 0x1.1b4866p-29,  0x1.a0db0ep-31,  0x1.32b48cp-32,  0x1.c3527ep-34, 
 0x1.4c1078p-35,  0x1.e8a37ap-37,  0x1.67852ap-38,  0x1.08852ap-39, 
 0x1.853f02p-41,  0x1.1e642cp-42,  0x1.a56e0cp-44,  0x1.36121ep-45, 
  0x1.c8465p-47,  0x1.4fb548p-48,  0x1.ee001ep-50,  0x1.6b771ap-51, 
 0x1.0b6c3ap-52,  0x1.898472p-54,  0x1.2188aep-55,  0x1.aa0de4p-57, 
 0x1.397924p-58,  0x1.cd480ap-60,  0x1.536452p-61,  0x1.f36bd4p-63, 
 0x1.6f741ep-64,  0x1.0e5b74p-65,  0x1.8dd5e2p-67,  0x1.24b604p-68, 
 0x1.aebabap-70,  0x1.3ce9bap-71,  0x1.d257d6p-73,  0x1.571db8p-74, 
 0x1.f8e6c2p-76,  0x1.737c56p-77,  0x1.1152eap-78,  0x1.923372p-80, 
 0x1.27ec46p-81,  0x1.b374b4p-83,  0x1.4063f8p-84,  0x1.d775d8p-86, 
 0x1.5ae192p-87,  0x1.fe7116p-89,  0x1.778fe2p-90,  0x1.1452b8p-91, 
 0x1.969d48p-93,  0x1.2b2b8ep-94,  0x1.b83bf2p-96,  0x1.43e7fcp-97, 
 0x1.dca23cp-99,    0x1.5ebp-100, 0x1.02057ep-101, 0x1.7baee2p-103, 
 0x1.175afp-104, 0x1.9b1382p-106, 0x1.2e73f6p-107, 0x1.bd109ep-109, 
 0x1.4775ep-110, 0x1.e1dd28p-112,  0x1.62892p-113, 0x1.04da4ep-114, 
0x1.7fd974p-116, 0x1.1a6baep-117, 0x1.9f9644p-119, 0x1.31c596p-120, 
0x1.c1f2dap-122,  0x1.4b0dcp-123, 0x1.e726c4p-125, 0x1.666d0ep-126, 
 0x1.07b71p-127,  0x1.840fcp-129,   0x1.1d85p-130,  0x1.a4258p-132, 
  0x1.3521p-133,   0x1.c6e4p-135,    0x1.4ebp-136,    0x1.ec8p-138, 
   0x1.6a4p-139,    0x1.0a8p-140,     0x1.88p-142,      0x1.2p-143, 
     0x1.bp-145,      0x1.4p-146,        0x1p-147,        0x1p-149, 
         0x0p+0,          0x0p+0,          0x0p+0,          0x0p+0, 
         0x0p+0,          0x0p+0,          0x0p+0,          0x0p+0, 
         0x0p+0,          0x0p+0,          0x0p+0,          0x0p+0, 
         0x0p+0,          0x0p+0,          0x0p+0,          0x0p+0, 
         0x0p+0,          0x0p+0,          0x0p+0,          0x0p+0, 
         0x0p+0,          0x0p+0,          0x0p+0,          0x0p+0, 
};

const float neg_table1[128] = {
         0x1p+0,   0x1.fc03fep-1,   0x1.f80feap-1,   0x1.f423b8p-1, 
  0x1.f03f56p-1,   0x1.ec62b6p-1,   0x1.e88dc6p-1,   0x1.e4c07ap-1, 
   0x1.e0facp-1,   0x1.dd3c8ap-1,   0x1.d985c8p-1,   0x1.d5d66ep-1, 
  0x1.d22e6ap-1,    0x1.ce8dbp-1,   0x1.caf42ep-1,   0x1.c761dap-1, 
  0x1.c3d6a2p-1,   0x1.c0527ap-1,   0x1.bcd554p-1,    0x1.b95f2p-1, 
  0x1.b5efd2p-1,   0x1.b2875cp-1,    0x1.af25bp-1,   0x1.abcac2p-1, 
  0x1.a87682p-1,   0x1.a528e2p-1,   0x1.a1e1dap-1,   0x1.9ea158p-1, 
   0x1.9b675p-1,   0x1.9833b6p-1,   0x1.95067cp-1,   0x1.91df98p-1, 
  0x1.8ebefap-1,   0x1.8ba498p-1,   0x1.889064p-1,   0x1.858252p-1, 
  0x1.827a56p-1,   0x1.7f7864p-1,    0x1.7c7c7p-1,   0x1.79866ep-1, 
  0x1.769652p-1,   0x1.73ac12p-1,   0x1.70c79ep-1,    0x1.6de8fp-1, 
  0x1.6b0ff8p-1,   0x1.683cacp-1,     0x1.656fp-1,   0x1.62a6ecp-1, 
  0x1.5fe462p-1,   0x1.5d2756p-1,    0x1.5a6fcp-1,   0x1.57bd94p-1, 
  0x1.5510c6p-1,   0x1.52694ep-1,   0x1.4fc71ep-1,   0x1.4d2a2ep-1, 
  0x1.4a9272p-1,    0x1.47ffep-1,   0x1.45726ep-1,   0x1.42ea12p-1, 
  0x1.4066c2p-1,   0x1.3de874p-1,   0x1.3b6f1ep-1,   0x1.38fab4p-1, 
   0x1.368b3p-1,   0x1.342084p-1,   0x1.31baaap-1,   0x1.2f5998p-1, 
   0x1.2cfd4p-1,   0x1.2aa59ep-1,   0x1.2852a8p-1,   0x1.260452p-1, 
  0x1.23ba94p-1,   0x1.217564p-1,   0x1.1f34bap-1,   0x1.1cf88ep-1, 
  0x1.1ac0d6p-1,   0x1.188d88p-1,   0x1.165e9cp-1,   0x1.14340ap-1, 
  0x1.120dcap-1,    0x1.0febdp-1,   0x1.0dce18p-1,   0x1.0bb496p-1, 
  0x1.099f42p-1,   0x1.078e16p-1,   0x1.058106p-1,   0x1.03780ep-1, 
  0x1.017324p-1,   0x1.fee47ep-2,    0x1.faeabp-2,   0x1.f6f8cep-2, 
  0x1.f30ec8p-2,   0x1.ef2c8ep-2,    0x1.eb521p-2,    0x1.e77f4p-2, 
  0x1.e3b40ep-2,   0x1.dff06cp-2,   0x1.dc3448p-2,   0x1.d87f96p-2, 
  0x1.d4d244p-2,   0x1.d12c48p-2,   0x1.cd8d8ep-2,   0x1.c9f60cp-2, 
  0x1.c665b2p-2,    0x1.c2dc7p-2,   0x1.bf5a3cp-2,   0x1.bbdf04p-2, 
  0x1.b86abap-2,   0x1.b4fd54p-2,    0x1.b196cp-2,   0x1.ae36f4p-2, 
   0x1.aaddep-2,   0x1.a78b78p-2,   0x1.a43faep-2,   0x1.a0fa76p-2, 
   0x1.9dbbcp-2,   0x1.9a8382p-2,   0x1.9751aep-2,   0x1.942636p-2, 
   0x1.91011p-2,   0x1.8de22ep-2,   0x1.8ac984p-2,   0x1.87b704p-2, 
  0x1.84aaa4p-2,   0x1.81a456p-2,   0x1.7ea40ep-2,   0x1.7ba9c2p-2, 
};

const float neg_table2[128] = {
         0x1p+0,     0x1.fff8p-1,      0x1.fffp-1,     0x1.ffe8p-1, 
     0x1.ffep-1,   0x1.ffd802p-1,   0x1.ffd002p-1,   0x1.ffc804p-1, 
  0x1.ffc004p-1,   0x1.ffb806p-1,   0x1.ffb006p-1,   0x1.ffa808p-1, 
  0x1.ffa008p-1,   0x1.ff980ap-1,   0x1.ff900cp-1,   0x1.ff880ep-1, 
   0x1.ff801p-1,   0x1.ff7812p-1,   0x1.ff7014p-1,   0x1.ff6816p-1, 
  0x1.ff6018p-1,   0x1.ff581cp-1,   0x1.ff501ep-1,   0x1.ff4822p-1, 
  0x1.ff4024p-1,   0x1.ff3828p-1,   0x1.ff302ap-1,   0x1.ff282ep-1, 
   0x1.ff203p-1,   0x1.ff1834p-1,   0x1.ff1038p-1,   0x1.ff083cp-1, 
   0x1.ff004p-1,   0x1.fef844p-1,   0x1.fef048p-1,   0x1.fee84cp-1, 
   0x1.fee05p-1,   0x1.fed856p-1,   0x1.fed05ap-1,   0x1.fec85ep-1, 
  0x1.fec064p-1,   0x1.feb868p-1,   0x1.feb06ep-1,   0x1.fea874p-1, 
  0x1.fea078p-1,   0x1.fe987ep-1,   0x1.fe9084p-1,   0x1.fe888ap-1, 
   0x1.fe809p-1,   0x1.fe7896p-1,   0x1.fe709cp-1,   0x1.fe68a2p-1, 
  0x1.fe60a8p-1,    0x1.fe58bp-1,   0x1.fe50b6p-1,   0x1.fe48bcp-1, 
  0x1.fe40c4p-1,   0x1.fe38cap-1,   0x1.fe30d2p-1,   0x1.fe28dap-1, 
   0x1.fe20ep-1,   0x1.fe18e8p-1,    0x1.fe10fp-1,   0x1.fe08f8p-1, 
    0x1.fe01p-1,   0x1.fdf908p-1,    0x1.fdf11p-1,   0x1.fde918p-1, 
   0x1.fde12p-1,   0x1.fdd92ap-1,   0x1.fdd132p-1,   0x1.fdc93ap-1, 
  0x1.fdc144p-1,   0x1.fdb94cp-1,   0x1.fdb156p-1,    0x1.fda96p-1, 
  0x1.fda168p-1,   0x1.fd9972p-1,   0x1.fd917cp-1,   0x1.fd8986p-1, 
   0x1.fd819p-1,   0x1.fd799ap-1,   0x1.fd71a4p-1,   0x1.fd69aep-1, 
  0x1.fd61b8p-1,   0x1.fd59c2p-1,   0x1.fd51cep-1,   0x1.fd49d8p-1, 
  0x1.fd41e4p-1,   0x1.fd39eep-1,   0x1.fd31fap-1,   0x1.fd2a04p-1, 
   0x1.fd221p-1,   0x1.fd1a1cp-1,   0x1.fd1228p-1,   0x1.fd0a32p-1, 
  0x1.fd023ep-1,   0x1.fcfa4ap-1,   0x1.fcf258p-1,   0x1.fcea64p-1, 
   0x1.fce27p-1,   0x1.fcda7cp-1,   0x1.fcd288p-1,   0x1.fcca96p-1, 
  0x1.fcc2a2p-1,    0x1.fcbabp-1,   0x1.fcb2bcp-1,   0x1.fcaacap-1, 
  0x1.fca2d8p-1,   0x1.fc9ae4p-1,   0x1.fc92f2p-1,     0x1.fc8bp-1, 
  0x1.fc830ep-1,   0x1.fc7b1cp-1,   0x1.fc732ap-1,   0x1.fc6b38p-1, 
  0x1.fc6348p-1,   0x1.fc5b56p-1,   0x1.fc5364p-1,   0x1.fc4b72p-1, 
  0x1.fc4382p-1,    0x1.fc3b9p-1,    0x1.fc33ap-1,    0x1.fc2bbp-1, 
  0x1.fc23bep-1,   0x1.fc1bcep-1,   0x1.fc13dep-1,   0x1.fc0beep-1, 
};

const float neg_table3[128] = {
         0x1p+0,    0x1.fffffp-1,    0x1.ffffep-1,    0x1.ffffdp-1, 
   0x1.ffffcp-1,    0x1.ffffbp-1,    0x1.ffffap-1,    0x1.ffff9p-1, 
   0x1.ffff8p-1,    0x1.ffff7p-1,    0x1.ffff6p-1,    0x1.ffff5p-1, 
   0x1.ffff4p-1,    0x1.ffff3p-1,    0x1.ffff2p-1,    0x1.ffff1p-1, 
    0x1.ffffp-1,    0x1.fffefp-1,    0x1.fffeep-1,    0x1.fffedp-1, 
   0x1.fffecp-1,    0x1.fffebp-1,    0x1.fffeap-1,    0x1.fffe9p-1, 
   0x1.fffe8p-1,    0x1.fffe7p-1,    0x1.fffe6p-1,    0x1.fffe5p-1, 
   0x1.fffe4p-1,    0x1.fffe3p-1,    0x1.fffe2p-1,    0x1.fffe1p-1, 
    0x1.fffep-1,    0x1.fffdfp-1,    0x1.fffdep-1,    0x1.fffddp-1, 
   0x1.fffdcp-1,    0x1.fffdbp-1,    0x1.fffdap-1,    0x1.fffd9p-1, 
   0x1.fffd8p-1,    0x1.fffd7p-1,    0x1.fffd6p-1,    0x1.fffd5p-1, 
   0x1.fffd4p-1,    0x1.fffd3p-1,    0x1.fffd2p-1,    0x1.fffd1p-1, 
    0x1.fffdp-1,    0x1.fffcfp-1,    0x1.fffcep-1,    0x1.fffcdp-1, 
   0x1.fffccp-1,    0x1.fffcbp-1,    0x1.fffcap-1,    0x1.fffc9p-1, 
   0x1.fffc8p-1,    0x1.fffc7p-1,    0x1.fffc6p-1,    0x1.fffc5p-1, 
   0x1.fffc4p-1,    0x1.fffc3p-1,    0x1.fffc2p-1,    0x1.fffc1p-1, 
    0x1.fffcp-1,    0x1.fffbfp-1,    0x1.fffbep-1,    0x1.fffbdp-1, 
   0x1.fffbcp-1,    0x1.fffbbp-1,    0x1.fffbap-1,    0x1.fffb9p-1, 
   0x1.fffb8p-1,    0x1.fffb7p-1,    0x1.fffb6p-1,    0x1.fffb5p-1, 
   0x1.fffb4p-1,    0x1.fffb3p-1,    0x1.fffb2p-1,    0x1.fffb1p-1, 
    0x1.fffbp-1,    0x1.fffafp-1,    0x1.fffaep-1,    0x1.fffadp-1, 
   0x1.fffacp-1,    0x1.fffabp-1,    0x1.fffaap-1,    0x1.fffa9p-1, 
   0x1.fffa8p-1,    0x1.fffa7p-1,    0x1.fffa6p-1,    0x1.fffa5p-1, 
   0x1.fffa4p-1,    0x1.fffa3p-1,    0x1.fffa2p-1,    0x1.fffa1p-1, 
    0x1.fffap-1,    0x1.fff9fp-1,    0x1.fff9ep-1,    0x1.fff9dp-1, 
   0x1.fff9cp-1,    0x1.fff9bp-1,    0x1.fff9ap-1,    0x1.fff99p-1, 
   0x1.fff98p-1,    0x1.fff97p-1,    0x1.fff96p-1,    0x1.fff95p-1, 
   0x1.fff94p-1,    0x1.fff93p-1,    0x1.fff92p-1,    0x1.fff91p-1, 
    0x1.fff9p-1,    0x1.fff8fp-1,    0x1.fff8ep-1,    0x1.fff8dp-1, 
   0x1.fff8cp-1,    0x1.fff8bp-1,    0x1.fff8ap-1,    0x1.fff89p-1, 
   0x1.fff88p-1,    0x1.fff87p-1,    0x1.fff86p-1,    0x1.fff85p-1, 
   0x1.fff84p-1,    0x1.fff83p-1,    0x1.fff82p-1,    0x1.fff81p-1, 
};




float aprx_exp_float(float x){
    const uint32_t precision = 7;
    if(x > 0x1p+7) return FP_INFINITE;
    if(x < -0x1p+7) return FP_ZERO;
    float tmp = (float)x + 0x1p+7; // 128.0
    uint32_t b = std::bit_cast<uint32_t>(tmp);
    uint8_t idx0 = (b >> (23-precision)) & ((1 << precision) - 1);
    uint8_t idx1 = (b >> (23-precision*2)) & ((1 << precision) - 1);
    uint8_t idx2 = (b >> (23-precision*3)) & ((1 << precision) - 1);

    if(x < 0.0){
        return neg_table0[idx0] * neg_table1[idx1] * neg_table2[idx2];
    }
    else{
        return pos_table0[idx0] * pos_table1[idx1] * pos_table2[idx2];
    }
}

// double aprx_exp_double(double x){
//     const uint32_t precision = 5;
//     if(x > 0x1p+7) return FP_INFINITE;
//     if(x < -0x1p+7) return FP_ZERO;
//     double tmp = (double)x + 0x1p+7; // 128.0
//     uint64_t b = std::bit_cast<uint64_t>(tmp);
//     uint8_t idx0 = (b >> (52-precision)) & ((1 << precision) - 1);
//     uint8_t idx1 = (b >> (52-precision*2)) & ((1 << precision) - 1);
//     uint8_t idx2 = (b >> (52-precision*3)) & ((1 << precision) - 1);
//     uint8_t idx3 = (b >> (52-precision*4)) & ((1 << precision) - 1);
//     uint8_t idx4 = (b >> (52-precision*5)) & ((1 << precision) - 1);
//     uint8_t idx5 = (b >> (52-precision*6)) & ((1 << precision) - 1);
//     uint8_t idx6 = (b >> (52-precision*7)) & ((1 << precision) - 1);
//     uint8_t idx7 = (b >> (52-precision*8)) & ((1 << precision) - 1);

//     if(x < 0.0){
//         return neg_table0[idx0] * neg_table1[idx1] * neg_table2[idx2] * neg_table3[idx3]
//             * neg_table4[idx4] * neg_table5[idx5] * neg_table6[idx6] * neg_table7[idx7];
//     }
//     else{
//         return pos_table0[idx0] * pos_table1[idx1] * pos_table2[idx2] * pos_table3[idx3]
//             * pos_table4[idx4] * pos_table5[idx5] * pos_table6[idx6] * pos_table7[idx7];
//     }
// }


int32_t err_rate(float x, float truth){
    return std::abs(std::bit_cast<int32_t>(x) - std::bit_cast<int32_t>(truth));
}

int main(){
    int i = 0;
    double total = 0;
    auto start = std::chrono::system_clock::now();
    for(double x = 0x1.0p-8; x < 90; x*=0x1.001p0){
        //total += std::exp((float)x);
        double exp_x = std::exp((double)x);
        ++i;
        printf("%4d\n", err_rate(aprx_exp_float(x), exp_x));
    }
    auto end = std::chrono::system_clock::now();
    printf("%ld us\n", std::chrono::duration_cast<std::chrono::microseconds>(end - start).count());
    printf("%d %a\n", i, total);
}
