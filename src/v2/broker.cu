#include "trade.h"

Broker newBroker(Data data) {
    // Broker *broker = malloc(sizeof(Broker));
    Broker broker;
    broker.cursor = 0;
    broker.minutes = data.minutes;
    broker.nbrMinutes = data.nbrMinutes;
    broker.bank = 0;
    broker.seed = plantSeed();
    return broker;
}

__host__ __device__ void tickBroker(Broker *broker){
        broker->bank += 1;
}
