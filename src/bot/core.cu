#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>

typedef struct {
    long time;
    double open;
    double high;
    double low;
    double close;
    double volume;
} Minute;

typedef struct {
    char name[128];
    long size;
    Minute* minutes;
} Coin;

typedef struct {
    int score;
    int minuteId;
    int coinId;
} Score;

typedef struct {
    // POTARD
    int nbrThreads;
    int nbrBlocks;
    int sitSize;
    
    Coin *source;
    long nbrCoins;
    int cursorCoin;
    int cursorMinute;
    Coin** coins;
} Env;

Env* e;

__global__ void compare(Env* e) {
    // int x = threadIdx.x;
    // int y = blockIdx.x;
    int cursorMinute = threadIdx.x * e->nbrThreads + blockIdx.x + e->cursorMinute;
}

void init(int size, char* files[]) {
    cudaMallocManaged(&e->coins, sizeof(void*) * size);
    cudaMallocManaged(&e->source, sizeof(Coin));
    e->nbrCoins = 0;
    e->cursorCoin = 0;
    e->nbrThreads = 128;
    e->nbrBlocks = 128;

    // e->nbrThreads = 10;
    // e->nbrBlocks = 10;

    e->sitSize = 400;
    char path[128];
    for (int i = 0; i < size; i++) {
        snprintf(path, sizeof(path), "./data/%s", files[i]);
        int fd = open(path, O_RDONLY);
        cudaMallocManaged(&e->coins[i], sizeof(Coin));
        struct stat buf;
        fstat(fd, &buf);
        off_t sizeAll = buf.st_size;
        cudaMallocManaged(&e->coins[i]->minutes, sizeAll);
        int res = read(fd, e->coins[i]->minutes, sizeAll);
        e->coins[i]->size = sizeAll / sizeof(Minute);
        snprintf(e->coins[i]->name, strlen(files[i]), "%s", files[i]);
        // printf("%ld %s\n", e->coins[i]->minutes[0].time, e->coins[i]->name);
        e->nbrCoins += 1;
        close(fd);
    }
}

void bake() {
    // cudaDeviceSynchronize();
    cudaError_t error = cudaGetLastError();
    if (error != cudaSuccess) {
        printf("CUDA error: %s\n", cudaGetErrorString(error));
        exit(-1);
    }
    for (e->cursorCoin; e->cursorCoin < e->nbrCoins; e->cursorCoin++) {
        printf("%s\n", e->coins[e->cursorCoin]->name);
        e->cursorMinute = 0;
        while (1) {
            e->cursorMinute += e->nbrBlocks * e->nbrThreads;
            compare<<<e->nbrBlocks, e->nbrThreads>>>(e);
            cudaDeviceSynchronize();
            if (e->cursorMinute >= e->coins[e->cursorCoin]->size - e->sitSize){
                break;
            }
        }
    }
}

int main(int argc, char* argv[]) {
    cudaMallocManaged(&e, sizeof(Env));
    init(argc - 1, &argv[1]);
    bake();
    return 0;
}