#include "trade.h"

static __global__ void applyTickBroker(Broker *brokers, int cursor) {
    int workerNbr = threadIdx.x + blockIdx.x * blockDim.x;
    Broker broker = brokers[workerNbr];
    broker.cursor = cursor;
    tickBroker(&broker);
    brokers[workerNbr] = broker;
}

// #define TIME_START 700000
#define TIME_START 0

static void bake(Data data) {
    int nbrThreads = 128;
    int nbrBlocks = 128;
    int nbrWorkers = nbrThreads * nbrBlocks;
    Broker *brokers;
    cudaMallocManaged(&brokers, sizeof(Broker) * nbrWorkers);
    for (int i = 0; i < nbrWorkers; i++) {
        brokers[i] = newBroker(data);
    }
    for (int i = TIME_START; i < data.nbrMinutes; i++) {
        if (i % 1000 == 0) {
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
        printf("BK: %-8.02lf FEE: %-8.02lf NB: %-5d\n", brokers[i].bank, brokers[i].fees, brokers[i].nbrBets);
        // printf("BK: %-12.2lf\n\n", brokers[i].bank);
        printSeed(&brokers[i].seed);
    }
}

int main() {
    srand(time(NULL));
    Data data = loadMinutes((char *)"../../data/bin/BTCUSDT");
    bake(data);
    return 0;
}