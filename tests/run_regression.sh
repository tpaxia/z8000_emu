#!/usr/bin/env bash
# Z8000 Instruction Regression Test Driver
# Runs the emulator and extracts test results from memory

set -e

EMU="../bin/z8000emu"
TEST_BIN="test_instructions.bin"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if emulator exists
if [[ ! -x "$EMU" ]]; then
    echo -e "${RED}Error: Emulator not found at $EMU${NC}"
    echo "Run 'make debug' first to build the emulator."
    exit 1
fi

# Check if test binary exists
if [[ ! -f "$TEST_BIN" ]]; then
    echo -e "${RED}Test binary not found.${NC}"
    exit 1
fi

echo "=========================================="
echo "Z8000 Instruction Regression Test"
echo "=========================================="

# Run emulator and capture output
# Use -d to dump memory, we'll parse the results from 0x2300
OUTPUT=$("$EMU" "$TEST_BIN" 2>&1)

# Extract register values from output
# Format: R0 =XXXX  R1 =XXXX  R2 =XXXX  R3 =XXXX
R0=$(echo "$OUTPUT" | grep -o 'R0 =[0-9A-Fa-f]*' | head -1 | cut -d= -f2)
R1=$(echo "$OUTPUT" | grep -o 'R1 =[0-9A-Fa-f]*' | head -1 | cut -d= -f2)
R2=$(echo "$OUTPUT" | grep -o 'R2 =[0-9A-Fa-f]*' | head -1 | cut -d= -f2)
R3=$(echo "$OUTPUT" | grep -o 'R3 =[0-9A-Fa-f]*' | head -1 | cut -d= -f2)

# Convert hex to decimal
PASSED=$((16#$R0))
FAILED=$((16#$R1))
LAST_TEST=$((16#$R2))
STATUS=$R3

# Check if halted
if echo "$OUTPUT" | grep -q "Halted: Yes"; then
    HALTED="Yes"
else
    HALTED="No"
fi

# Extract cycle count
CYCLES=$(echo "$OUTPUT" | grep -o 'Total cycles: [0-9]*' | cut -d: -f2 | tr -d ' ')

echo ""
echo "Results:"
echo "  Tests Passed: $PASSED"
echo "  Tests Failed: $FAILED"
echo "  Last Test #:  $LAST_TEST"
echo "  Total Cycles: $CYCLES"
echo "  CPU Halted:   $HALTED"
echo ""

# Determine overall status
if [[ "$STATUS" == "DEAD" ]]; then
    echo -e "${GREEN}=========================================="
    echo "  ALL TESTS PASSED! (Status: 0xDEAD)"
    echo -e "==========================================${NC}"
    exit 0
elif [[ "$STATUS" == "FA11" ]]; then
    echo -e "${RED}=========================================="
    echo "  SOME TESTS FAILED! (Status: 0xFA11)"
    echo -e "==========================================${NC}"

    # Optionally run with tracing to find the failure
    if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
        echo ""
        echo "Running with trace to find failure point..."
        "$EMU" -t "$TEST_BIN" 2>&1 | tail -50
    else
        echo ""
        echo "Run with -v for verbose trace output"
    fi
    exit 1
else
    echo -e "${YELLOW}=========================================="
    echo "  UNKNOWN STATUS: 0x$STATUS"
    echo -e "==========================================${NC}"
    exit 2
fi
