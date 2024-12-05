#include <stdio.h>
#include <time.h>
#include <stdlib.h>

typedef struct{
    char *input_ptr;
    int value;
} UserInput;


// Declare the NASM function that makes the system call
extern UserInput take_user_input();
extern int user_prompt();


int passedTime(){

    //get timestamp
    struct timespec ts;

    if (clock_gettime(CLOCK_REALTIME, &ts) == -1) {
        perror("clock_gettime");
        return 1;
    }

    //open the file
    FILE *fptr = fopen("gametime.txt", "r+");

    //get the old value
    char savedTimeString[11];
    fgets(savedTimeString, 11, fptr);



    //save the new timestamp
    fseek(fptr, 0, SEEK_SET);
    fprintf(fptr, "%ld", ts.tv_sec);
    fclose(fptr);

    //convert values to int and calculate the difference
    int currentTime = ts.tv_sec;
    int savedTime = atoi(savedTimeString);
    int difference = currentTime - savedTime;

    return difference;
}


int main() {

    //get the time difference
    int difference = passedTime();

    //TODO update animal status


    int amount_pets = user_prompt();

    printf("amount pets: %d\n", amount_pets);

    return 0;
}


