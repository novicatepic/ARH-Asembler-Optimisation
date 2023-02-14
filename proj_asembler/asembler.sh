echo "1000 runs of x64"
time for i in {1..1000}; do ./projataketwoYMM2 entry_fileDOUBLE o; done
echo
echo "1000 runs of AVX"
time for i in {1..1000}; do ./projataketwoYMMP entry_fileDOUBLE o1; done
echo
echo "1000 runs of C"
time for i in {1..1000}; do ./mainDouble entry_fileDOUBLE o2; done
echo
