#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define SIT_SIZE 200
#define NBR_COIN 162
#define NBR_MINUTES 881003
#define AMOUNT_TEST 100000
#define NBR_BLOCK 128

typedef struct {
    double open;
    double high;
    double low;
    double close;
    double volume;
} Data;

typedef struct {
    double time;
    Data data[NBR_COIN];
} Minute;

typedef struct {
    Minute **minutes;
    int endIndex;

} Situation;

typedef struct {
    Minute **minutes;
} Env;

Env env;

__global__ void test(Minute **minutes) {
    // int coinId = threadIdx.x;
    // int minuteId = blockDim.x;

    // printf("")

    // for (int i = 0; i < AMOUNT_TEST; i++) {
    //     printf("%lf - %lf\n", minutes[i]->data[3].open,
    //            minutes[i]->data[3].volume);
    // }
}

/**
 * Load history in RAM and VRAM
 */
Minute **loadHistory(int start, int amount) {
    int fd = open("../data/bin/full", O_RDONLY);
    Minute **minutes;
    cudaMallocManaged(&minutes, sizeof(void **) * amount);
    int i = -1;
    while (1) {
        i++;
        cudaMallocManaged(&minutes[i], sizeof(Minute));
        if (read(fd, minutes[i], sizeof(Minute)) < 1 || i == AMOUNT_TEST) break;
    }
    return minutes;
}

/**
 * Compare Given situation with all history
 */
void bakeSituation() {}

/**
 * Export situation to external program
 */
void printSituation() {}

int main() {
    // printf("CHIEN\n");
    // env.minutes = loadHistory(0, AMOUNT_TEST);
    // int nbrIteration = NBR_MINUTES / NBR_BLOCK;
    // test<<<NBR_BLOCK, NBR_COIN>>>(env.minutes);
    // cudaDeviceSynchronize();
    // printf("done\n");
    dprintf(1, "#LE CHIEN\n");
    dprintf(1, "#LE RIEN\n");
    dprintf(1, "#LE CASSOULET\n");
    getchar();
    dprintf(1, "#LE MOULINSARD\n");
    return 0;
}