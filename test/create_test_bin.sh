#!/bin/sh
# Create regression test binary with reset vector header
# Reset vector: FCW=0x4000 (system mode), PC=0x0100
DIR="$(dirname "$0")"
printf '\x00\x00' > "${DIR}/test_instructions.bin"
printf '\x40\x00' >> "${DIR}/test_instructions.bin"
printf '\x01\x00' >> "${DIR}/test_instructions.bin"
dd if=/dev/zero bs=1 count=250 2>/dev/null >> "${DIR}/test_instructions.bin"
cat "${DIR}/test_instructions_raw.bin" >> "${DIR}/test_instructions.bin"
