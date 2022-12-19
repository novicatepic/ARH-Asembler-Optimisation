echo "1000 runs of NoSSE with file that contains 5 000 000 elements"
time for i in {1..1000}; do ./projataketwo entry_file2 output_file2; done

echo "1000 runs of SSE with file that contains 5 000 000 elements"
time for i in {1..1000}; do ./projaBAD entry_file2 output_file3; done

echo "1000 runs of c with file that contains 5 000 000 elements"
time for i in {1..1000}; do ./main entry_file2 output_file4; done
