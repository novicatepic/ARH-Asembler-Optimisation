echo "10000 runs of x64"
time for i in {1..10000}; do ./projataketwoYMM2 entry_fileDOUBLE o; done
echo
echo "10000 runs of AVX"
time for i in {1..10000}; do ./p1 entry_fileDOUBLE o1; done
echo
