#include "trade.h"

double randfrom(double min, double max) {
    double range = (max - min);
    double div = RAND_MAX / range;
    return min + (rand() / div);
}

__host__ __device__ void printMinute(Minute *minute) {
    printf("%ld OPEN: %-10.5lf HIGH: %-10.5lf LOW: %-10.5lf CLOSE: %-10.5lf\n",
           minute->time, minute->open, minute->high, minute->low,
           minute->close);
}

__global__ void applyTickBroker(Broker *brokers, int cursor) {
    int workerNbr = threadIdx.x + blockIdx.x * blockDim.x;

    Broker broker = brokers[workerNbr];
    broker.cursor = cursor;

    // printf("%d\n", broker.cursor);
    if (broker.minutes[broker.cursor].open > broker.seed.chien) {
        broker.bank += 1;
    }

    brokers[workerNbr] = broker;
}

Data loadMinutes(char *path) {
    Data data;
    int fd = open(path, O_RDONLY);
    struct stat buf;
    fstat(fd, &buf);
    off_t size = buf.st_size;
    cudaMallocManaged(&data.minutes, size);
    int rd = read(fd, data.minutes, size);
    if (rd <= 0) {
        printf("ERROR LOAD FILE\n");
        exit(0);
    }
    data.nbrMinutes = size / sizeof(Minute);
    return data;
}

Seed plantSeed() {
    Seed seed;
    seed.chien = randfrom(5, 14000);
    return seed;
}

Broker newBroker(Data data) {
    // Broker *broker = malloc(sizeof(Broker));
    Broker broker;
    broker.cursor = 700000;
    broker.minutes = data.minutes;
    broker.nbrMinutes = data.nbrMinutes;
    broker.seed = plantSeed();
    broker.bank = 0;
    return broker;
}

// #define TIME_START 700000
#define TIME_START 0

void bake(Data data) {
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
            printf("%d / 800000\n", i);
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
        printf("CH: %-12.2lf BK: %-12.2lf\n", brokers[i].seed.chien,
               brokers[i].bank);
    }
}

int main() {
    srand(time(NULL));
    Data data = loadMinutes((char *)"../../data/bin/BTCUSDT");
    bake(data);
    return 0;
}