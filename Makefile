# Z8000 Standalone Emulator Makefile

CXX ?= c++
CXXFLAGS = -std=c++17 -Wall -Wextra -Iinclude

# Z8000 cross-toolchain
Z8K_PREFIX ?= z8k-coff-
Z8K_AS = $(Z8K_PREFIX)as
Z8K_LD = $(Z8K_PREFIX)ld
Z8K_OBJCOPY = $(Z8K_PREFIX)objcopy

# Directories
SRCDIR = src
INCDIR = include
BUILDDIR = build
TESTDIR = test

# Debug build (default)
CXXFLAGS_DEBUG = $(CXXFLAGS) -g -O0 -DDEBUG

# Release build
CXXFLAGS_RELEASE = $(CXXFLAGS) -O2 -DNDEBUG

# Source files
SOURCES = $(SRCDIR)/main.cpp $(SRCDIR)/z8000.cpp tools/8000dasm.cpp
HEADERS = $(wildcard $(INCDIR)/*.h) $(wildcard $(INCDIR)/*.hxx) tools/8000dasm.h

# Output
TARGET = $(BUILDDIR)/z8000emu
TEST_BIN = $(TESTDIR)/test.bin
REGRESSION_BIN = $(TESTDIR)/test_instructions.bin

.PHONY: all debug release clean run-test run-test-verbose run-regression help dirs

# Default target (debug)
all: debug

# Create directories
dirs:
	@mkdir -p $(BUILDDIR) $(TESTDIR)

debug: CXXFLAGS := $(CXXFLAGS_DEBUG)
debug: dirs $(TARGET)

release: CXXFLAGS := $(CXXFLAGS_RELEASE)
release: dirs $(TARGET)

$(TARGET): $(SOURCES) $(HEADERS)
	$(CXX) $(CXXFLAGS) -o $@ $(SOURCES)

clean:
	rm -rf $(BUILDDIR)
	rm -f $(TESTDIR)/*.bin $(TESTDIR)/*.o $(TESTDIR)/*.coff

# =============================================================================
# Simple test binary (hand-coded)
# =============================================================================
$(TEST_BIN): dirs
	@echo "Creating simple test binary..."
	@printf '\x00\x00' > $@           # 0-1: Reserved
	@printf '\x40\x00' >> $@          # 2-3: FCW = 0x4000 (system mode)
	@printf '\x00\x06' >> $@          # 4-5: PC = 0x0006 (entry point)
	@printf '\x21\x01\x12\x34' >> $@  # LD R1, #0x1234
	@printf '\x21\x02\x56\x78' >> $@  # LD R2, #0x5678
	@printf '\x81\x21' >> $@          # ADD R1, R2
	@printf '\x7A\x00' >> $@          # HALT
	@echo "Created: $@"

run-test: debug $(TEST_BIN)
	@echo "Running simple test..."
	$(TARGET) -t $(TEST_BIN)

run-test-verbose: debug $(TEST_BIN)
	@echo "Running simple test (verbose)..."
	$(TARGET) -t -m $(TEST_BIN)

# =============================================================================
# Instruction regression test
# =============================================================================

# Assemble test_instructions.s
$(TESTDIR)/test_instructions.o: $(TESTDIR)/test_instructions.s
	@echo "Assembling test_instructions.s..."
	$(Z8K_AS) -z8002 -o $@ $<

# Link at address 0x0100
$(TESTDIR)/test_instructions.coff: $(TESTDIR)/test_instructions.o
	@echo "Linking test_instructions..."
	$(Z8K_LD) -Ttext=0x0100 -o $@ $<

# Extract raw binary
$(TESTDIR)/test_instructions_raw.bin: $(TESTDIR)/test_instructions.coff
	@echo "Extracting binary..."
	$(Z8K_OBJCOPY) -O binary $< $@

# Create final binary with reset vector
$(REGRESSION_BIN): $(TESTDIR)/test_instructions_raw.bin dirs
	@echo "Creating regression test binary with reset vector..."
	@# Reset vector: FCW=0x4000 (system mode), PC=0x0100
	@printf '\x00\x00' > $@           # 0x0000: Reserved
	@printf '\x40\x00' >> $@          # 0x0002: FCW = 0x4000 (system mode)
	@printf '\x01\x00' >> $@          # 0x0004: PC = 0x0100 (entry point)
	@# Pad to 0x0100 (256 bytes total header)
	@dd if=/dev/zero bs=1 count=250 2>/dev/null >> $@
	@# Append the actual code
	@cat $(TESTDIR)/test_instructions_raw.bin >> $@
	@echo "Created: $@ ($(shell wc -c < $@) bytes)"

# Run regression test using test driver script
run-regression: debug $(REGRESSION_BIN)
	@$(TESTDIR)/run_regression.sh

# Run regression with verbose output (shows trace on failure)
run-regression-verbose: debug $(REGRESSION_BIN)
	@$(TESTDIR)/run_regression.sh -v

# Run regression with full instruction tracing
run-regression-trace: debug $(REGRESSION_BIN)
	@echo "Running regression test with tracing..."
	$(TARGET) -t $(REGRESSION_BIN)

# =============================================================================
# Help
# =============================================================================
help:
	@echo "Z8000 Standalone Emulator Build"
	@echo ""
	@echo "Emulator targets:"
	@echo "  all (default)        - Build debug version"
	@echo "  debug                - Build with debug symbols"
	@echo "  release              - Build optimized version"
	@echo "  clean                - Remove built files"
	@echo ""
	@echo "Test targets:"
	@echo "  run-test               - Run simple test (4 instructions)"
	@echo "  run-test-verbose       - Run simple test with memory tracing"
	@echo "  run-regression         - Run instruction regression test"
	@echo "  run-regression-verbose - Run regression with trace on failure"
	@echo "  run-regression-trace   - Run regression with full instruction trace"
	@echo ""
	@echo "Output: $(TARGET)"
	@echo ""
	@echo "Z8K toolchain: $(Z8K_PREFIX)as/ld/objcopy"
	@echo "  Override with: make Z8K_PREFIX=z8k-elf-"
