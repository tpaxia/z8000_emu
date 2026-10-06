# TODO

## Program Status Area reads use the wrong address space

On a trap or interrupt the emulator reads the new program status (FCW, PC
segment, PC offset) through the data space: `GET_FCW`, `GET_PC` and
`read_irq_vector` in `lib/src/z8000.cpp` all use `m_data`.

The reference part does not. A Zilog Z8001APS (date code 8425), captured on
the `z8000_test` rig on 2026-10-06 with the bus status recorded per cycle,
drives ST3-ST0 = 1100 (program reference) on these reads, which is also what
z8000.md 7.7.3 says:

    0x0EFE  0218  W  ST=1001   pushed PC offset (stack)
    0x0EFC  8000  W  ST=1001   pushed PC segment
    0x0EFA  C000  W  ST=1001   pushed FCW
    0x0EF8  7F00  W  ST=1001   pushed identifier
    0x081A  C000  R  ST=1100   new FCW
    0x081C  8000  R  ST=1100   new PC segment
    0x081E  0300  R  ST=1100   new PC offset

(`seg_sc_basic`; the same 1100 appears on all 69 PSA reads across the trap
tests of that capture.)

The code was moved to `m_data` earlier on the strength of a trace showing
ST=1000. That trace does not reproduce on this part.

To do:

- Move `GET_FCW`, `GET_PC` and `read_irq_vector` back to `m_program`.
- Check what depends on the current behaviour first. Anything that decodes
  the status lines sees the difference, a Z8010 MMU in particular, so
  machines with an MMU (S8000/ZEUS, for instance) need re-testing.
- The `z8000_test` goldens cannot confirm the change either way: the harness
  has one memory behind every space, and the emulator's test driver emits no
  bus trace. Comparing spaces needs the driver to report the space of each
  access, checked against the rig's ST field.

Not covered by any capture: the reset vector (already on `m_program`) and
the space used for the vectored-interrupt PC table.
