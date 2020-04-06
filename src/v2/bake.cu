#include "trade.h"

static __global__ void applyTickBroker(Broker *brokers, int cursor) {
    int workerNbr = threadIdx.x + blockIdx.x * blockDim.x;
    brokers[workerNbr].cursor = cursor;
    tickBroker(&brokers[workerNbr]);
}

// #define TIME_START 700000
#define TIME_START 500

static void bake(Data data) {
    int nbrThreads = 64;
    int nbrBlocks = 127;
    int nbrWorkers = nbrThreads * nbrBlocks;
    Broker *brokers;
    cudaMallocManaged(&brokers, sizeof(Broker) * nbrWorkers);
    double maxBank = -999999999;
    double maxReg = 10;
 
    for (int chien = 0; chien < 100000; chien++) {
        for (int i = 0; i < nbrWorkers; i++) {
            brokers[i] = newBroker(data);
        }
        for (int i = TIME_START; i < data.nbrMinutes; i++) {
            if (i % 100000 == 0) {
                printf("%d / 800000  wokers : %d\n", i, nbrWorkers);
            }
            applyTickBroker<<<nbrBlocks, nbrThreads>>>(brokers, i);
        }
        cudaDeviceSynchronize();
        cudaError_t error = cudaGetLastError();
        if (error != cudaSuccess) {
            printf("CUDA error: %s\n", cudaGetErrorString(error));
            exit(-1);
        }
        for (int i = 0; i < nbrWorkers; i++) {
            // printf("BK: %-12.2lf\n\n", brokers[i].bank);
            if (brokers[i].bank > maxBank && brokers[i].reg >= maxReg && brokers[i].nbrBets > BAKE_MIN_BETS) {
                printSeed(&brokers[i].seed);
                printf("BK: %-8.02lf FEE: %-8.02lf NB: %-5d REG: %-5d\n\n",
                       brokers[i].bank, brokers[i].fees, brokers[i].nbrBets, brokers[i].reg);
                maxBank = brokers[i].bank;
                maxReg = brokers[i].reg;
            }
        }
    }
}

int main() {
    srand(time(NULL));
    Data data = loadMinutes((char *)"../../data/bin/BTCUSDT");
    bake(data);
    return 0;
}