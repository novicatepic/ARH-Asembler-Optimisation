#include <stdio.h>
#include <stdlib.h>

int num_of_generated = 10;

int main(int argc, char** argv) {

    FILE *fp = fopen("entry_file", "wb"); 

    fwrite(&num_of_generated, sizeof(int), 1, fp);

    float xArray[num_of_generated];
    float yArray[num_of_generated];

    for(int i = 0; i < 2; i++) {
        if(i == 0) {
            printf("Unesite elemente za vektor x: ");
        } else {
            printf("Unesite elemente za vektor y: ");
        }
        
        for(int j = 0; j < num_of_generated; j++) {
            printf("Unesite %d.broj: ", j+1);
            float unos = 0.0;
            scanf("%f", &unos);
            if(i == 0) {
                xArray[j] = unos;
            } else {
                yArray[j] = unos;
            }
        }
    }

    fwrite(xArray, sizeof(float), num_of_generated, fp);
    fwrite(yArray, sizeof(float), num_of_generated, fp);

    fclose(fp);

    return 0;
}