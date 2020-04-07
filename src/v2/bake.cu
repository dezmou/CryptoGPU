#include "trade.h"

static __global__ void applyTickBroker(Broker *brokers, int cursor) {
    int workerNbr = threadIdx.x + blockIdx.x * blockDim.x;
    brokers[workerNbr].cursor = cursor;
    tickBroker(&brokers[workerNbr]);
}

// #define TIME_START 700000
#define BAKE_MIN_BETS 500

long long current_timestamp() {
    struct timeval te;
    gettimeofday(&te, NULL);  // get current time
    long long milliseconds =
        te.tv_sec * 1000LL + te.tv_usec / 1000;  // calculate milliseconds
    return milliseconds;
}

static void bake(Data data) {
    int nbrThreads = 128;
    int nbrBlocks = 64;
    int nbrWorkers = nbrThreads * nbrBlocks;
    Broker *brokers;
    cudaMallocManaged(&brokers, sizeof(Broker) * nbrWorkers);
    double maxBank = -999999999;
    double maxReg = 8;
    int totalMinutes = 0;
    for (int chien = 0; chien < 100000; chien++) {
        for (int i = 0; i < nbrWorkers; i++) {
            brokers[i] = newBroker(data);
        }
        long long timeStart = current_timestamp();
        for (int i = TIME_START; i < data.nbrMinutes; i++) {
            totalMinutes += 1;
            if (totalMinutes == 50000) {
                printf("perf: %lf\n",
                       (double)nbrWorkers /
                           (double)(current_timestamp() - timeStart));
            }
            // if (i % 100000 == 0) {
            //     printf("%d / 1300000  wokers : %d\n", i, nbrWorkers);
            // }
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
            if (brokers[i].bank > (maxBank * 0.95) && brokers[i].reg >= 10 &&
                brokers[i].nbrBets > BAKE_MIN_BETS) {
                // if (brokers[i].bank > 0 && brokers[i].reg >= maxReg &&
                // brokers[i].nbrBets > BAKE_MIN_BETS) {
                printSeed(&brokers[i].seed);
                printf("BK: %-8.02lf FEE: %-8.02lf NB: %-5d REG: %-5d\n\n",
                       brokers[i].bank, brokers[i].fees, brokers[i].nbrBets,
                       brokers[i].reg);
                maxBank = brokers[i].bank;
                maxReg = brokers[i].reg;
            }
        }
        // printf("DONE\n");
    }
}

int main() {
    srand(time(NULL));
    Data data = loadMinutes((char *)"./BTCUSDT");
    bake(data);
    return 0;
}