// Z8000 Standalone Emulator - Main Entry Point
// Loads binary files and executes Z8001/Z8002 code with optional tracing

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <getopt.h>

#include <z8000/z8000.h>

#include "memory.h"

void print_usage(const char* progname) {
    printf("Z8000 Standalone Emulator\n");
    printf("Usage: %s [options] <binary-file>\n\n", progname);
    printf("Options:\n");
    printf("  -s, --segmented      Use Z8001 segmented mode (default: Z8002 non-segmented)\n");
    printf("  -b, --base <addr>    Load address in hex (default: 0x0000)\n");
    printf("  -e, --entry <addr>   Override entry point (writes to reset vector at addr 4)\n");
    printf("  -t, --trace          Enable instruction tracing\n");
    printf("  -r, --regtrace       Enable register tracing (dump after each instruction)\n");
    printf("  -m, --memtrace       Enable memory access tracing\n");
    printf("  -i, --iotrace        Enable I/O access tracing\n");
    printf("  -c, --cycles <n>     Max cycles to execute (default: unlimited)\n");
    printf("  -d, --dump           Dump memory after execution\n");
    printf("  -h, --help           Show this help\n");
    printf("\nExamples:\n");
    printf("  %s -t program.bin           # Z8002 binary with reset vector\n", progname);
    printf("  %s -s -t program.bin        # Z8001 segmented mode\n", progname);
    printf("  %s -e 0x100 -t code.bin     # Override entry point\n", progname);
    printf("\nReset Vector (Z8002 - 6 bytes):\n");
    printf("  0x0000-01: Reserved\n");
    printf("  0x0002-03: FCW (set bit 14 for system mode)\n");
    printf("  0x0004-05: PC (16-bit entry point)\n");
    printf("\nReset Vector (Z8001 - 8 bytes):\n");
    printf("  0x0000-01: Reserved\n");
    printf("  0x0002-03: FCW (set bit 15 for segmented, bit 14 for system mode)\n");
    printf("  0x0004-07: Segmented PC (seg<<8|0x80 in high word, offset in low word)\n");
    printf("\nNote: Binary should include reset vector. Use -e to override entry point.\n");
}

uint32_t parse_hex(const char* str) {
    uint32_t val = 0;
    if (str[0] == '0' && (str[1] == 'x' || str[1] == 'X')) {
        sscanf(str + 2, "%x", &val);
    } else {
        sscanf(str, "%x", &val);
    }
    return val;
}

int main(int argc, char* argv[]) {
    uint32_t base_addr = 0x0000;
    uint32_t entry_addr = 0x0000;
    bool entry_set = false;
    bool segmented = false;
    bool trace = false;
    bool reg_trace = false;
    bool mem_trace = false;
    bool io_trace = false;
    bool dump_mem = false;
    int max_cycles = -1;
    const char* filename = nullptr;

    static struct option long_options[] = {
        {"segmented",    no_argument,       0, 's'},
        {"base",         required_argument, 0, 'b'},
        {"entry",        required_argument, 0, 'e'},
        {"trace",        no_argument,       0, 't'},
        {"regtrace",     no_argument,       0, 'r'},
        {"memtrace",     no_argument,       0, 'm'},
        {"iotrace",      no_argument,       0, 'i'},
        {"cycles",       required_argument, 0, 'c'},
        {"dump",         no_argument,       0, 'd'},
        {"help",         no_argument,       0, 'h'},
        {0, 0, 0, 0}
    };

    int opt;
    while ((opt = getopt_long(argc, argv, "sb:e:trmic:dh", long_options, nullptr)) != -1) {
        switch (opt) {
            case 's':
                segmented = true;
                break;
            case 'b':
                base_addr = parse_hex(optarg);
                break;
            case 'e':
                entry_addr = parse_hex(optarg);
                entry_set = true;
                break;
            case 't':
                trace = true;
                break;
            case 'r':
                reg_trace = true;
                break;
            case 'm':
                mem_trace = true;
                break;
            case 'i':
                io_trace = true;
                break;
            case 'c':
                max_cycles = atoi(optarg);
                break;
            case 'd':
                dump_mem = true;
                break;
            case 'h':
                print_usage(argv[0]);
                return 0;
            default:
                print_usage(argv[0]);
                return 1;
        }
    }

    if (optind >= argc) {
        fprintf(stderr, "Error: No binary file specified\n\n");
        print_usage(argv[0]);
        return 1;
    }

    filename = argv[optind];

    // If entry point not set, use base address
    if (!entry_set) {
        entry_addr = base_addr;
    }

    // Z8001 has 23-bit (8MB) address space, Z8002 has 16-bit (64KB)
    size_t mem_size = segmented ? 0x800000 : 0x10000;

    // Load binary file
    FILE* f = fopen(filename, "rb");
    if (!f) {
        fprintf(stderr, "Error: Cannot open file '%s'\n", filename);
        return 1;
    }

    fseek(f, 0, SEEK_END);
    long filesize = ftell(f);
    fseek(f, 0, SEEK_SET);

    if ((size_t)filesize > mem_size - base_addr) {
        fprintf(stderr, "Error: File too large (%ld bytes) for load address 0x%04X\n",
                filesize, base_addr);
        fclose(f);
        return 1;
    }

    uint8_t* buffer = new uint8_t[filesize];
    size_t bytes_read = fread(buffer, 1, filesize, f);
    fclose(f);

    if (bytes_read != (size_t)filesize) {
        fprintf(stderr, "Error: Could not read entire file\n");
        delete[] buffer;
        return 1;
    }

    printf("Z8000 Standalone Emulator\n");
    printf("=========================\n");
    printf("CPU: %s\n", segmented ? "Z8001 (segmented)" : "Z8002 (non-segmented)");
    printf("Loaded: %s (%ld bytes)\n", filename, filesize);
    printf("Base address: 0x%04X\n", base_addr);

    // Create memory region (shared for program, data, stack)
    MemoryRegion memory(mem_size);
    memory.set_name("MEM");
    memory.set_trace(mem_trace);

    // Create I/O ports
    IOPorts io;
    io.set_trace(io_trace);

    // Load binary into memory
    if (!memory.load(base_addr, buffer, filesize)) {
        delete[] buffer;
        return 1;
    }
    delete[] buffer;

    // Create CPU (Z8001 or Z8002)
    z8001_device cpu_seg;
    z8002_device cpu_nonseg;
    z8002_device& cpu = segmented ? static_cast<z8002_device&>(cpu_seg) : cpu_nonseg;

    // Set all memory spaces to same region
    cpu.set_memory(&memory);
    cpu.set_io(&io);
    cpu.set_trace(trace);
    cpu.set_reg_trace(reg_trace);

    // Reset CPU
    cpu.reset();

    // Show reset vector from memory
    if (entry_set) {
        printf("Overriding entry point: 0x%04X\n", entry_addr);
        if (segmented) {
            // Z8001 reset vector: FCW at 2, segmented PC at 4-7
            // Encode entry_addr as segmented: seg in bits 22..16, offset in bits 15..0
            uint16_t seg = (entry_addr >> 16) & 0x7F;
            uint16_t off = entry_addr & 0xFFFF;
            uint16_t seg_word = (seg << 8) | 0x8000;  // long format marker
            memory.write_word(4, seg_word);
            memory.write_word(6, off);
            if (memory.read_word(2) == 0) {
                memory.write_word(2, 0xC000);  // F_SEG | F_S_N = segmented system mode
            }
        } else {
            memory.write_word(4, entry_addr & 0xFFFF);
            if (memory.read_word(2) == 0) {
                memory.write_word(2, 0x4000);  // F_S_N = system mode
            }
        }
    }

    if (segmented) {
        uint16_t fcw = memory.read_word(2);
        uint16_t seg_word = memory.read_word(4);
        uint16_t off_word = memory.read_word(6);
        uint32_t seg = (seg_word >> 8) & 0x7F;
        printf("Reset vector (Z8001):\n");
        printf("  FCW: 0x%04X\n", fcw);
        printf("  PC:  <<%02X>>%04X\n", seg, off_word);
    } else {
        printf("Reset vector (Z8002):\n");
        printf("  FCW: 0x%04X\n", memory.read_word(2));
        printf("  PC:  0x%04X\n", memory.read_word(4));
    }

    printf("\nStarting execution...\n");
    if (trace) {
        printf("---\n");
    }

    // Run CPU
    cpu.run(max_cycles);

    if (trace) {
        printf("---\n");
    }

    // Print final state (always show so test scripts can parse results)
    printf("\n");
    cpu.dump_regs();

    // Print summary
    printf("\nTotal cycles: %d\n", cpu.get_cycles());
    printf("Halted: %s\n", cpu.is_halted() ? "Yes" : "No");

    // Optional memory dump
    if (dump_mem) {
        printf("\n=== Memory Dump (first 256 bytes from load address) ===\n");
        memory.dump(base_addr, 256);
    }

    return 0;
}
