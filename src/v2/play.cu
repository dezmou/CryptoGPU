#include "trade.h"

FILE *fp;

int main(int argc, char *argv[]) {
    srand(time(NULL));
    fp = fopen("res.csv", "w");
    fprintf(fp, "price, bank, fee\n");

    if (argc == 1) {
        printf("argv1 must be path to data binary\n");
        exit(0);
    }
    Data data = loadMinutes(argv[1]);
    Broker broker = newBroker(data);
    if (argc == 2) {
    } else {
        broker.seed = scanSeed(argv[2]);
    }
    printSeed(&broker.seed);
    for (int i = TIME_START; i < data.nbrMinutes; i++) {
        broker.cursor = i;
        tickBroker(&broker);
    }
    return 0;
}