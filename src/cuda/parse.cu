#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define SIT_SIZE 1000
#define NBR_COIN 162
#define NBR_MINUTES 881003
#define AMOUNT_TEST 500000
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
void printSituation(Situation *sit) {
    int index = sit->endIndex - SIT_SIZE;
    dprintf(1, "#SIT");
    for (int i = 0; i < SIT_SIZE; i++) {
        dprintf(1, " %lf", sit->minutes[index + i * 10]->data[3].open);
    }
    dprintf(1,"\n");
}

void clear(){
    dprintf(1, "#CLS\n");
}

int main() {
    clear();
    env.minutes = loadHistory(0, AMOUNT_TEST);
    dprintf(2,"ready");
    Situation sit;
    sit.minutes = env.minutes;
    for (int i=0 ; i < 400; i++){
        sit.endIndex = 2000 + (i * 400);
        printSituation(&sit);
        getchar();
        clear();
    }
    // int nbrIteration = NBR_MINUTES / NBR_BLOCK;
    // test<<<NBR_BLOCK, NBR_COIN>>>(env.minutes);
    // cudaDeviceSynchronize();
    return 0;
}