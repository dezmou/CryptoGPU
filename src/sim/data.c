#include "trade.h"

Data loadMinutes(char * path) {
    Data data;
    int fd = open(path, O_RDONLY);
    struct stat buf;
    fstat(fd, &buf);
    off_t size = buf.st_size;
    data.minutes = malloc(size);
    int rd = read(fd, data.minutes, size);
    if (rd <= 0){
        printf("ERROR LOAD FILE\n");
        exit(0);
    }
    data.nbrMinutes = size / sizeof(Minute);
    return data;
}
