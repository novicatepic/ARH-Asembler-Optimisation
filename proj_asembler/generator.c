#include <stdio.h>
#include <stdlib.h>

int num_of_generated = 5;

int main(int argc, char** argv) {

    FILE *fp = fopen("entry_file", "wb"); 

    fwrite(&num_of_generated, sizeof(int), 1, fp);

    double xArray[num_of_generated];
    double yArray[num_of_generated];

    for(int i = 0; i < 2; i++) {
        for(int j = 0; j < num_of_generated; j++) {
            double randNum = rand();
            if(i == 0) {
                xArray[j] = randNum;
            } else {
                yArray[j] = randNum;
            }
        }
    }

    fwrite(xArray, sizeof(double), num_of_generated, fp);
    fwrite(yArray, sizeof(double), num_of_generated, fp);

    fclose(fp);

    return 0;
}