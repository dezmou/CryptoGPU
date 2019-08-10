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
    char* result;
} Env;

Env* e;

#define STEP_SIZE 20

__global__ void compare(Env* e) {
    int workerNbr = threadIdx.x * e->nbrThreads + blockIdx.x;
    int cursorMinute = workerNbr + e->cursorMinute;
    double score = 0;
    int step = 0;
    for (int i = 1; i < e->sitSize; i++) {
        double destPourcent =
            e->coins[e->cursorCoin]->minutes[cursorMinute + step].open /
            e->coins[e->cursorCoin]->minutes[cursorMinute + i].open * 1000;
        double srcPourcent = e->src[0 + step].open / e->src[i].open * 1000;
        score += abs(destPourcent - srcPourcent);
        if (step > STEP_SIZE){
            step += 1;
        }
            
    }
    e->scores[workerNbr].score = score;
    e->scores[workerNbr].minuteId = cursorMinute;
    e->scores[workerNbr].coinId = e->cursorCoin;
}

void printBestScores() {
    for (int i = 0; i < e->nbrScores; i++) {
        // for (int i = 0; i < 2; i++) {
        printf("%.15lf %s %ld\n", e->bestScores[i].score,
               e->coins[e->bestScores[i].coinId]->name,
               e->coins[e->bestScores[i].coinId]
                   ->minutes[e->bestScores[i].minuteId]
                   .time);
    }
    printf("\n");
}

extern "C" char* bake(int sitSize, Minute* minutes) {
    e->sitSize = sitSize;
    memcpy(e->src, minutes, sizeof(Minute) * sitSize);
    for (int iBest = 0; iBest < e->nbrScores; iBest++) {
        e->bestScores[iBest].score = 999999999999;
    }
    for (e->cursorCoin = 0; e->cursorCoin < e->nbrCoins; e->cursorCoin++) {
        // printf("%s\n", e->coins[e->cursorCoin]->name);
        e->cursorMinute = 0;
        while (1) {
            compare<<<e->nbrBlocks, e->nbrThreads>>>(e);
            cudaDeviceSynchronize();
            cudaError_t error = cudaGetLastError();
            if (error != cudaSuccess) {
                printf("CUDA error: %s\n", cudaGetErrorString(error));
                exit(-1);
            }
            for (int iScore = 0; iScore < e->nbrBlocks * e->nbrThreads;
                 iScore++) {
                if (e->scores[iScore].score <=
                    e->bestScores[e->nbrScores - 1].score) {
                    // printf("%lf %lf %s\n",
                    // e->scores[iScore].score,e->coins[e->scores[iScore].coinId]->minutes[e->scores[iScore].minuteId].volume,
                    // e->coins[e->scores[iScore].coinId]->name);

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
                    }
                }
            }
            // exit(0);
            e->cursorMinute += e->nbrBlocks * e->nbrThreads;
            if (e->coins[e->cursorCoin]->size - e->cursorMinute <=
                e->nbrBlocks * e->nbrThreads) {
                break;
            }
        }
    }
    // printBestScores();
    int nbrChars = 0;
    for (int i = 0; i < e->nbrScores; i++) {
        nbrChars += sprintf(
            &e->result[nbrChars], "%lf|%s|%ld\n", e->bestScores[i].score,
            e->coins[e->bestScores[i].coinId]->name, e->bestScores[i].minuteId);
    }
    return e->result;
    // printf("%s\n", e->result);
}

extern "C" void init(int size, char* files[]) {
    cudaMallocManaged(&e, sizeof(Env));
    cudaMallocManaged(&e->coins, sizeof(void*) * size);
    cudaMallocManaged(&e->source, sizeof(Coin));
    cudaMallocManaged(&e->src, sizeof(Minute) * MAX_SIT_SIZE);
    e->result = (char*)malloc(MAX_SCORE_NBR * 1024);

    e->nbrCoins = 0;
    e->cursorCoin = 0;
    e->nbrBlocks = 256;
    e->nbrThreads = 128;
    e->nbrScores = 2000;

    e->nbrBlocks = 256;
    e->nbrThreads = 256;

    cudaMallocManaged(&e->scores, sizeof(Score) * e->nbrThreads * e->nbrBlocks);
    cudaMallocManaged(&e->bestScores, sizeof(Score) * MAX_SCORE_NBR);
    e->sitSize = 600;
    char path[128];
    for (int i = 0; i < size; i++) {
        snprintf(path, sizeof(path), "./data/%s", files[i]);
        int fd = open(path, O_RDONLY);
        if (fd < 0) {
            continue;
        }
        cudaMallocManaged(&e->coins[i], sizeof(Coin));
        struct stat buf;
        fstat(fd, &buf);
        off_t sizeAll = buf.st_size;
        cudaMallocManaged(&e->coins[i]->minutes, sizeAll);
        int res = read(fd, e->coins[i]->minutes, sizeAll);
        e->coins[i]->size = sizeAll / sizeof(Minute);
        snprintf(e->coins[i]->name, strlen(files[i]) + 1, "%s", files[i]);
        e->nbrCoins += 1;
        close(fd);
    }
}