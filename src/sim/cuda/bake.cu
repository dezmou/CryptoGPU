#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>

#include "trade.h"

#define TIME_START 50
#define AMOUNT_STOP 9999999999999
#define FEE_TAKER 0.0004
#define FEE_MAKER 0.0004
#define BET_AMOUNT 10000

typedef struct {
    Data data;
    int nbrThreads;
    int nbrBlocks;
    Potards *potards;
    Broker *brokers;
} BakeParams;

__device__ double getVariance(Minute *minute, Potards *potards) {
    double min = 99999999999;
    double max = -9999999999;
    for (int cursor = -(potards->period_for_variance + 1); cursor <= 0;
         cursor++) {
        if (minute[cursor].low < min) {
            min = minute[cursor].low;
        }
        if (minute[cursor].high > max) {
            max = minute[cursor].high;
        }
    }
    return (max / min * 100) - 100;
}

__device__ Bet newBet(Minute *minute, int type, double amount, double closeWin,
           double closeLose) {
    Bet bet;
    bet.type = type;
    bet.totalFee = 0;
    bet.amount = amount;
    bet.closeLose = 0;
    bet.closeWin = 0;
    if (bet.type == NO_BET) {
        return bet;
    } else if (bet.type == SELL) {
        bet.closeLose = minute->close * (1 + closeLose * 0.01);
        bet.closeWin = minute->close * (1 - closeWin * 0.01);
    } else if (bet.type == BUY) {
        bet.closeLose = minute->close * (1 - closeLose * 0.01);
        bet.closeWin = minute->close * (1 + closeWin * 0.01);
    }
    return bet;
}

__device__ Bet analyse(Minute *minute, Potards *potards) {
    // dev
    // return newBet(minute, SELL, BET_AMOUNT / minute->close,
    //               potards->closeWin ,
    //               potards->closeLose);

    double change_before_long =
        100 - (minute[-(potards->change_before_long_steps)].close /
               minute->close * 100);
    // double variance = getVariance(minute, potards);
    double variance = 5.0;
    if (change_before_long > potards->change_before_long &&
        variance < potards->maxVariance) {
        return newBet(minute, SELL, BET_AMOUNT / minute->close,
                      potards->closeWin * change_before_long,
                      potards->closeLose * change_before_long);
    } else {
        return newBet(NULL, NO_BET, 0, 0, 0);
    }
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

__device__ void openBet(Broker *broker, Bet *bet) {
    double usd = bet->amount * broker->minutes[broker->cursor].close;
    double fee = usd * FEE_MAKER;
    bet->price = broker->minutes[broker->cursor].close;
    broker->bank += -usd;
    broker->bank += -fee;
    broker->bet = bet;
    broker->totalFee += fee;
    bet->startCursor = broker->cursor;
    // if (!LEARN) {
    //     printMinute(&broker->minutes[broker->cursor]);
    // }
}

__device__ void closeBet(Broker *broker, Bet *bet, double price) {
    double usd;
    double closePrice = price;
    if (bet->type == BUY) {
        // printf("CHENAPAN\n");
        usd = bet->amount * closePrice;
    } else if (bet->type == SELL) {
        usd = bet->amount * (bet->price + (bet->price - closePrice));
    }
    double fee = usd * FEE_MAKER;
    broker->bank += usd;
    broker->bank += -fee;
    broker->bet = NULL;
    broker->totalFee += fee;
    broker->nbrBets += 1;
    // printf("chien\n");
    // if (!LEARN) {
    //     printMinute(&broker->minutes[broker->cursor]);
    //     fprintf(fp, "%lf,%lf,%lf\n", broker->minutes[broker->cursor].close,
    //             broker->bank, broker->totalFee);
        // printf(
        //     "%-4s STA %-7ld CLO: %-7ld BK: %-9.2lf PRI: %-10.2lf CLW:
        //     %-10.2lf " "CLL: "
        //     "%-10.2lf "
        //     "ACT: %-10.2lf FEE: %-10.5lf TFE: %-10.5lf  NBT: %-6d FL: "
        //     "%-5d\n\n\n",
        //     (bet->type == BUY ? "BUY" : "SELL"), bet->startCursor + 2,
        //     broker->cursor + 2, broker->bank, bet->price, bet->closeWin,
        //     bet->closeLose, broker->minutes[broker->cursor].close, fee,
        //     broker->totalFee, broker->nbrBets, broker->flatScore);
    // }
    // printf(KWHT);
    // getchar();
}

__device__ int tickBroker(Broker *broker) {
    do {
        broker->cursor += 1;
        // if (broker->cursor % 100000 == 0){
        //     if (broker->bank < 0){
        //         return 0;
        //     }
        // }

        if (broker->cursor % 50000 == 0) {
            if (broker->bank > broker->lastFlatBank) {
                broker->flatScore += 1;
            } else if (broker->bank < broker->lastFlatBank) {
                broker->flatScore += -1;
            }
            // broker->flatScore += (broker->bank > broker->lastFlatBank) ? 1 :
            // 0;
            broker->lastFlatBank = broker->bank;
            broker->nbrFlatScore += 1;
        }
        if (broker->bet) {
            Bet *bet = broker->bet;
            if (bet->type == BUY) {
                if (broker->minutes[broker->cursor].low <= bet->closeLose) {
                    // lose
                    // printf(KRED);
                    closeBet(broker, bet, bet->closeLose);
                    broker->nbrLost++;
                } else if (broker->minutes[broker->cursor].high >=
                           bet->closeWin) {
                    // WIN
                    // printf(KGRN);
                    closeBet(broker, bet, bet->closeWin);
                    broker->nbrWon++;
                }
            } else if (bet->type == SELL) {
                if (broker->minutes[broker->cursor].high >= bet->closeLose) {
                    // lose
                    // printf(KRED);
                    closeBet(broker, bet, bet->closeLose);
                    broker->nbrLost++;
                } else if (broker->minutes[broker->cursor].low <=
                           bet->closeWin) {
                    // WIN
                    // printf(KGRN);
                    closeBet(broker, bet, bet->closeWin);
                    broker->nbrWon++;
                }
            }
        }
        if (broker->cursor >= broker->nbrMinutes - 1 ||
            (broker->cursor - TIME_START) > AMOUNT_STOP) {
            return 0;
        }
    } while (broker->bet != NULL);
    return 1;
}

__device__ void bake(Potards *potards, Broker *broker) {
    // printf("%lf\n", broker->minutes->open);
    do {
        Bet bet = analyse(&broker->minutes[broker->cursor], potards);
        if (bet.type) {
            openBet(broker, &bet);
        }
    } while (tickBroker(broker));
}

__device__ void printMinute(Minute *minute) {
    printf("%ld OPEN: %-10.5lf HIGH: %-10.5lf LOW: %-10.5lf CLOSE: %-10.5lf\n",
           minute->time, minute->open, minute->high, minute->low,
           minute->close);
}


__device__ Broker newBroker(Data data) {
    // Broker *broker = malloc(sizeof(Broker));
    Broker broker;
    broker.cursor = TIME_START;
    broker.bet = NULL;
    broker.minutes = data.minutes;
    broker.bank = 0;
    broker.nbrBets = 0;
    broker.totalFee = 0;
    broker.nbrWon = 0;
    broker.nbrLost = 0;
    broker.flatScore = 0;
    broker.nbrFlatScore = 0;
    broker.lastFlatBank = 0;
    broker.variance = 0;
    broker.nbrMinutes = data.nbrMinutes;
    return broker;
}

double randfrom(double min, double max) {
    double range = (max - min);
    double div = RAND_MAX / range;
    return min + (rand() / div);
}


Potards newPotards() {
    Potards res;
    res.change_before_long = 1.35;
    res.change_before_long_steps = 1;
    res.closeWin = 0.64;
    res.closeLose = 3.55;
    res.period_for_variance = 40;
    res.maxVariance = 17.11;
    // if (LEARN) {
    
    res.change_before_long = randfrom(0.01, 0.8);
    // res.change_before_long_steps = (long)randfrom(1, 10);
    res.closeWin = randfrom(0.05, 1);
    res.closeLose = randfrom(0.05, 1);
    // res.maxVariance = randfrom(1, 20);
    
    // }
    return res;
}

__global__ void cudaBake(BakeParams *p) {
    int workerNbr = threadIdx.x + blockIdx.x * blockDim.x; 
    Potards potard = p->potards[workerNbr];
    Broker broker = newBroker(p->data);
    bake(&potard, &broker);
    p->brokers[workerNbr] = broker;
    // p->brokers[workerNbr] = broker;
    printf("THX: %-5d BLX: %-5d THY: %-5d BLY: %-5d\n", threadIdx.x, blockIdx.x, threadIdx.y, blockIdx.y);
    // printMinute(&p->data.minutes[workerNbr]);
}

#define NBR_THREAD 512
#define NBR_BLOCK 512

// #define NBR_THREAD 1
// #define NBR_BLOCK 1


int main() {
    // return 0;
    BakeParams *p;
    cudaMallocManaged(&p, sizeof(BakeParams));
    cudaMallocManaged(&p->potards, sizeof(Potards) * NBR_BLOCK * NBR_THREAD);
    cudaMallocManaged(&p->brokers, sizeof(Broker) * NBR_BLOCK * NBR_THREAD);
    p->nbrBlocks = NBR_BLOCK;
    p->nbrThreads = NBR_THREAD;
    p->data = loadMinutes("../../../data/bin/BTCUSDT");

    for (int i = 0; i < NBR_THREAD * NBR_BLOCK; i++) {
        p->potards[i] = newPotards();
        // p->brokers[i] = newBroker(p->data);
    }
    cudaBake<<<p->nbrBlocks, p->nbrThreads>>>(p);
    cudaDeviceSynchronize();
    cudaError_t error = cudaGetLastError();
    if (error != cudaSuccess) {
        printf("CUDA error: %s\n", cudaGetErrorString(error));
        exit(-1);
    }
    return 0;
    for (int i = 0; i < NBR_THREAD * NBR_BLOCK; i++) {
        printf(
            "BK: %-8.2lf  NB: %-5d CBL: %-8.2lf CBLS: %-8.2ld CLW: %-8.2lf "
            "CLS: %-8.2lf FEE: %-8.2lf  NBW: %5ld NBL: %5ld "
            "FL: %-5d MXV: %-8.2lf\n",
            p->brokers[i].bank, p->brokers[i].nbrBets, p->potards[i].change_before_long,
            p->potards[i].change_before_long_steps, p->potards[i].closeWin, p->potards[i].closeLose,
            p->brokers[i].totalFee, p->brokers[i].nbrWon, p->brokers[i].nbrLost,
            p->brokers[i].flatScore, p->potards[i].maxVariance);
    }

    return 0;
}
