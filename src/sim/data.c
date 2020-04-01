#include "trade.h"

Data loadMinutes(char * path) {
    Data data;
    int fd = open(path, O_RDONLY);
    struct stat buf;
    fstat(fd, &buf);
    off_t size = buf.st_size;
    data.minutes = malloc(size);
    read(fd, data.minutes, size);
    data.nbrMinutes = size / sizeof(Minute);
    return data;
}
