#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define CBLACK "\33[30m"
#define CRED "\33[31m"
#define CGREEN "\33[32m"
#define CWHITE "\33[37m"

#define SIT_SIZE 130
#define NBR_COIN 162
#define NBR_COIN_CUDA 162
#define NBR_BLOCK 1024
#define NBR_HIGH_SCORE 10
#define MIN_PRICE 0.000220
#define TIME_GUESS 10
#define COIN_TEST 98
#define AMOUNT_BET 100
#define MIN_POURCENT_GUESS 0.001
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
    int score;
    int minuteId;
    int coinId;
} Score;

typedef struct {
    Score highScores[NBR_HIGH_SCORE];
    double *guessed;

    /**Cuda memory */
    Minute **minutes;  // all history
    Minute **srcPourcent;
    int *scores;
} Env;

typedef struct {
    int cursor;
    int coinId;
} Situation;

Env env;

/**
 * Clear visual field
 */
void clear() { dprintf(1, "#CLS\n"); }

/**
 * Launch the great machine comparator
 * Comparing pourcent source with all other minutes
 */
__global__ void bake(Minute **source, int sourceCoinId, int cursor,
                     Minute **minutes, int *scores) {
    int coinId = threadIdx.x;
    int minuteId = blockIdx.x;
    double score = 0;
    if (minutes[cursor + minuteId]->data[coinId].open < MIN_PRICE) {
        scores[NBR_COIN_CUDA * minuteId + coinId] = -1;
        return;
    }
    for (int i = 0; i < SIT_SIZE; i++) {
        if (minutes[cursor + minuteId + i]->data[coinId].open == -1) {
            scores[NBR_COIN_CUDA * minuteId + coinId] = -1;
            return;
        }
        double pourcent = minutes[cursor + minuteId + i]->data[coinId].open /
                          minutes[cursor + minuteId]->data[coinId].open * 100;
        score +=
            fabs(fabs(source[i]->data[sourceCoinId].open) - fabs(pourcent));
    }

    // printf("score : %12lf coinId: %4d minuteId : %3d test: %lf \n", score,
    //        coinId, minuteId + cursor,
    //        minutes[minuteId + cursor]->data[coinId].open);
    scores[NBR_COIN_CUDA * minuteId + coinId] = score;
}

/**
 * Generate a random number
 */
int random_number(int min_num, int max_num) {
    int result = (rand() % (max_num - min_num)) + min_num;
    return result;
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
    for (int i = 0; i < SIT_SIZE; i++) {
        env.srcPourcent[i]->time = env.minutes[cursor + i]->time;
        for (int coinIndex = 0; coinIndex < NBR_COIN_CUDA; coinIndex++) {
            env.srcPourcent[i]->data[coinIndex].close =
                env.minutes[cursor + i]->data[coinIndex].close /
                env.minutes[cursor]->data[coinIndex].close * 100;
            env.srcPourcent[i]->data[coinIndex].high =
                env.minutes[cursor + i]->data[coinIndex].high /
                env.minutes[cursor]->data[coinIndex].high * 100;
            env.srcPourcent[i]->data[coinIndex].low =
                env.minutes[cursor + i]->data[coinIndex].low /
                env.minutes[cursor]->data[coinIndex].low * 100;
            env.srcPourcent[i]->data[coinIndex].open =
                env.minutes[cursor + i]->data[coinIndex].open /
                env.minutes[cursor]->data[coinIndex].open * 100;
            env.srcPourcent[i]->data[coinIndex].volume =
                env.minutes[cursor + i]->data[coinIndex].volume /
                env.minutes[cursor + i]->data[coinIndex].volume * 100;
        }
    }
    return env.srcPourcent;
}

/**
 * Export situation to external program
 */
void printSituation(int cursor, int coinId) {
    dprintf(2, "sit : %lf coinId : %d\n", env.minutes[cursor]->time, coinId);
    dprintf(1, "#SIT");
    for (int i = 0; i < SIT_SIZE * 2; i++) {
        dprintf(2, " %lf", env.minutes[i + cursor]->data[coinId].open);
        dprintf(1, " %lf", env.minutes[i + cursor]->data[coinId].open);
    }
    dprintf(1, "\n");
}

/**
 * Compare Given situation with all history
 */
void bakeSituation(int cursor, int baseCoinId) {
    // score
    int *scores = env.scores;
    int baseCursor = cursor;
    Minute **pourcent = SituationToPourcent(cursor);
    // cursor += SIT_SIZE;  // avoiding compare source situation
    cursor = 0;
    for (int hi = 0; hi < NBR_HIGH_SCORE; hi++) {
        env.highScores[hi].score = 99999999;
        env.highScores[hi].minuteId = 0;
        env.highScores[hi].coinId = 0;
    }
    for (int bakeIndex = 0; cursor < 870000; bakeIndex++) {
        bake<<<NBR_BLOCK, NBR_COIN_CUDA>>>(pourcent, baseCoinId, cursor,
                                           env.minutes, scores);
        cudaDeviceSynchronize();
        cudaError_t error = cudaGetLastError();
        if (error != cudaSuccess) {
            printf("CUDA error: %s\n", cudaGetErrorString(error));
            exit(-1);
        }
        for (int i = 0; i < NBR_BLOCK * NBR_COIN_CUDA; i++) {
            if (scores[i] != -1) {
                int minuteId = i / NBR_COIN;
                int coinId = i % NBR_COIN;
                if (abs((minuteId + cursor) - baseCursor) < (SIT_SIZE * 5)) {
                    continue;
                }

                // dprintf(2,
                //         "score : %12d coinId: %4d minuteid : %3d test:
                //         %lf\n", scores[i], coinId, minuteId + cursor,
                //         env.minutes[minuteId + cursor]->data[coinId].open);

                for (int highIndex = 0; highIndex < NBR_HIGH_SCORE;
                     highIndex++) {
                    if (scores[i] < env.highScores[highIndex].score) {
                        env.highScores[highIndex].score = scores[i];
                        env.highScores[highIndex].minuteId = minuteId + cursor;
                        env.highScores[highIndex].coinId = coinId;
                        i += NBR_COIN_CUDA * 50;
                        break;
                    }
                }
                // if (found) {
                //     break;
                // }
                // if (scores[i] < 47) {
                //     dprintf(2, "score : %d coinId : %d\n time :", scores[i],
                //             coinId);
                //     printSituation(minuteId + cursor, coinId);
                //     // getchar();
                //     break;
                // }
            }
        }
        cursor += NBR_BLOCK;
        // if (cursor % 100 == 0) {
        //     // dprintf(2, "cursor : %d\n", cursor);
        //     // getchar();
        // }
        // getchar();
    }
    // dprintf(2, "Done\n");
    // getchar();

    // clear();
    // for (int highIndex = 0; highIndex < NBR_HIGH_SCORE - 1; highIndex++) {
    //     getchar();
    //     printSituation(env.highScores[highIndex].minuteId,
    //                    env.highScores[highIndex].coinId);
    // }
}

/**
 * Return the guessed percentage of change from situation to TIME_GUESS
 */
double makeNextGuess() {
    double pred = 0;
    for (int highIndex = 0; highIndex < NBR_HIGH_SCORE; highIndex++) {
        // env.highScores[highIndex].minuteId + SIT_SIZE;
        // env.highScores[highIndex].coinId;
        double start =
            env.minutes[env.highScores[highIndex].minuteId + SIT_SIZE]
                ->data[env.highScores[highIndex].coinId]
                .open;
        double end = env.minutes[env.highScores[highIndex].minuteId + SIT_SIZE +
                                 TIME_GUESS]
                         ->data[env.highScores[highIndex].coinId]
                         .open;
        pred += 100 - (start / end * 100);
    }
    pred = pred / NBR_HIGH_SCORE;
    return pred;
}

/**
 * Get real next pourcent of given situation
 */
double getRealNext(int minuteId, int coinId) {
    double start = env.minutes[minuteId + SIT_SIZE]->data[coinId].open;
    double end =
        env.minutes[minuteId + SIT_SIZE + TIME_GUESS]->data[coinId].open;
    return 100 - (start / end * 100);
}

// /**
//  * do something with the score of a minute
//  */
// void onScore() {}

void initMem() {
    cudaMallocManaged(&env.srcPourcent, sizeof(void *) * SIT_SIZE);
    for (int i = 0; i < SIT_SIZE; i++) {
        cudaMallocManaged(&env.srcPourcent[i], sizeof(Minute));
    }
    cudaMallocManaged(&env.scores, sizeof(int) * NBR_BLOCK * NBR_COIN);
    env.guessed = (double *)malloc(sizeof(double) * SIT_SIZE);
}

Situation getRandomSituation() {
    Situation res;
    int last = 0;
    while (1) {
        res.cursor = random_number(200000, NBR_MINUTES - 1000);
        if (res.cursor == last) {
            printf("AH NON\n");
        }
        last = res.cursor;
        res.coinId = random_number(0, NBR_COIN_CUDA);
        if (env.minutes[res.cursor]->data[res.coinId].open != -1 &&
            env.minutes[res.cursor]->data[res.coinId].open > MIN_PRICE) {
            return res;
        }
        usleep(1000);
    }
}

int main() {
    srand(time(NULL));
    env.minutes = loadHistory(0, AMOUNT_TEST);
    initMem();
    int cur = 0;
    double bank = 1000;
    while (1) {
        // dprintf(2, "ready\n");
        // int cursor = 397100 + cur;
        // int cursor = random_number(397100, 500000);
        // clear();
        // printSituation(cursor, COIN_TEST);
        // dprintf(2, "READY\n");
        Situation sit = getRandomSituation();
        bakeSituation(sit.cursor, sit.coinId);
        double pred = makeNextGuess();
        double real = getRealNext(sit.cursor, sit.coinId);
        if (abs(real) > 5) {
            continue;
        }
        printf(
            "Time : %d | Cursor : %8d | CoinId : %4d | Pred : %10lf | Real : "
            "%10lf | BANK : %12lf |",
            (int)env.minutes[sit.cursor + SIT_SIZE]->time, sit.cursor,
            sit.coinId, pred, real, bank);
        if (abs(pred) > MIN_POURCENT_GUESS) {
            if (pred * real > 0) {
                bank += abs(real) * AMOUNT_BET;
                // printf("%sWON  %s ", CGREEN, CWHITE);
                bank += -(AMOUNT_BET * 0.002);
            } else {
                // printf("%sLOST %s ", CRED, CWHITE);
                bank -= abs(real) * AMOUNT_BET;
                bank += -(AMOUNT_BET * 0.002);
            }
        }
        printf("\n");
        fflush(stdout);
        // write(1,"\n", 1);
        // exit(0);
        // cur += SIT_SIZE / 2;
    }
    return 0;
}