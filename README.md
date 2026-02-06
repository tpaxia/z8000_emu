# Z8000 Standalone Emulator

A standalone Z8000 CPU emulator extracted from MAME, designed for testing and debugging Z8000 code without the full MAME environment.

The CPU core is built as a reusable library (`libz8000.a`) with abstract memory/IO interfaces, so it can be embedded in different emulators (e.g., an M20 operating system emulator with 512KB segmented memory).

## Features

- Z8002 (non-segmented) and Z8001 (segmented) CPU emulation
- Reusable library with abstract bus interfaces (`z8000_memory_bus`, `z8000_io_bus`)
- Instruction tracing with disassembly
- Register state tracing
- Memory access tracing
- I/O port tracing with console I/O support
- Separate program/data/stack memory spaces (can be unified)
- Loads raw binary files

## Building

```bash
make              # Debug build (library + driver)
make release      # Optimized build
make libz8000     # Build only the library
make run-test     # Build and run test
make clean        # Remove built files
```

Output:
- `build/libz8000.a` - Z8000 CPU core library
- `build/z8000emu` - Emulator driver (links against library)

Requirements: C++17 compatible compiler (g++ or clang++)

## Usage

```
build/z8000emu [options] <binary-file>

Options:
  -s, --segmented      Use Z8001 segmented mode (default: Z8002 non-segmented)
  -b, --base <addr>    Load address in hex (default: 0x0000)
  -e, --entry <addr>   Override entry point (writes to reset vector)
  -t, --trace          Enable instruction tracing
  -r, --regtrace       Enable register tracing (dump after each instruction)
  -m, --memtrace       Enable memory access tracing
  -i, --iotrace        Enable I/O access tracing
  -c, --cycles <n>     Max cycles to execute (default: unlimited)
  -d, --dump           Dump memory after execution
  -h, --help           Show help
```

## Memory Map (Z8002)

```
Address     Contents
---------   ------------------------------------------
0x0000-01   Reserved
0x0002-03   FCW (Flags/Control Word) after reset
0x0004-05   PC (Program Counter) after reset
0x0006-07   FCW for Extended Instruction trap
0x0008-09   PC for Extended Instruction trap
0x000A-0B   FCW for Privileged Instruction trap
0x000C-0D   PC for Privileged Instruction trap
0x000E-0F   FCW for System Call
0x0010-11   PC for System Call
0x0012-13   FCW for Segment Trap
0x0014-15   PC for Segment Trap
0x0016-17   FCW for NMI
0x0018-19   PC for NMI
0x001A-1B   FCW for Non-Vectored Interrupt
0x001C-1D   PC for Non-Vectored Interrupt
0x001E-1F   FCW for Vectored Interrupt
0x0020-21   PC for Vectored Interrupt
0x0022+     Available for program and data
```

## Binary Format

The binary file should include the reset vector at the beginning.

### Z8002 (non-segmented) reset vector

```
Offset  Size  Contents
------  ----  --------
0x00    2     Reserved (typically 0x0000)
0x02    2     FCW - set to 0x4000 for system mode
0x04    2     PC - 16-bit entry point address
0x06+   -     Program code and data
```

### Z8001 (segmented) reset vector

```
Offset  Size  Contents
------  ----  --------
0x00    2     Reserved (typically 0x0000)
0x02    2     FCW - set to 0xC000 for segmented system mode
0x04    2     Segment word: (segment << 8) | 0x8000 (long format)
0x06    2     Offset word: 16-bit offset within segment
0x08+   -     Program code and data
```

### FCW (Flags and Control Word) Bits

| Bit | Name | Description |
|-----|------|-------------|
| 15  | SEG  | Segmented mode (Z8001 only) |
| 14  | S/N  | System/Normal mode (1=system, required for HALT) |
| 13  | EPU  | Extended processor unit |
| 12  | VIE  | Vectored interrupt enable |
| 11  | NVIE | Non-vectored interrupt enable |
| 10  | -    | Reserved |
| 9   | -    | Reserved |
| 8   | -    | Reserved |
| 7   | C    | Carry flag |
| 6   | Z    | Zero flag |
| 5   | S    | Sign flag |
| 4   | P/V  | Parity/Overflow flag |
| 3   | DA   | Decimal adjust flag |
| 2   | H    | Half-carry flag |
| 1-0 | -    | Reserved |

## Examples

### Running a Z8002 binary

```bash
build/z8000emu -t program.bin
```

### Running a Z8001 (segmented) binary

```bash
build/z8000emu -s -t program.bin
```

### Override entry point (for binaries without reset vector)

```bash
build/z8000emu -e 0x100 -t code.bin
```

### Creating a test binary

```bash
# Create binary with reset vector
printf '\x00\x00' > test.bin           # Reserved
printf '\x40\x00' >> test.bin          # FCW = 0x4000 (system mode)
printf '\x00\x06' >> test.bin          # PC = 0x0006 (entry point)
printf '\x21\x01\x12\x34' >> test.bin  # LD R1, #0x1234
printf '\x21\x02\x56\x78' >> test.bin  # LD R2, #0x5678
printf '\x81\x21' >> test.bin          # ADD R1, R2
printf '\x7A\x00' >> test.bin          # HALT

# Run it
build/z8000emu -t test.bin
```

Or use the built-in test target:

```bash
make run-test
```

## Console I/O

The emulator provides console I/O on port 0x0000:
- Writing a byte to port 0 outputs it to stdout
- Reading a byte from port 0 reads from stdin

Use `-i` flag to trace I/O operations.

## File Structure

```
z8000_emu/
├── src/
│   ├── main.cpp          # Driver: command-line interface and loader
│   └── z8000.cpp         # Library: CPU implementation (adapted from MAME)
├── include/
│   ├── z8000_intf.h      # Library: abstract bus interfaces
│   ├── z8000.h           # Library: CPU class definition
│   ├── emu.h             # Library: basic types, MAME compatibility shim
│   ├── z8000cpu.h        # Library: register and flag definitions
│   ├── z8000dab.h        # Library: DAB instruction lookup table
│   ├── z8000ops.hxx      # Library: opcode implementations
│   ├── z8000tbl.hxx      # Library: opcode dispatch table
│   └── memory.h          # Driver: flat-array memory and loopback I/O
├── tools/
│   ├── 8000dasm.cpp      # Library: disassembler (from MAME)
│   ├── 8000dasm.h
│   └── makedab.cpp       # DAB table generator
├── build/                # Compiled output (created by make)
│   ├── libz8000.a        # CPU core library
│   └── z8000emu          # Emulator driver
├── test/                 # Test binaries and assembly
├── Makefile
└── README.md
```

## Embedding the Library

To use `libz8000.a` in another project, implement the abstract bus interfaces and link against the library:

```cpp
#include "z8000.h"
#include "z8000_intf.h"

class MyMemory : public z8000_memory_bus {
    uint8_t ram[512 * 1024];
    uint8_t read_byte(uint32_t addr) override { return ram[addr]; }
    uint16_t read_word(uint32_t addr) override { return (ram[addr] << 8) | ram[addr+1]; }
    void write_byte(uint32_t addr, uint8_t val) override { ram[addr] = val; }
    void write_word(uint32_t addr, uint16_t val) override { ram[addr] = val >> 8; ram[addr+1] = val; }
    void write_word(uint32_t addr, uint16_t val, uint16_t mask) override {
        uint16_t old = read_word(addr);
        write_word(addr, (old & ~mask) | (val & mask));
    }
};

class MyIO : public z8000_io_bus {
    uint8_t read_byte(uint16_t addr, int mode) override { return 0; }
    uint16_t read_word(uint16_t addr, int mode) override { return 0; }
    void write_byte(uint16_t addr, uint8_t val, int mode) override {}
    void write_word(uint16_t addr, uint16_t val, int mode) override {}
};

MyMemory mem;
MyIO io;
z8001_device cpu;       // Z8001 segmented mode (or z8002_device)
cpu.set_memory(&mem);   // all spaces use same memory
cpu.set_io(&io);
cpu.reset();
cpu.run(1000);          // run 1000 cycles
```

## Origin

This emulator is based on the Z8000 CPU core from MAME (Multiple Arcade Machine Emulator). The core has been adapted to run standalone without the MAME device framework.

## License

BSD-3-Clause (inherited from MAME)
