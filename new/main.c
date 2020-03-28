#include <fcntl.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>

#define KNRM "\x1B[0m"
#define KRED "\x1B[31m"
#define KGRN "\x1B[32m"
#define KYEL "\x1B[33m"
#define KBLU "\x1B[34m"
#define KMAG "\x1B[35m"
#define KCYN "\x1B[36m"
#define KWHT "\x1B[37m"

// #define RAKE 0.00275
#define RAKE 0.00075
// #define RAKE 0

#define BUY 1
#define SELL 2

typedef struct {
    long time;
    double open;
    double high;
    double low;
    double close;
    double volume;
} Minute;

Minute *data;
int nbrMinutes;
int cursor;
int nbrBets = 0;
double totalFees = 0;
int totalWait = 0;
double bank = 10000;
int nbrWon = 0;
int nbrLost = 0;

// potards
double changeRequired = 1000;
double closeLoss = 2;
double closeWin = 1;
double maxWait = 60;

int learn = 0;


double randfrom(double min, double max) {
    double range = (max - min);
    double div = RAND_MAX / range;
    return min + (rand() / div);
}

void fillData() {
    int fd = open("BTCUSDT", O_RDONLY);
    struct stat buf;
    fstat(fd, &buf);
    off_t size = buf.st_size;
    data = malloc(size);
    read(fd, data, size);
    nbrMinutes = size / sizeof(Minute);
}

double bet(Minute *minute, char type, double amount, double acloseWin,
           double acloseLoss) {
    double fee = amount * RAKE;
    double final = amount;
    double gain;
    int i;
    int overWaited = 1;
    for (i = 1; i <= (int)maxWait; i++) {
        // gain = (100 - (minute->close / minute[i].close * 100)) ;
        //        (type == BUY ? 1 : -1);
        gain = fabs((minute->close - minute[i].close) / minute->close * 100);
        if (minute->close > minute[i].close) {
            gain *= (type == BUY ? -1 : 1);
        } else if (minute->close < minute[i].close) {
            gain *= (type == BUY ? 1 : -1);
        }

        if (gain > acloseWin || gain < -acloseLoss) {
            overWaited = 0;
            break;
        }
    }
    if (!overWaited) {
        gain = gain < 0 ? -closeLoss : closeWin;
    }
    if (gain < 0) {
        nbrLost++;
    } else if (gain > 0) {
        nbrWon++;
    }
    long tmpCursor = cursor;
    cursor += i;
    totalWait += i;
    final = amount + (amount * (gain * 0.01));
    fee += final * RAKE;
    totalFees += fee;
    final += -fee;

    if (!learn) {
        if (gain > 0) {
            printf(KGRN);
        }
        if (gain < 0) {
            printf(KRED);
        }
        printf(
            "%-5s ST : %-10.2lf END : %-10.2lf I : %-4d  GAI : %-10.2lf  BK : "
            "%-10.2lf  FE : %-10.2lf  TW: %-5d  CU: %-5ld  DAY: %-4d\n",
            type == BUY ? "BUY" : "SELL", minute->close, minute[i].close, i,
            gain, bank, totalFees, totalWait, tmpCursor + 2, cursor / 60 / 24);
    }
    return final;
}

void analyse(Minute *minute) {
    double change = 100 - ((minute->open / minute->close) * 100);
    // printf("%lf\n", change);
    if (fabs(change) > changeRequired) {
        nbrBets++;
        double betSize = bank;
        // double betSize = 100;
        bank +=
            bet(minute, change < 0 ? BUY : SELL, betSize, closeWin, closeLoss);
        bank += -betSize;
        // printf("%8.2lf %8.2lf\n", minute->open, minute->close);
    }
}

void play(Minute *minute) {
    analyse(minute);
    // double betSize = 100;
    // bank += -betSize;
    // bank += bet(minute, SELL, betSize, 0.5, 0.5);
    // printf(" bank : %lf\n", bank);
}


int main() {
    learn = 0;
    srand(time(NULL));
    fillData();
    printf("%d\n", nbrMinutes);
    double bestGains = -99999999999;
    double worstGains = 0;
    for (int i = 0; i < 10000000000; i++) {
        nbrBets = 0;
        bank = 100;
        totalFees = 0;
        totalWait = 0;
        nbrLost = 0;
        nbrWon = 0;

        changeRequired = 0.42;
        closeWin = 4.03;
        closeLoss = 0.10;
        maxWait = 8;

        if (learn) {
            changeRequired = randfrom(0.001, 1);
            closeWin = randfrom(0.01, 5);
            closeLoss = randfrom(0.08, 1);
            maxWait = randfrom(1, 60);
        }

        for (cursor = 0; cursor < nbrMinutes; cursor += 1) {
            play(&data[cursor]);
            // getchar();
            // break;
        }
        if (bank > bestGains) {
            // if (bank > 1186628.65 && nbrBets > 600) {

            // if (nbrBets > 600) {
            // printf(KGRN);
            printf(
                "NBB: %-5d CHR: %-8.2lf CLW: %-8.2lf CLS: %-8.2lf BK: %-10.2lf "
                " "
                "FEE: %-10.2lf   MXW: %-10.2lf TW: %-10.2d  WL: %-5d / %-5d\n",
                nbrBets, changeRequired, closeWin, closeLoss, bank, totalFees,
                maxWait, totalWait, nbrWon, nbrLost);
            bestGains = bank;
        }
        if (!learn) {
            break;
        }
        // getchar();
    }
    printf("DONE\n");
    return 0;
}