#!/bin/bash

# Define the test file
TEST_FILE=/tmp/testfile

# Test write speed with dd
echo "Testing write speed with dd..."
dd if=/dev/zero of=$TEST_FILE bs=1G count=1 oflag=direct

# Test read speed with dd
echo "Testing read speed with dd..."
dd if=$TEST_FILE of=/dev/null bs=1G count=1 iflag=direct

# Cleanup
rm -f $TEST_FILE

echo "Disk I/O test with dd completed."
