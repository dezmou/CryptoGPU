#include <fcntl.h>
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
double totalWait = 0;
double bank = 10000;

// potards
double changeRequired = 1000;
double closeLoss = 2;
double closeWin = 1;
double maxWait = 60;

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
    double change;
    int i;
    for (i = 1; i <= (int)maxWait; i++) {
        change = ((minute[i].close / minute->close * 100) - 100) *
                 (type == BUY ? 1 : -1);
        if (change > acloseWin || change < -acloseLoss) {
            break;
        }
    }
    cursor += i;
    totalWait += i;
    final = amount + (amount * (change * 0.01));
    fee += final * RAKE;
    totalFees += fee;
    final += -fee;
    if (change > 0) {
        printf(KGRN);
    }
    if (change < 0) {
        printf(KRED);
    }
    printf("%-5s ST : %-10.2lf END : %-10.2lf I : %-4d  CH : %-10.2lf  BK : %-10.2lf\n",
           type == BUY ? "BUY" : "SELL", minute->open, minute[i].open, i, change, bank);
    return final;
}

void analyse(Minute *minute) {
    double change = 100000 - (minute->open / minute->close * 100000);
    if (abs(change) > changeRequired) {
        nbrBets++;
        double betSize = 10000;
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
    srand(time(NULL));
    fillData();
    double bestGains = 0;
    double worstGains = 0;
    for (int i = 0; i < 10000000; i++) {
        nbrBets = 0;
        bank = 10000;
        totalFees = 0;
        totalWait = 0;

        changeRequired = 480;
        closeWin = 0.23;
        closeLoss = 0.89;
        maxWait = 37;

        // changeRequired = randfrom(100, 3000);
        // closeWin = randfrom(0.01, 1);
        // closeLoss = randfrom(0.01, 1);
        // maxWait = randfrom(1, 60);


        for (cursor = 0; cursor < nbrMinutes; cursor += 1) {
            play(&data[cursor]);
            // getchar();
            // break;
        }
        if (bank > bestGains && nbrBets > 600) {
            // printf(KGRN);
            printf(
                "NBB : %5d CHR:%8.2lf CLW:%8.2lf CLS%8.2lf BK:%10.2lf  "
                "FEE:%10.2lf   MXW:%10.2lf TW:%10.2lf\n",
                nbrBets, changeRequired, closeWin, closeLoss, bank, totalFees,
                maxWait, totalWait / 60);
            bestGains = bank;
        }
        break;
        // getchar();
    }
    printf("DONE\n");
    return 0;
}