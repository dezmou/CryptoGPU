# include <fcntl.h>
# include <stdio.h>
# include <unistd.h>
# include <stdlib.h>
# include <string.h>
# include <dirent.h> 
# include <stdio.h> 
# include <time.h>
# include <sys/timeb.h>  
# include <sys/time.h> 

# define TIME 0
# define OPEN 1
# define CLOSE 2
# define HIGH 3
# define LOW 4
# define VOLUMETO 5
# define VOLUMEFROM 6

# define SITUATION_SIZE 500
# define CAN_PRINT if (okPrint())
# define POK printf("ok\n");
# define POKK printf("okk\n");
# define POKK printf("okk\n");
# define MAX_PRINT 50000

# define BUF 56 * SITUATION_SIZE

// # define BUF 56 * 100

int lastPrint ;

char okPrint(){
    if (lastPrint > MAX_PRINT){
        lastPrint = 0;
        return 1;
    }
    lastPrint += 1;
    return 0;
}

void bakeUnit(double *minute){
    // CAN_PRINT 
    printf("%15lf %15lf %15lf %15lf %15lf %15lf %15lf\n", \
    minute[TIME], minute[OPEN], minute[CLOSE], minute[HIGH], minute[LOW], minute[VOLUMEFROM], minute[VOLUMETO]);
}

void bake(char *file){
    int fd = open(file, O_RDONLY);
    double chien = 5;
    int readed  = 45;
    int ok = 0;
    double *data;

    while (1){
        data = malloc(BUF);

        readed = read(fd, data, BUF);
        if (readed < 1){
            break;
        }
        readed = readed / 8;
        for (int i = 0 ; i < readed ; i += 7){
            bakeUnit(&data[i]);
        }
        ok = 1;
        free(data);

    }
    if (ok == 0){
        printf("error %s\n", file);
    }
    close(fd);

}

// # define FOLDER "/media/ramdisk/datas/"
# define FOLDER "data2/"

int load_all(void) {


    DIR *d;
    // char fileName[64] = "data2/";
    char fileName[64] = FOLDER;
    struct dirent *dir;

  if (d){
    int g = 0;
        d = opendir(FOLDER);
       while ((dir = readdir(d)) != NULL) {
           g ++;
           if (g < 5){
               continue;
           }
           strcat(fileName, dir->d_name);
           bake(fileName);
        //    bake("big");
           fileName[6] = 0;
        //    break;
       }
    closedir(d);
    }

  return(0);
}

int main(){
    POK;
    lastPrint = 0;
    for (int i = 0; i < 1 ;i++){
        load_all();
    }

    return 0;
}