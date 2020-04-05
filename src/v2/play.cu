#include "trade.h"

int main(int argc, char *argv[]) {
    if (argc == 1) {
        printf("argv1 must be path to data binary\n");
        printf("argv2 must be seed string\n");
        exit(0);
    }
    Data data = loadMinutes(argv[1]);
    Broker broker = newBroker(data);
    broker.seed = scanSeed(argv[2]);
    printSeed(&broker.seed);
    for (int i = 0; i < data.nbrMinutes; i++) {
        broker.cursor = i;
        tickBroker(&broker);
    }
    return 0;
}