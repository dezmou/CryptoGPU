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

typedef struct {
    long time;
    double open;
    double high;
    double low;
    double close;
    double volume;
} Minute;

typedef struct {
    int nbrMinutes;
    Minute *minutes;
} Data;

typedef struct {
    int type;
    double price;
} Order;

typedef struct {
    int type;
    long startCursor;
    double amount;
    double price;
    double closeWin;
    double closeLose;
    double totalFee;
} Bet;

typedef struct {
    long cursor;
    double bank;
    Bet *bet;
    Minute *minutes;
    int nbrBets;
    int nbrMinutes;
    double totalFee;
    long nbrWon;
    long nbrLost;
    int flatScore;
    int nbrFlatScore;
    double lastFlatBank;
    double variance;
} Broker;

typedef struct {
    double change_before_long;
    long change_before_long_steps;
    double closeWin;
    double closeLose;
    int period_for_variance;
    double maxVariance;
} Potards;

Data loadMinutes(char *path);
Bet analyse(Minute *minute, Potards *potards);
void printMinute(Minute *minute);