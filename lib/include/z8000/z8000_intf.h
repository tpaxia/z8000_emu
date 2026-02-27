// Z8000 CPU Abstract Bus Interfaces
// These interfaces define what the CPU needs from the system.
// Embedders implement these to provide memory and I/O access.

#ifndef Z8000_INTF_H
#define Z8000_INTF_H

#include <cstdint>

// What the CPU needs from the system for memory access.
// The CPU presents addresses as-is (23-bit for Z8001 with segment info,
// 16-bit for Z8002). The implementer handles physical address translation.
class z8000_memory_bus {
public:
    virtual ~z8000_memory_bus() = default;
    virtual uint8_t read_byte(uint32_t addr) = 0;
    virtual uint16_t read_word(uint32_t addr) = 0;
    virtual void write_byte(uint32_t addr, uint8_t val) = 0;
    virtual void write_word(uint32_t addr, uint16_t val) = 0;
    virtual void write_word(uint32_t addr, uint16_t val, uint16_t mask) = 0;
};

// What the CPU needs from the system for I/O access.
// mode: 0=normal I/O (IN/OUT), 1=special I/O (SIN/SOUT)
class z8000_io_bus {
public:
    virtual ~z8000_io_bus() = default;
    virtual uint8_t read_byte(uint16_t addr, int mode) = 0;
    virtual uint16_t read_word(uint16_t addr, int mode) = 0;
    virtual void write_byte(uint16_t addr, uint8_t val, int mode) = 0;
    virtual void write_word(uint16_t addr, uint16_t val, int mode) = 0;
};

#endif // Z8000_INTF_H
