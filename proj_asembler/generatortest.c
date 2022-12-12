#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

#ifndef RAND_MAX
#define RAND_MAX ((int) (unsigned)~0 >> 1)
#endif

//inclusive
double generateRandom(double low, double high) {
    
    double result;
    result = (double)rand() / ((double) RAND_MAX + 1);
    return (low + result * (high - low));
}

double myGenerator() {
    double res = 0.0; 
    int random = rand();
    printf("Rand = %d\n", random);
    res = (double)rand() * 100;
    return res; 
}

int main() {
    srand((int)time(NULL));
    double randomNum = generateRandom(1.0, 250.0);
    printf("1=%lf\n", randomNum);
    double randomNum2 = generateRandom(1.0, 250.0);
    printf("2=%lf\n", randomNum2);
    double randomNum3 = generateRandom(1.0, 250.0);
    printf("1=%lf\n", randomNum3);
    double randomNum4 = generateRandom(1.0, 250.0);
    printf("2=%lf\n", randomNum4);
    //double ran2 = myGenerator();
    //printf("2=%lf", ran2);

    return 0;
}