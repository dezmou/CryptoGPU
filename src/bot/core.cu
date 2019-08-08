#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>

#define MAX_SCORE_NBR 2000
#define MAX_SIT_SIZE 4000

// typedef struct bestScore BestScore;

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
    double score;
    long minuteId;
    long coinId;
} Score;

typedef struct {
    // POTARD
    int nbrThreads;
    int nbrBlocks;
    int sitSize;
    int nbrScores;

    Coin* source;
    Score* scores;
    Score* bestScores;
    long nbrCoins;
    Minute* src;
    int cursorCoin;
    int cursorMinute;
    Coin** coins;
} Env;

Env* e;

__global__ void compare(Env* e) {
    // int x = threadIdx.x;
    // int y = blockIdx.x;
    int workerNbr = threadIdx.x * e->nbrThreads + blockIdx.x;
    int cursorMinute = workerNbr + e->cursorMinute;
    // printf("%lf\n", e->coins[e->cursorCoin]->minutes[cursorMinute].open);
    // for (int i = 0; i < e->sitSize; i++) {
    //     Minute* minute = &e->coins[e->cursorCoin]->minutes[cursorMinute + i];

    //     // printf("%lf\n", minute->open);
    //     if (i % 100 == 0) {
    //         e->scores[workerNbr].score = i;
    //     }
    // }
    // e->scores[workerNbr].score =
    // e->coins[e->cursorCoin]->minutes[cursorMinute].volume;

    // e->scores[workerNbr].score =
    //     e->coins[e->cursorCoin]->minutes[cursorMinute].volume;

    e->scores[workerNbr].score =
        e->coins[e->cursorCoin]->minutes[cursorMinute].volume;
}

// void initBestScores() {
//     BestScore* best = e->bests;
//     best->prev = NULL;
//     for (int iBest = 1; iBest < e->nbrScores; iBest++) {
//         best->next = &e->bests[iBest];
//         best->score = NULL;
//         e->bests[iBest].prev = best;
//         best = &e->bests[iBest];
//     }
//     best->next = NULL;
//     e->lastBest = best;
// }

void printBestScores() {
    for (int i = 0; i < 20; i++) {
        printf("%lf ", e->bestScores[i].score);
    }
    printf("\n");
}

extern "C" void bake(int sitSize, Minute* minutes) {
    e->sitSize = sitSize;
    memcpy(e->src, minutes, sizeof(Minute) * sitSize);
    for (int iBest = 0; iBest < e->nbrScores; iBest++) {
        e->bestScores[iBest].score = 999999999;
    }
    for (e->cursorCoin = 0; e->cursorCoin < e->nbrCoins; e->cursorCoin++) {
        printf("%s\n", e->coins[e->cursorCoin]->name);
        e->cursorMinute = 0;
        while (1) {
            compare<<<e->nbrBlocks, e->nbrThreads>>>(e);
            cudaDeviceSynchronize();
            cudaError_t error = cudaGetLastError();
            if (error != cudaSuccess) {
                printf("CUDA error: %s\n", cudaGetErrorString(error));
                exit(-1);
            }
            // printf("%d\n", bests->score->score);
            for (int iScore = 0; iScore < e->nbrBlocks * e->nbrThreads;
                 iScore++) {
                if (e->scores[iScore].score <
                    e->bestScores[e->nbrScores - 1].score) {
                    for (int iBest = 0; iBest < e->nbrScores; iBest++) {
                        if (e->scores[iScore].score <
                            e->bestScores[iBest].score) {
                            Score tmp = e->bestScores[iBest];
                            for (int iTmp = iBest + 1; iTmp < e->nbrScores;
                                 iTmp++) {
                                Score tmp2 = e->bestScores[iTmp];
                                e->bestScores[iTmp] = tmp;
                                tmp = tmp2;
                            }
                            e->bestScores[iBest] = e->scores[iScore];
                            break;
                        }
                        // if (e->bestScores[iBest - 1].score <
                        // e->scores[iScore].score) {

                        // }
                        // if (e->scores[iScore].score >
                        //     e->bestScores[iBest].score) {
                        //         Score *tmp = e->bestScores[iBest];
                        //         e->bestScores[iBest] =
                        // }
                    }
                }
                printBestScores();
                getchar();
                // BestScore* best = e->lastBest;
                // if (((e->lastBest->score == NULL) ||
                //      e->scores[iScore].score < e->lastBest->score->score)) {
                //     while (1) {
                //         if (e->scores[iScore].score > best->score->score){
                //             e->lastBest->score = e->scores[iScore].score;
                //             e->lastBest->next
                //             e->lastBest->prev = best->prev;
                //             // best->score->next =
                //             break;
                //         }
                //         if (!best->prev) {
                //             break;
                //         }
                //         best = best->prev;
                //     }
                // }

                // for (int iBest = 0; iBest > e->nbrScores; iBest++) {
                //     if (e->scores[iScore].score < bests->score->score) {
                //         e->bests[iBest];
                //         break;
                //     }
                //     bests->score->score
                // }

                // for (int iBest = e->nbrScores - 1; iBest >= 0; iBest--) {
                //     if (e->scores[iScore].score <
                //     e->bestScores[iBest].score){
                //         e->bestScores[iBest].score = e->scores[iScore].score;
                //         e->bestScores[iBest].minuteId =
                //         e->scores[iScore].minuteId;
                //         e->bestScores[iBest].coinId =
                //         e->scores[iScore].coinId;
                //         break;
                //     }
                // }
                // printf("%.10lf\n", e->scores[iScore].score);
            }
            // exit(0);
            e->cursorMinute += e->nbrBlocks * e->nbrThreads;
            if (e->coins[e->cursorCoin]->size - e->cursorMinute <=
                e->nbrBlocks * e->nbrThreads) {
                break;
            }
        }
    }
}

extern "C" void init(int size, char* files[]) {
    cudaMallocManaged(&e, sizeof(Env));
    cudaMallocManaged(&e->coins, sizeof(void*) * size);
    cudaMallocManaged(&e->source, sizeof(Coin));
    cudaMallocManaged(&e->src, sizeof(Minute) * MAX_SIT_SIZE);
    e->nbrCoins = 0;
    e->cursorCoin = 0;
    e->nbrThreads = 256;
    e->nbrBlocks = 256;
    e->nbrScores = 100;
    cudaMallocManaged(&e->scores, sizeof(Score) * e->nbrThreads * e->nbrBlocks);
    cudaMallocManaged(&e->bestScores, sizeof(Score) * MAX_SCORE_NBR);
    // cudaMallocManaged(&e->bests, sizeof(Score) * MAX_SCORE_NBR);
    // e->nbrThreads = 10;
    // e->nbrBlocks = 10;

    e->sitSize = 600;
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
        snprintf(e->coins[i]->name, strlen(files[i]) + 1, "%s", files[i]);

        // printf("%ld -  %s\n", e->coins[i]->minutes[0].time,
        // e->coins[i]->name);

        e->nbrCoins += 1;
        close(fd);
    }
}

// int main(int argc, char* argv[]) {
//     init(argc - 1, &argv[1]);
//     bake();
//     return 0;
// }