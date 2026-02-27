// Memory Model for Z8000 Standalone Emulator
// Provides flat-array memory and loopback I/O for the test driver.
// Implements the abstract bus interfaces from z8000_intf.h.

#ifndef MEMORY_H
#define MEMORY_H

#include <cstdio>
#include <cstring>
#include <cstdlib>

#include <z8000/emu.h>
#include <z8000/z8000_intf.h>

// Flat-array memory region implementing z8000_memory_bus
class MemoryRegion : public z8000_memory_bus {
public:
    MemoryRegion(size_t size = 0x10000) : m_size(size), m_trace(false), m_name("mem") {
        m_data = new u8[m_size];
        clear();
    }

    ~MemoryRegion() {
        delete[] m_data;
    }

    void clear() {
        memset(m_data, 0, m_size);
    }

    void set_trace(bool enable) { m_trace = enable; }
    void set_name(const char* name) { m_name = name; }

    size_t size() const { return m_size; }

    // Load binary data at specified address
    bool load(u32 addr, const u8* data, size_t len) {
        if (addr + len > m_size) {
            fprintf(stderr, "MemoryRegion: load exceeds bounds (0x%04X + 0x%zX > 0x%zX)\n",
                    addr, len, m_size);
            return false;
        }
        memcpy(&m_data[addr], data, len);
        return true;
    }

    // z8000_memory_bus interface
    u8 read_byte(u32 addr) override {
        addr &= (m_size - 1);
        u8 val = m_data[addr];
        if (m_trace) {
            printf("  %s RD8  [%04X] -> %02X\n", m_name, addr, val);
        }
        return val;
    }

    u16 read_word(u32 addr) override {
        addr &= (m_size - 1) & ~1;  // Word aligned
        u16 val = (static_cast<u16>(m_data[addr]) << 8) | m_data[addr + 1];
        if (m_trace) {
            printf("  %s RD16 [%04X] -> %04X\n", m_name, addr, val);
        }
        return val;
    }

    void write_byte(u32 addr, u8 val) override {
        addr &= (m_size - 1);
        if (m_trace) {
            printf("  %s WR8  [%04X] <- %02X\n", m_name, addr, val);
        }
        m_data[addr] = val;
    }

    void write_word(u32 addr, u16 val) override {
        addr &= (m_size - 1) & ~1;  // Word aligned
        if (m_trace) {
            printf("  %s WR16 [%04X] <- %04X\n", m_name, addr, val);
        }
        m_data[addr] = (val >> 8) & 0xFF;
        m_data[addr + 1] = val & 0xFF;
    }

    void write_word(u32 addr, u16 val, u16 mask) override {
        addr &= (m_size - 1) & ~1;
        u16 existing = read_word(addr);
        u16 new_val = (existing & ~mask) | (val & mask);
        if (m_trace) {
            printf("  %s WR16 [%04X] <- %04X (mask %04X)\n", m_name, addr, new_val, mask);
        }
        m_data[addr] = (new_val >> 8) & 0xFF;
        m_data[addr + 1] = new_val & 0xFF;
    }

    // Get raw pointer (for debugging/display)
    const u8* data() const { return m_data; }
    u8* data() { return m_data; }

    // Hex dump for debugging
    void dump(u32 start, u32 len) const {
        for (u32 i = 0; i < len; i += 16) {
            printf("%04X: ", (start + i) & 0xFFFF);
            for (u32 j = 0; j < 16 && (i + j) < len; j++) {
                printf("%02X ", m_data[(start + i + j) & (m_size - 1)]);
            }
            printf("\n");
        }
    }

private:
    u8* m_data;
    size_t m_size;
    bool m_trace;
    const char* m_name;
};

// I/O Ports - mock I/O space for testing
// Implements specific port behaviors expected by the regression tests:
//
// Normal I/O space (mode=0):
//   Loopback ports (read returns last written value):
//     - 0x0000-0x0001: io_data_reg (initial: 0x1234)
//     - 0x0002-0x0003: io_ctrl_reg (initial: 0x0000)
//   Fixed ports (always return same value):
//     - 0x0010: Always returns 0xAA (byte) or 0xAA00 (word)
//     - Any undefined port: Returns 0xDEAD (word) or 0xDE (byte)
//
// Special I/O space (mode=1, used by SIN/SOUT):
//   Loopback ports:
//     - 0x0020-0x0021: sio_data_reg (initial: 0x5678)
//   Other ports: Returns 0xBEEF (word) or 0xBE (byte)
//
class IOPorts : public z8000_io_bus {
public:
    IOPorts() : m_trace(false) {
        clear();
    }

    void clear() {
        // Initialize loopback registers with distinct values
        m_io_data_reg = 0x1234;
        m_io_ctrl_reg = 0x0000;
        m_sio_data_reg = 0x5678;
    }

    void set_trace(bool enable) { m_trace = enable; }

    // z8000_io_bus interface (mode: 0=normal, 1=special)
    u8 read_byte(u16 addr, int mode) override {
        u8 val;
        if (mode == 0) {
            // Normal I/O space
            switch (addr & 0xFFFE) {
                case 0x0000: val = (addr & 1) ? (m_io_data_reg & 0xFF) : (m_io_data_reg >> 8); break;
                case 0x0002: val = (addr & 1) ? (m_io_ctrl_reg & 0xFF) : (m_io_ctrl_reg >> 8); break;
                case 0x0010: val = (addr & 1) ? 0x55 : 0xAA; break;  // 0x10=0xAA, 0x11=0x55
                default: val = 0xDE; break;      // Undefined port
            }
        } else {
            // Special I/O space
            switch (addr & 0xFFFE) {
                case 0x0020: val = (addr & 1) ? (m_sio_data_reg & 0xFF) : (m_sio_data_reg >> 8); break;
                default: val = 0xBE; break;      // Undefined special port
            }
        }
        if (m_trace) {
            printf("  %sI/O RD8  [%04X] -> %02X\n", mode ? "S" : "", addr, val);
        }
        return val;
    }

    u16 read_word(u16 addr, int mode) override {
        addr &= 0xFFFE;
        u16 val;
        if (mode == 0) {
            // Normal I/O space
            switch (addr) {
                case 0x0000: val = m_io_data_reg; break;
                case 0x0002: val = m_io_ctrl_reg; break;
                case 0x0010: val = 0xAA00; break;  // Fixed value for block I/O tests
                default: val = 0xDEAD; break;      // Undefined port
            }
        } else {
            // Special I/O space
            switch (addr) {
                case 0x0020: val = m_sio_data_reg; break;
                default: val = 0xBEEF; break;      // Undefined special port
            }
        }
        if (m_trace) {
            printf("  %sI/O RD16 [%04X] -> %04X\n", mode ? "S" : "", addr, val);
        }
        return val;
    }

    void write_byte(u16 addr, u8 val, int mode) override {
        if (m_trace) {
            printf("  %sI/O WR8  [%04X] <- %02X\n", mode ? "S" : "", addr, val);
        }
        if (mode == 0) {
            // Normal I/O space
            switch (addr & 0xFFFE) {
                case 0x0000:
                    if (addr & 1) m_io_data_reg = (m_io_data_reg & 0xFF00) | val;
                    else m_io_data_reg = (m_io_data_reg & 0x00FF) | (val << 8);
                    break;
                case 0x0002:
                    if (addr & 1) m_io_ctrl_reg = (m_io_ctrl_reg & 0xFF00) | val;
                    else m_io_ctrl_reg = (m_io_ctrl_reg & 0x00FF) | (val << 8);
                    break;
                // Fixed ports and undefined ports ignore writes
            }
        } else {
            // Special I/O space
            switch (addr & 0xFFFE) {
                case 0x0020:
                    if (addr & 1) m_sio_data_reg = (m_sio_data_reg & 0xFF00) | val;
                    else m_sio_data_reg = (m_sio_data_reg & 0x00FF) | (val << 8);
                    break;
            }
        }
    }

    void write_word(u16 addr, u16 val, int mode) override {
        addr &= 0xFFFE;
        if (m_trace) {
            printf("  %sI/O WR16 [%04X] <- %04X\n", mode ? "S" : "", addr, val);
        }
        if (mode == 0) {
            // Normal I/O space
            switch (addr) {
                case 0x0000: m_io_data_reg = val; break;
                case 0x0002: m_io_ctrl_reg = val; break;
                // Fixed ports and undefined ports ignore writes
            }
        } else {
            // Special I/O space
            switch (addr) {
                case 0x0020: m_sio_data_reg = val; break;
            }
        }
    }

private:
    bool m_trace;
    // Loopback registers
    u16 m_io_data_reg;   // Normal I/O 0x0000
    u16 m_io_ctrl_reg;   // Normal I/O 0x0002
    u16 m_sio_data_reg;  // Special I/O 0x0020
};

#endif // MEMORY_H
