#!/bin/bash

# Test Runner Script
# Runs tests and captures output to a log file

set -e

# Check for test file argument
if [ -z "$1" ]; then
    echo "Usage: $0 <test_file> [log_name]"
    echo "Example: $0 test/models/user_test.rb"
    exit 1
fi

TEST_FILE="$1"
LOG_DIR="log/test_logs"
LOG_NAME="${2:-$(basename "$TEST_FILE" .rb)_$(date +%Y%m%d_%H%M%S).log}"
LOG_FILE="$LOG_DIR/$LOG_NAME"

# Create log directory if needed
mkdir -p "$LOG_DIR"

# Run tests and capture output
echo "Running: rails test $TEST_FILE"
echo "Log file: $LOG_FILE"

if rails test "$TEST_FILE" 2>&1 | tee "$LOG_FILE"; then
    echo ""
    echo "Tests passed. Log saved to: $LOG_FILE"
else
    echo ""
    echo "Tests failed. See log: $LOG_FILE"
    exit 1
fi
