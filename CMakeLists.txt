cmake_minimum_required(VERSION 3.16)
project(z8000_emu LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_compile_options(-Wall -Wextra)

# Add DEBUG define for Debug builds (CMake already sets -g -O0 / -O2 -DNDEBUG)
add_compile_definitions($<$<CONFIG:Debug>:DEBUG>)

# --- Library: z8000 (CPU core + disassembler) ---
add_library(z8000 STATIC
    src/z8000.cpp
    tools/8000dasm.cpp
)
target_include_directories(z8000 PUBLIC include tools)

# --- Executable: z8000emu (CLI driver) ---
add_executable(z8000emu src/main.cpp)
target_link_libraries(z8000emu PRIVATE z8000)

# =============================================================================
# Z8K cross-toolchain test targets (optional convenience targets)
# =============================================================================
set(Z8K_PREFIX "z8k-coff-" CACHE STRING "Z8K cross-toolchain prefix")
set(Z8K_AS "${Z8K_PREFIX}as")
set(Z8K_LD "${Z8K_PREFIX}ld")
set(Z8K_OBJCOPY "${Z8K_PREFIX}objcopy")

set(TESTDIR "${CMAKE_SOURCE_DIR}/test")

# assemble-test: assemble + link + extract + prepend reset vector
add_custom_target(assemble-test
    COMMENT "Building regression test binary..."
    COMMAND ${Z8K_AS} -z8002 -o ${TESTDIR}/test_instructions.o ${TESTDIR}/test_instructions.s
    COMMAND ${Z8K_LD} -Ttext=0x0100 -o ${TESTDIR}/test_instructions.coff ${TESTDIR}/test_instructions.o
    COMMAND ${Z8K_OBJCOPY} -O binary ${TESTDIR}/test_instructions.coff ${TESTDIR}/test_instructions_raw.bin
    COMMAND ${TESTDIR}/create_test_bin.sh
)

# run-regression: build emulator, assemble test, then run regression script
add_custom_target(run-regression
    COMMENT "Running regression test..."
    COMMAND ${TESTDIR}/run_regression.sh
    DEPENDS z8000emu
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
)
add_dependencies(run-regression assemble-test)
