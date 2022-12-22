echo "10 runs of O0 with file that contains 150 000 000 elements"
time for i in {1..10}; do ./mainO0 entry_fileDOUBLE o; done

echo "10 runs of O1 with file that contains 150 000 000 elements"
time for i in {1..10}; do ./mainO1 entry_fileDOUBLE o1; done

echo "10 runs of O2 with file that contains 150 000 000 elements"
time for i in {1..10}; do ./mainO2 entry_fileDOUBLE o2; done

echo "10 runs of O3 with file that contains 150 000 000 elements"
time for i in {1..10}; do ./mainO3 entry_fileDOUBLE o34; done

echo "10 runs of Ofast with file that contains 150 000 000 elements"
time for i in {1..10}; do ./mainOfast entry_fileDOUBLE o3; done

echo "10 runs of Ofastmavx with file that contains 150 000 000 elements"
time for i in {1..10}; do ./mainOfastmavx entry_fileDOUBLE o4; done
