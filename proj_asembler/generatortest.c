#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

#ifndef RAND_MAX
#define RAND_MAX ((int) (unsigned)~0 >> 1)
#endif

//inclusive
float generateRandomFloat(float low, float high) {
    
    float result;
    result = (float)rand() / ((float) RAND_MAX + 1);
    return (low + result * (high - low));
}

int num_elements = 10000;

int main() {
    srand((int)time(NULL));
    float xValues[num_elements];
    float yValues[num_elements];

    FILE* fp = fopen("entry_file2", "wb");

    if(fp != NULL) {
        fwrite(&num_elements, sizeof(int), 1, fp);
        for(int i = 0; i < num_elements; i++) {
            xValues[i] = (float)generateRandomFloat(1, 4);
            yValues[i] = (float)generateRandomFloat(1, 4);
        }
        fwrite(xValues, sizeof(float), num_elements, fp);
        fwrite(yValues, sizeof(float), num_elements, fp);

        fclose(fp);
    }
    

    //double ran2 = myGenerator();
    //printf("2=%lf", ran2);

    return 0;
}