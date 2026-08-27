// license:BSD-3-Clause
// copyright-holders:Juergen Buchmueller,Ernesto Corvi
// Adapted for standalone use
/*****************************************************************************
 *
 *   z8000.cpp
 *   Portable Z8000(2) emulator
 *   Standalone version adapted from MAME
 *
 *****************************************************************************/

#include <cstdio>
#include <cassert>
#include <sstream>

#include <z8000/z8000.h>
#include <z8000/z8000cpu.h>

// data_buffer::r16 implementation (needs z8000_memory_bus to be complete)
u16 data_buffer::r16(offs_t addr) const {
    if (m_bus) {
        return m_bus->read_word(addr);
    }
    if (!m_data || addr + 1 >= m_size) return 0xFFFF;
    // Big-endian read
    return (static_cast<u16>(m_data[addr]) << 8) | m_data[addr + 1];
}

//#define VERBOSE 1

#ifndef VERBOSE
#define VERBOSE 0
#endif

#define LOG(...)  do { if (VERBOSE) printf(__VA_ARGS__); } while(0)


z8002_device::z8002_device()
    : m_ppc(0), m_pc(0), m_psapseg(0), m_psapoff(0), m_fcw(0), m_refresh(0)
    , m_nspseg(0), m_nspoff(0), m_irq_req(0), m_irq_vec(0), m_op_valid(0)
    , m_nmi_state(0), m_mi(0), m_halt(false), m_icount(0), m_total_cycles(0)
    , m_vector_mult(1)
    , m_program_bus(nullptr), m_data_bus(nullptr), m_stack_bus(nullptr)
    , m_io_bus(nullptr), m_trace(false), m_reg_trace(false), m_disasm(nullptr)
{
    clear_internal_state();
    init_tables();
    m_disasm = new z8000_disassembler(this);
}

z8002_device::z8002_device(int addrbits, int vecmult)
    : m_ppc(0), m_pc(0), m_psapseg(0), m_psapoff(0), m_fcw(0), m_refresh(0)
    , m_nspseg(0), m_nspoff(0), m_irq_req(0), m_irq_vec(0), m_op_valid(0)
    , m_nmi_state(0), m_mi(0), m_halt(false), m_icount(0), m_total_cycles(0)
    , m_vector_mult(vecmult)
    , m_program_bus(nullptr), m_data_bus(nullptr), m_stack_bus(nullptr)
    , m_io_bus(nullptr), m_trace(false), m_reg_trace(false), m_disasm(nullptr)
{
    (void)addrbits;  // May be used for Z8001 in future
    clear_internal_state();
    init_tables();
    m_disasm = new z8000_disassembler(this);
}

z8001_device::z8001_device()
    : z8002_device(23, 2)
{
}

z8002_device::~z8002_device()
{
    delete m_disasm;
}

void z8002_device::set_program_memory(z8000_memory_bus* mem)
{
    m_program_bus = mem;
    m_cache.bus = mem;
    m_opcache.bus = mem;
    m_program.bus = mem;
}

void z8002_device::set_data_memory(z8000_memory_bus* mem)
{
    m_data_bus = mem;
    m_data.bus = mem;
}

void z8002_device::set_stack_memory(z8000_memory_bus* mem)
{
    m_stack_bus = mem;
    m_stack.bus = mem;
}

void z8002_device::set_io(z8000_io_bus* io)
{
    m_io_bus = io;
}

bool z8002_device::get_segmented_mode() const
{
    return false;
}

bool z8001_device::get_segmented_mode() const
{
    return (m_fcw & F_SEG) ? true : false;
}

uint32_t z8002_device::addr_add(uint32_t addr, uint32_t addend)
{
    return (addr & 0xffff0000) | ((addr + addend) & 0xffff);
}

uint32_t z8002_device::addr_sub(uint32_t addr, uint32_t subtrahend)
{
    return (addr & 0xffff0000) | ((addr - subtrahend) & 0xffff);
}

/* conversion table for Z8000 DAB opcode */
#include <z8000/z8000dab.h>

uint16_t z8002_device::RDOP()
{
    uint16_t res = m_opcache.read_word(m_pc);
    m_pc += 2;
    return res;
}

uint32_t z8002_device::get_operand(int opnum)
{
    int i;

    for (i = 0; i < opnum; i++)
    {
        assert (m_op_valid & (1 << i));
    }

    if (! (m_op_valid & (1 << opnum)))
    {
        m_op[opnum] = m_cache.read_word(m_pc);
        m_pc += 2;
        m_op_valid |= (1 << opnum);
    }
    return m_op[opnum];
}

uint32_t z8002_device::get_addr_operand(int opnum)
{
    int i;

    for (i = 0; i < opnum; i++)
    {
        assert (m_op_valid & (1 << i));
    }

    if (! (m_op_valid & (1 << opnum)))
    {
        uint32_t seg = m_cache.read_word(m_pc);
        m_pc += 2;
        if (get_segmented_mode())
        {
            if (seg & 0x8000)
            {
                m_op[opnum] = ((seg & 0x7f00) << 8) | m_cache.read_word(m_pc);
                m_pc += 2;
            }
            else
                m_op[opnum] = ((seg & 0x7f00) << 8) | (seg & 0xff);
        }
        else
            m_op[opnum] = seg;
        m_op_valid |= (1 << opnum);
    }
    return m_op[opnum];
}

uint32_t z8002_device::get_raw_addr_operand(int opnum)
{
    int i;

    for (i = 0; i < opnum; i++)
    {
        assert (m_op_valid & (1 << i));
    }

    if (! (m_op_valid & (1 << opnum)))
    {
        uint32_t seg = m_cache.read_word(m_pc);
        m_pc += 2;
        if (get_segmented_mode())
        {
            if (seg & 0x8000)
            {
                m_op[opnum] = (seg << 16) | m_cache.read_word(m_pc);
                m_pc += 2;
            }
            else
                m_op[opnum] = (seg << 16) | (seg & 0xff);
        }
        else
            m_op[opnum] = seg;
        m_op_valid |= (1 << opnum);
    }
    return m_op[opnum];
}

uint32_t z8002_device::adjust_addr_for_nonseg_mode(uint32_t addr)
{
    return addr;
}

uint32_t z8001_device::adjust_addr_for_nonseg_mode(uint32_t addr)
{
    if (!(m_fcw & F_SEG))
    {
        return (addr & 0xffff) | (m_pc & 0x7f0000);
    }
    else
    {
        return addr;
    }
}

uint8_t z8002_device::RDMEM_B(mem_specific &space, uint32_t addr)
{
    addr = adjust_addr_for_nonseg_mode(addr);
    return space.read_byte(addr);
}

uint16_t z8002_device::RDMEM_W(mem_specific &space, uint32_t addr)
{
    addr = adjust_addr_for_nonseg_mode(addr);
    addr &= ~1;
    return space.read_word(addr);
}

uint32_t z8002_device::RDMEM_L(mem_specific &space, uint32_t addr)
{
    uint32_t result;
    addr = adjust_addr_for_nonseg_mode(addr);
    addr &= ~1;
    result = space.read_word(addr) << 16;
    return result + space.read_word(addr_add(addr, 2));
}

void z8002_device::WRMEM_B(mem_specific &space, uint32_t addr, uint8_t value)
{
    addr = adjust_addr_for_nonseg_mode(addr);
    uint16_t value16 = value | (value << 8);
    space.write_word(addr & ~1, value16, BIT(addr, 0) ? 0x00ff : 0xff00);
}

void z8002_device::WRMEM_W(mem_specific &space, uint32_t addr, uint16_t value)
{
    addr = adjust_addr_for_nonseg_mode(addr);
    addr &= ~1;
    space.write_word(addr, value);
}

void z8002_device::WRMEM_L(mem_specific &space, uint32_t addr, uint32_t value)
{
    addr = adjust_addr_for_nonseg_mode(addr);
    addr &= ~1;
    space.write_word(addr, value >> 16);
    space.write_word(addr_add(addr, 2), value & 0xffff);
}

uint8_t z8002_device::RDPORT_B(int mode, uint16_t addr)
{
    return m_io_bus->read_byte(addr, mode);
}

uint16_t z8002_device::RDPORT_W(int mode, uint16_t addr)
{
    return m_io_bus->read_word(addr, mode);
}

void z8002_device::WRPORT_B(int mode, uint16_t addr, uint8_t value)
{
    m_io_bus->write_byte(addr, value, mode);
}

void z8002_device::WRPORT_W(int mode, uint16_t addr, uint16_t value)
{
    m_io_bus->write_word(addr, value, mode);
}

void z8002_device::cycles(int cyc)
{
    m_icount -= cyc;
    m_total_cycles += cyc;
}

#include <z8000/z8000ops.hxx>
#include <z8000/z8000tbl.hxx>

void z8002_device::PUSH_PC()
{
    PUSHW(SP, m_pc);        /* save current pc */
}

void z8001_device::PUSH_PC()
{
    PUSHL(SP, make_segmented_addr(m_pc));        /* save current pc */
}


uint32_t z8002_device::GET_PC(uint32_t VEC)
{
    return RDMEM_W(m_data, VEC + 2);
}

uint32_t z8001_device::GET_PC(uint32_t VEC)
{
    return segmented_addr(RDMEM_L(m_data, VEC + 4));
}

uint32_t z8002_device::get_reset_pc()
{
    return RDMEM_W(m_program, 4);
}

uint32_t z8001_device::get_reset_pc()
{
    return segmented_addr(RDMEM_L(m_program, 4));
}

uint16_t z8002_device::GET_FCW(uint32_t VEC)
{
    return RDMEM_W(m_data, VEC);
}

uint16_t z8001_device::GET_FCW(uint32_t VEC)
{
    return RDMEM_W(m_data, VEC + 2);
}

uint32_t z8002_device::F_SEG_Z8001()
{
    return 0;
}

uint32_t z8001_device::F_SEG_Z8001()
{
    return F_SEG;
}

uint32_t z8002_device::PSA_ADDR()
{
    /* The reserved low byte is not part of the address - the PSA starts on a
       256-byte boundary (z8000.md 7.7.3).  Masked here rather than on the
       write so the register keeps what software put in it; the two are
       indistinguishable from software, since LDCTL is the only way to load
       PSAP, but this keeps the masking at the point the manual describes.
       Pinned by seg_psap_no_unaligned_psa. */
    return m_psapoff & 0xff00;
}

uint32_t z8001_device::PSA_ADDR()
{
    /* see the nonsegmented version - the reserved low byte is dropped here */
    return segmented_addr((m_psapseg << 16) | (m_psapoff & 0xff00));
}


/*
 * Exception dispatch.
 *
 * Priority (z8000.md 7.8, descending):
 *      Reset
 *      Internal trap  (extended instruction, privileged instruction, SC)
 *      Nonmaskable interrupt
 *      Segment / address translation trap
 *      Vectored interrupt
 *      Nonvectored interrupt
 * The tests below are ordered to match; do not reorder them.
 *
 * All Program Status Area accesses (GET_FCW / GET_PC / read_irq_vector) go
 * through m_data.
 *
 * z8000.md 7.7.3 says otherwise - "loaded from the Program Status Area in
 * system program memory (i.e. status outputs ST3-ST0 indicate IF_N ...)",
 * which would be status 1100 - and this code followed the manual until the
 * part was asked directly.  Driving SC #0 on a Z8001 with the bus status
 * captured per cycle (seg_sc_basic, golden trace) gives:
 *
 *      0x081A  C000  R  ST=1000   new FCW
 *      0x081C  8000  R  ST=1000   new PC segment
 *      0x081E  0300  R  ST=1000   new PC offset
 *
 * 1000 is a data memory request.  The same trace shows 1101/1100 on the
 * instruction fetches either side of it, so this is the part distinguishing
 * the two spaces, not a stuck status line.  A system decoding ST3-ST0 - a
 * Z8010 MMU, say - therefore sees the PSA as a data reference.
 *
 * The reset vector at 0x0002/0x0004 is left on m_program: it is fetched
 * before any of this applies and no capture covers it.
 */
void z8002_device::Interrupt()
{
    uint16_t fcw = m_fcw;

    if (m_irq_req & Z8000_RESET)
    {
        m_irq_req &= Z8000_NVI | Z8000_VI;
        CHANGE_FCW(RDMEM_W(m_program, 2)); /* get reset m_fcw */
        m_pc = get_reset_pc(); /* get reset m_pc  */
    }
    else
    /* trap ? */
    if (m_irq_req & Z8000_EPU)
    {
        CHANGE_FCW(fcw | F_S_N | F_SEG_Z8001());/* switch to segmented (on Z8001) system mode */
        PUSH_PC();
        PUSHW(SP, fcw);       /* save current m_fcw */
        PUSHW(SP, m_op[0]);   /* for internal traps, the 1st word of the instruction is pushed */
        m_irq_req &= ~Z8000_EPU;
        CHANGE_FCW(GET_FCW(EPU));
        m_pc = GET_PC(EPU);
        LOG("Z8K ext instr trap $%04x\n", m_pc);
    }
    else
    if (m_irq_req & Z8000_TRAP)
    {
        CHANGE_FCW(fcw | F_S_N | F_SEG_Z8001());/* switch to segmented (on Z8001) system mode */
        PUSH_PC();
        PUSHW(SP, fcw);       /* save current m_fcw */
        PUSHW(SP, m_op[0]);   /* for internal traps, the 1st word of the instruction is pushed */
        m_irq_req &= ~Z8000_TRAP;
        CHANGE_FCW(GET_FCW(TRAP));
        m_pc = GET_PC(TRAP);
        LOG("Z8K priv instr trap $%04x\n", m_pc);
    }
    else
    if (m_irq_req & Z8000_SYSCALL)
    {
        if (m_trap_cb && !m_trap_cb(m_trap_cb_ctx, m_op[0] & 0xff, m_ppc)) {
            m_irq_req &= ~Z8000_SYSCALL;
            m_halt = true;
        } else {
            CHANGE_FCW(fcw | F_S_N | F_SEG_Z8001());/* switch to segmented (on Z8001) system mode */
            PUSH_PC();
            PUSHW(SP, fcw);       /* save current m_fcw */
            PUSHW(SP, m_op[0]);   /* for internal traps, the 1st word of the instruction is pushed */
            m_irq_req &= ~Z8000_SYSCALL;
            CHANGE_FCW(GET_FCW(SYSCALL));
            m_pc = GET_PC(SYSCALL);
            LOG("Z8K syscall [$%02x/$%04x]\n", m_op[0] & 0xff, m_pc);
        }
    }
    else
    if (m_irq_req & Z8000_NMI)
    {
        m_irq_vec = 0;
        m_halt = false;

        CHANGE_FCW(fcw | F_S_N | F_SEG_Z8001());/* switch to segmented (on Z8001) system mode */
        PUSH_PC();
        PUSHW(SP, fcw);       /* save current m_fcw */
        PUSHW(SP, m_irq_vec);   /* save interrupt/trap type tag */
        m_pc = GET_PC(NMI);
        m_irq_req &= ~Z8000_NMI;
        CHANGE_FCW(GET_FCW(NMI));
        LOG("Z8K NMI $%04x\n", m_pc);
    }
    else
    if (m_irq_req & Z8000_SEGTRAP)
    {
        m_irq_vec = 0;  // No interrupt acknowledge in standalone

        CHANGE_FCW(fcw | F_S_N | F_SEG_Z8001());/* switch to segmented (on Z8001) system mode */
        PUSH_PC();
        PUSHW(SP, fcw);       /* save current m_fcw */
        PUSHW(SP, m_irq_vec);   /* save interrupt/trap type tag */
        m_pc = GET_PC(SEGTRAP);
        m_irq_req &= ~Z8000_SEGTRAP;
        CHANGE_FCW(GET_FCW(SEGTRAP));
        LOG("Z8K segtrap $%04x\n", m_pc);
    }
    else
    if ((m_irq_req & Z8000_VI) && (m_fcw & F_VIE))
    {
        m_irq_vec = 0;
        m_halt = false;

        CHANGE_FCW(fcw | F_S_N | F_SEG_Z8001());/* switch to segmented (on Z8001) system mode */
        PUSH_PC();
        PUSHW(SP, fcw);       /* save current m_fcw */
        PUSHW(SP, m_irq_vec);   /* save interrupt/trap type tag */
        m_pc = read_irq_vector();
        m_irq_req &= ~Z8000_VI;
        CHANGE_FCW(GET_FCW(VI));
        LOG("Z8K VI [$%04x/$%04x] fcw $%04x, pc $%04x\n", m_irq_vec, VEC00 + 2 * (m_irq_vec & 0xff), m_fcw, m_pc);
    }
    else
    if ((m_irq_req & Z8000_NVI) && (m_fcw & F_NVIE))
    {
        m_irq_vec = 0;
        m_halt = false;

        CHANGE_FCW(fcw | F_S_N | F_SEG_Z8001());/* switch to segmented (on Z8001) system mode */
        PUSH_PC();
        PUSHW(SP, fcw);       /* save current m_fcw */
        PUSHW(SP, m_irq_vec);   /* save interrupt/trap type tag */
        m_pc = GET_PC(NVI);
        m_irq_req &= ~Z8000_NVI;
        CHANGE_FCW(GET_FCW(NVI));
        LOG("Z8K NVI $%04x\n", m_pc);
    }
}

uint32_t z8002_device::read_irq_vector()
{
    return RDMEM_W(m_data, VEC00 + 2 * (m_irq_vec & 0xff));
}


uint32_t z8001_device::read_irq_vector()
{
    return segmented_addr(RDMEM_L(m_data, VEC00 + 2 * (m_irq_vec & 0xff)));
}


void z8002_device::set_input_line(int line, int state)
{
    switch (line)
    {
        case NMI_LINE:
            /* NMI is edge triggered: latch a request on the inactive-to-active
               transition only, so holding the line low does not re-trigger. */
            if (m_nmi_state == CLEAR_LINE && state != CLEAR_LINE)
                m_irq_req |= Z8000_NMI;
            m_nmi_state = state;
            break;

        case NVI_LINE:
        case VI_LINE:
            /* NVI/VI are level sensitive. NVI_LINE and VI_LINE index
               m_irq_state[] directly. */
            m_irq_state[line] = state;
            if (state == CLEAR_LINE)
                m_irq_req &= ~(line == NVI_LINE ? Z8000_NVI : Z8000_VI);
            else
                m_irq_req |= (line == NVI_LINE ? Z8000_NVI : Z8000_VI);
            break;

        default:
            break;
    }
}


void z8002_device::set_input_line_and_vector(int line, int state, uint16_t vector)
{
    m_irq_vec = vector;
    set_input_line(line, state);
}


void z8002_device::pulse_input_line(int line, uint16_t vector)
{
    switch (line)
    {
        case NMI_LINE:
            /* already edge triggered - a pulse is the normal case */
            set_input_line(NMI_LINE, ASSERT_LINE);
            m_nmi_state = CLEAR_LINE;
            break;

        case NVI_LINE:
        case VI_LINE:
            /* Latch the request, but leave m_irq_state[] clear so CHANGE_FCW
               does not re-latch it when the handler re-enables NVIE/VIE. */
            m_irq_vec = vector;
            m_irq_req |= (line == NVI_LINE ? Z8000_NVI : Z8000_VI);
            break;

        default:
            break;
    }
}


void z8002_device::clear_internal_state()
{
    m_op[0] = m_op[1] = m_op[2] = m_op[3] = 0;
    m_ppc = 0;
    m_pc = 0;
    m_psapseg = 0;
    m_psapoff = 0;
    m_fcw = 0;
    m_refresh = 0;
    m_nspseg = 0;
    m_nspoff = 0;
    m_irq_req = 0;
    m_irq_vec = 0;
    m_op_valid = 0;
    m_regs.Q[0] = m_regs.Q[1] = m_regs.Q[2] = m_regs.Q[3] = 0;
    m_nmi_state = 0;
    m_irq_state[0] = m_irq_state[1] = 0;
    m_halt = false;
    m_total_cycles = 0;
}

void z8002_device::init_tables()
{
    /* set up the zero, sign, parity lookup table */
    for (int i = 0; i < 256; i++)
        z8000_zsp[i] = ((i == 0) ? F_Z : 0) |
                        ((i & 128) ? F_S : 0) |
                        ((((i>>7)^(i>>6)^(i>>5)^(i>>4)^(i>>3)^(i>>2)^(i>>1)^i) & 1) ? 0 : F_PV);

    for (const Z8000_init *opc = table; opc->size; opc++)
        for (int val = opc->beg; val <= opc->end; val += opc->step)
            z8000_exec[val] = opc - table;
}

void z8002_device::reset()
{
    clear_internal_state();
    m_irq_req |= Z8000_RESET;
    m_refresh &= 0x7fff;
    m_halt = false;
    m_mi = CLEAR_LINE;
}

void z8002_device::trace_instruction()
{
    // Create a data buffer from program memory bus for the disassembler
    data_buffer opcodes;
    if (m_program_bus) {
        opcodes.set_bus(m_program_bus);
    }

    // Disassemble the instruction
    // Use full address (with segment for Z8001) so the bus reads from
    // the correct segment and the disassembler sees the right opcodes.
    std::ostringstream stream;
    offs_t pc = m_ppc;  // Full address including segment
    offs_t result = m_disasm->disassemble(stream, pc, opcodes, opcodes);
    offs_t size = result & 0x0FFFFFFF;  // Mask off STEP_* flags

    // Print PC and opcode bytes
    if (get_segmented_mode() && (pc >> 16)) {
        printf("<<%X>>%04X:", (pc >> 16) & 0x7F, pc & 0xFFFF);
    } else {
        printf("PC=%04X:", pc & 0xFFFF);
    }
    for (offs_t i = 0; i < size; i += 2) {
        if (m_program_bus) {
            printf(" %04X", m_program_bus->read_word(pc + i));
        }
    }

    // Pad for alignment (max 3 words = 6 bytes)
    for (offs_t i = size; i < 6; i += 2) {
        printf("     ");
    }

    // Print disassembly
    printf("  %s\n", stream.str().c_str());
}

int z8002_device::step()
{
    if (!m_program_bus || !m_io_bus) return -1;

    if (m_irq_req)
        Interrupt();

    if (m_halt)
        return 0;

    m_ppc = m_pc;

    m_op[0] = RDOP();
    m_op_valid = 1;

    if (m_trace)
        trace_instruction();

    const Z8000_init &exec = table[z8000_exec[m_op[0]]];
    int cycles = exec.cycles;
    m_total_cycles += cycles;
    (this->*exec.opcode)();
    m_op_valid = 0;

    if (m_reg_trace)
        dump_regs();

    return cycles;
}

void z8002_device::run(int max_cycles)
{
    if (!m_program_bus) {
        fprintf(stderr, "Error: No program memory attached to CPU\n");
        return;
    }
    if (!m_io_bus) {
        fprintf(stderr, "Error: No I/O attached to CPU\n");
        return;
    }

    const bool unlimited = max_cycles < 0;
    do {
        // Keep the per-slice counter bounded because opcode handlers adjust it
        // directly.  Unlimited mode simply starts another slice until HALT.
        m_icount = unlimited ? 1000000 : max_cycles;

        do
        {
            /* any interrupt request pending? */
            if (m_irq_req)
                Interrupt();

            m_ppc = m_pc;

            if (m_halt)
            {
                m_icount = 0;
            }
            else
            {
                m_op[0] = RDOP();
                m_op_valid = 1;

                if (m_trace)
                    trace_instruction();

                const Z8000_init &exec = table[z8000_exec[m_op[0]]];

                m_icount -= exec.cycles;
                m_total_cycles += exec.cycles;
                (this->*exec.opcode)();
                m_op_valid = 0;

                if (m_reg_trace) {
                    dump_regs();
                }
            }
        } while (m_icount > 0 && !m_halt);
    } while (unlimited && !m_halt);
}

void z8002_device::dump_regs() const
{
    printf("\n=== Z8002 Registers ===\n");
    printf("PC=%04X  FCW=%04X  PSAP=%04X  NSP=%04X\n",
           m_pc & 0xFFFF, m_fcw, m_psapoff, m_nspoff);
    printf("Flags: %c%c%c%c%c%c\n",
           (m_fcw & F_C) ? 'C' : '-',
           (m_fcw & F_Z) ? 'Z' : '-',
           (m_fcw & F_S) ? 'S' : '-',
           (m_fcw & F_PV) ? 'V' : '-',
           (m_fcw & F_DA) ? 'D' : '-',
           (m_fcw & F_H) ? 'H' : '-');
    printf("\n");
    for (int i = 0; i < 16; i += 4) {
        printf("R%-2d=%04X  R%-2d=%04X  R%-2d=%04X  R%-2d=%04X\n",
               i, get_reg(i),
               i+1, get_reg(i+1),
               i+2, get_reg(i+2),
               i+3, get_reg(i+3));
    }
}

void z8001_device::dump_regs() const
{
    printf("\n=== Z8001 Registers ===\n");
    printf("PC=<<%02X>>%04X  FCW=%04X  PSAP=<<%02X>>%04X  NSP=<<%02X>>%04X\n",
           (m_pc >> 16) & 0x7F, m_pc & 0xFFFF, m_fcw,
           m_psapseg & 0x7F, m_psapoff,
           m_nspseg & 0x7F, m_nspoff);
    printf("Flags: %c%c%c%c%c%c%c\n",
           (m_fcw & F_SEG) ? 'G' : '-',
           (m_fcw & F_C) ? 'C' : '-',
           (m_fcw & F_Z) ? 'Z' : '-',
           (m_fcw & F_S) ? 'S' : '-',
           (m_fcw & F_PV) ? 'V' : '-',
           (m_fcw & F_DA) ? 'D' : '-',
           (m_fcw & F_H) ? 'H' : '-');
    printf("\n");
    for (int i = 0; i < 16; i += 4) {
        printf("R%-2d=%04X  R%-2d=%04X  R%-2d=%04X  R%-2d=%04X\n",
               i, get_reg(i),
               i+1, get_reg(i+1),
               i+2, get_reg(i+2),
               i+3, get_reg(i+3));
    }
}
