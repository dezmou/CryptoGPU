#ifndef TRADE_H
#define TRADE_H

#include <cuda_runtime.h>
#include <fcntl.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
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

#define NO_BET 0
#define BUY 1
#define SELL 2

#define BROKER_REG_STEP 50000
#define TIME_START 10

#ifndef PLAY
#define DEVICE __device__
#endif

#ifdef PLAY
#define DEVICE __host__
#endif

#ifndef BUILD
#define __host__
#define __device__
#define __global__
#define blockDim .x 0
#define threadIdx .x 0
#define blockIdx 0
#endif


typedef struct {
    double a;
    double b;
    double c;
    double d;
    double e;
    double f;
    double g;
    double h;
    double i;
    double j;
    double k;
    double l;
    double m;
    double n;
    double o;
    double p;
    // double
} Seed;

typedef struct {
    long time;
    double open;
    double high;
    double low;
    double close;
    double volume;
} Minute;

typedef struct {
    long time;
    double open;
    double high;
    double low;
    double close;
    double volume;
    double avgCandle;
} Line;

typedef struct {
    int nbrMinutes;
    Minute *minutes;
    Line *line;
} Data;

typedef struct {
    int type;
    long cursor;
    double bank;
    double totalFee;
    double closeUp;
    double closeDown;
} Bet;

typedef struct {
    long cursor;
    Minute *minutes;
    int nbrMinutes;
    Seed seed;
    double bank;
    Bet bet;
    double fees;
    int nbrBets;
    int reg;
    int lastRegBank;
} Broker;

extern FILE *fp;

Broker newBroker(Data data);
double randfrom(double min, double max);
Seed plantSeed();
Data loadMinutes(char *path);
void printSeed(Seed *seed);
Seed scanSeed(char *seedStr);

DEVICE void printMinute(Minute *minute, int cursor);
DEVICE void tickBroker(Broker *broker);
DEVICE void analyse(Minute *minute, Seed *seed, Bet *bet);

#endif