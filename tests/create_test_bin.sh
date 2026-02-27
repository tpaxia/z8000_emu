#!/usr/bin/env bash
# Create regression test binary with reset vector header
# Reset vector: FCW=0x4000 (system mode), PC=0x0100

if [[ ! -f "test_instructions_raw.bin" ]]; then
    echo "Missing 'test_instructions_raw.bin'."
    exit 1
fi

printf '\x00\x00' > "test_instructions.bin"
printf '\x40\x00' >> "test_instructions.bin"
printf '\x01\x00' >> "test_instructions.bin"
dd if=/dev/zero bs=1 count=250 2>/dev/null >> "test_instructions.bin"
cat "test_instructions_raw.bin" >> "test_instructions.bin"
