#include <fcntl.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>
#include <cuda_runtime.h>
// maybe you need also helpers
// #include <helper_cuda.h>
// #include <helper_functions.h> // helper utility functions 

#define KNRM "\x1B[0m"
#define KRED "\x1B[31m"
#define KGRN "\x1B[32m"
#define KYEL "\x1B[33m"
#define KBLU "\x1B[34m"
#define KMAG "\x1B[35m"
#define KCYN "\x1B[36m"
#define KWHT "\x1B[37m"

#define NO_BET 0
#define BUY 1
#define SELL 2

#ifndef BUILD
    #define __host__
    #define __device__
    #define __global__
    #define blockDim.x 0
    #define threadIdx.x 0
    #define blockIdx 0
#endif

typedef struct {
    long time;
    double open;
    double high;
    double low;
    double close;
    double volume;
} Minute;

typedef struct {
    int nbrMinutes;
    Minute *minutes;
} Data;

typedef struct {
    double chien;
    double lapin;
} Seed;

typedef struct {
    int type;
    double bank;
    double totalFee;
    double closeUp;
    double closeDown;
} Bet;

typedef struct {
    long cursor;
    Minute *minutes;
    int nbrMinutes;
    Seed seed;
    double bank;
    Bet bet;
} Broker;


Broker newBroker(Data data);
double randfrom(double min, double max);
Seed plantSeed();
Data loadMinutes(char *path);
void printSeed(Seed *seed);
Seed scanSeed(char *seedStr);
__host__ __device__ void printMinute(Minute *minute);
__host__ __device__ void tickBroker(Broker *broker);
__host__ __device__ Bet analyse(Minute *minute, Seed *seed);
