#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define SIT_SIZE 400

#define NBR_COIN 162
// #define NBR_BLOCK 128

#define NBR_COIN_CUDA 162
#define NBR_BLOCK 128

// #define NBR_COIN 1
// #define NBR_BLOCK 1

#define NBR_MINUTES 881003
#define AMOUNT_TEST 881003

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

/**
 * Launch the great machine comparator
 * Comparing pourcent source with all other minutes
 */
__global__ void bake(Minute **source, int sourceCoinId, int cursor,
                     Minute **minutes, int *scores) {
    int coinId = threadIdx.x;
    int minuteId = blockIdx.x;
    double score = 0;
    for (int i = 0; i < SIT_SIZE; i++) {
        if (minutes[cursor + minuteId + i]->data[coinId].open == -1) {
            scores[NBR_COIN_CUDA * minuteId + coinId] = -1;
            return;
        }
        double pourcent = minutes[cursor + minuteId + i]->data[coinId].open /
                          minutes[cursor + minuteId]->data[coinId].open * 100;
        score += fabs((source[i]->data[sourceCoinId].open) - (pourcent));
    }

    // printf("score : %12lf coinId: %4d minuteId : %3d test: %lf \n", score,
    //        coinId, minuteId + cursor,
    //        minutes[minuteId + cursor]->data[coinId].open);

    scores[NBR_COIN_CUDA * minuteId + coinId] = score;
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
 * Transform every value of a situation to a pourcentage from first value
 */
Minute **SituationToPourcent(int cursor) {
    Minute **result;
    cudaMallocManaged(&result, sizeof(void *) * SIT_SIZE);
    for (int i = 0; i < SIT_SIZE; i++) {
        cudaMallocManaged(&result[i], sizeof(Minute));
        result[i]->time = env.minutes[cursor + i]->time;
        for (int coinIndex = 0; coinIndex < NBR_COIN_CUDA; coinIndex++) {
            result[i]->data[coinIndex].close =
                env.minutes[cursor + i]->data[coinIndex].close /
                env.minutes[cursor]->data[coinIndex].close * 100;
            result[i]->data[coinIndex].high =
                env.minutes[cursor + i]->data[coinIndex].high /
                env.minutes[cursor]->data[coinIndex].high * 100;
            result[i]->data[coinIndex].low =
                env.minutes[cursor + i]->data[coinIndex].low /
                env.minutes[cursor]->data[coinIndex].low * 100;
            result[i]->data[coinIndex].open =
                env.minutes[cursor + i]->data[coinIndex].open /
                env.minutes[cursor]->data[coinIndex].open * 100;
            result[i]->data[coinIndex].volume =
                env.minutes[cursor + i]->data[coinIndex].volume /
                env.minutes[cursor + i]->data[coinIndex].volume * 100;
        }
    }
    return result;
}

/**
 * Export situation to external program
 */
void printSituation(int cursor, int coinId) {
    dprintf(1, "#SIT");
    for (int i = 0; i < SIT_SIZE; i++) {
        dprintf(1, " %lf", env.minutes[i + cursor]->data[coinId].open);
    }
    dprintf(1, "\n");
}

/**
 * Compare Given situation with all history
 */
int *bakeSituation(int cursor, int coinId) {
    int *scores;
    Minute **pourcent = SituationToPourcent(cursor);
    cursor += SIT_SIZE;  // avoiding compare source situation
    cudaMallocManaged(&scores, sizeof(int) * NBR_BLOCK * NBR_COIN);
    for (int bakeIndex = 0; cursor < 881003; bakeIndex++) {
        bake<<<NBR_BLOCK, NBR_COIN_CUDA>>>(pourcent, coinId, cursor,
                                           env.minutes, scores);
        cudaDeviceSynchronize();
        for (int i = 0; i < NBR_BLOCK * NBR_COIN_CUDA; i++) {
            if (scores[i] != -1) {
                int minuteId = i / NBR_COIN;
                int coinId = i % NBR_COIN;

                // dprintf(2,
                //         "score : %12d coinId: %4d minuteid : %3d test:
                //         %lf\n", scores[i], coinId, minuteId + cursor,
                //         env.minutes[minuteId + cursor]->data[coinId].open);

                if (scores[i] < 1300) {
                    printSituation(minuteId + cursor, coinId);
                    getchar();
                }
            }
        }
        cursor += NBR_BLOCK;
        if (cursor % 100 == 0) {
            dprintf(2, "cursor : %d\n", cursor);
        }
        // getchar();
    }
    return scores;
}

/**
 * Clear visual field
 */
void clear() { dprintf(1, "#CLS\n"); }

/**
 * do something with the score of a minute
 */
void onScore() {}

int main() {
    clear();
    env.minutes = loadHistory(0, AMOUNT_TEST);
    dprintf(2, "ready\n");
    int cursor = 0;
    printSituation(cursor, 3);
    getchar();
    int *scores = bakeSituation(cursor, 3);

    return 0;
}