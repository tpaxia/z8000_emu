// Z8000 Standalone Emulator - Main Entry Point
// Loads binary files and executes Z8002 code with optional tracing

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <getopt.h>
#include "z8000.h"
#include "memory.h"

void print_usage(const char* progname) {
    printf("Z8000 Standalone Emulator\n");
    printf("Usage: %s [options] <binary-file>\n\n", progname);
    printf("Options:\n");
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
    printf("  %s -t program.bin           # Binary includes reset vector\n", progname);
    printf("  %s -e 0x100 -t code.bin     # Override entry point for code without vector\n", progname);
    printf("\nMemory Map (Z8002):\n");
    printf("  0x0000-0x0001: Reserved\n");
    printf("  0x0002-0x0003: FCW (Flags/Control Word) - set bit 14 for system mode\n");
    printf("  0x0004-0x0005: PC (Program Counter) after reset\n");
    printf("  0x0006-0xFFFF: Interrupt vectors, program, and data\n");
    printf("\nNote: Binary should include reset vector. Use -e to override entry point.\n");
}

uint16_t parse_hex(const char* str) {
    uint16_t val = 0;
    if (str[0] == '0' && (str[1] == 'x' || str[1] == 'X')) {
        sscanf(str + 2, "%hx", &val);
    } else {
        sscanf(str, "%hx", &val);
    }
    return val;
}

int main(int argc, char* argv[]) {
    uint16_t base_addr = 0x0000;
    uint16_t entry_addr = 0x0000;
    bool entry_set = false;
    bool trace = false;
    bool reg_trace = false;
    bool mem_trace = false;
    bool io_trace = false;
    bool dump_mem = false;
    int max_cycles = -1;
    const char* filename = nullptr;

    static struct option long_options[] = {
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
    while ((opt = getopt_long(argc, argv, "b:e:trmic:dh", long_options, nullptr)) != -1) {
        switch (opt) {
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

    // Load binary file
    FILE* f = fopen(filename, "rb");
    if (!f) {
        fprintf(stderr, "Error: Cannot open file '%s'\n", filename);
        return 1;
    }

    fseek(f, 0, SEEK_END);
    long filesize = ftell(f);
    fseek(f, 0, SEEK_SET);

    if (filesize > 0x10000 - base_addr) {
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
    printf("Loaded: %s (%ld bytes)\n", filename, filesize);
    printf("Base address: 0x%04X\n", base_addr);

    // Create memory region (shared for program, data, stack)
    // You could create separate regions for each if needed
    MemoryRegion memory(0x10000);  // 64KB
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

    // Create CPU
    z8002_device cpu;

    // Set all memory spaces to same region (can be separated later)
    cpu.set_memory(&memory);  // Sets program, data, stack all to same region
    cpu.set_io(&io);
    cpu.set_trace(trace);
    cpu.set_reg_trace(reg_trace);

    // Reset CPU
    cpu.reset();

    // Show reset vector from memory (should be part of loaded binary)
    // For Z8002: FCW at address 2, PC at address 4
    if (entry_set) {
        // Override entry point if explicitly specified (for testing binaries without reset vector)
        printf("Overriding entry point: 0x%04X\n", entry_addr);
        memory.write_word(4, entry_addr);
        // Ensure system mode if FCW is zero (privileged instructions like HALT need it)
        if (memory.read_word(2) == 0) {
            memory.write_word(2, 0x4000);  // F_S_N = system mode
        }
    }
    printf("Reset vector (Z8002):\n");
    printf("  FCW: 0x%04X\n", memory.read_word(2));
    printf("  PC:  0x%04X\n", memory.read_word(4));

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
