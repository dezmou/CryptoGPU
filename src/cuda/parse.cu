#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define SIT_SIZE 1000

#define NBR_COIN 162
#define NBR_BLOCK 128

// #define NBR_COIN 1
// #define NBR_BLOCK 1

#define NBR_MINUTES 881003
#define AMOUNT_TEST 1000

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
} Env;

Env env;

__global__ void bake(int cursor, Minute **minutes, int *scores) {
    int coinId = threadIdx.x;
    int minuteId = blockIdx.x;

    // for (int i=0; i < SIT_SIZE; i++){
    //     printf("%lf\n", minutes[minuteId + i]->data[3].open);
    // }

    // for (int i = 0; i < AMOUNT_TEST; i++) {
    //     printf("%lf - %lf\n", minutes[i]->data[3].open,
    //            minutes[i]->data[3].volume);
    // }

    scores[ NBR_COIN * minuteId + coinId] = 69;
}

/**
 * Load history in RAM and VRAM
 */
Minute **loadHistory(int start, int amount) {
    int fd = open("../data/bin/full", O_RDONLY);
    Minute **minutes;
    cudaMallocManaged(&minutes, sizeof(void *) * amount);
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
int *bakeSituation(int cursor) {
    int *scores;
    cudaMallocManaged(&scores, sizeof(int) * NBR_BLOCK * NBR_COIN);
    // int nbrIteration = NBR_MINUTES / NBR_BLOCK;
    bake<<<NBR_BLOCK, NBR_COIN>>>(cursor, env.minutes, scores);
    cudaDeviceSynchronize();
    return scores;
}

/**
 * Export situation to external program
 */
void printSituation(int cursor) {
    dprintf(1, "#SIT");
    for (int i = 0; i < SIT_SIZE; i++) {
        dprintf(1, " %lf", env.minutes[cursor + i]->data[3].open);
    }
    dprintf(1, "\n");
}

/**
 * Clear visual field
 */
void clear() { dprintf(1, "#CLS\n"); }

int main() {
    // clear();
    env.minutes = loadHistory(0, AMOUNT_TEST);
    dprintf(2, "ready\n");
    int cursor = 0;
    int *scores = bakeSituation(cursor);

    for (int i = 0; i < NBR_BLOCK * NBR_COIN; i++) {
        dprintf(2, "%d ", scores[i]);
    }
    dprintf(2,"\n");


    // for (int i = 0; i < 400; i++) {
    //     clear();
    //     printSituation(cursor);
    //     cursor += 5000;
    //     getchar();
    // }

    return 0;
}