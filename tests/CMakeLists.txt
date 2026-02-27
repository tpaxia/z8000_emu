set(Z8K_PREFIX "z8k-coff-" CACHE STRING "Z8K cross-toolchain prefix")
set(Z8K_AS "${Z8K_PREFIX}as")
set(Z8K_LD "${Z8K_PREFIX}ld")
set(Z8K_OBJCOPY "${Z8K_PREFIX}objcopy")

add_custom_target(assemble-tests
  COMMENT "Building regression test binary..."
  COMMAND ${Z8K_AS} -z8002 -o ${CMAKE_CURRENT_BINARY_DIR}/test_instructions.o ${CMAKE_CURRENT_SOURCE_DIR}/test_instructions.s
  COMMAND ${Z8K_LD} -Ttext=0x0100 -o ${CMAKE_CURRENT_BINARY_DIR}/test_instructions.coff ${CMAKE_CURRENT_BINARY_DIR}/test_instructions.o
  COMMAND ${Z8K_OBJCOPY} -O binary ${CMAKE_CURRENT_BINARY_DIR}/test_instructions.coff ${CMAKE_CURRENT_BINARY_DIR}/test_instructions_raw.bin
  COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/create_test_bin.sh
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)

add_custom_target(run-regression-tests
  COMMENT "Running regression tests..."
  COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/run_regression.sh
  DEPENDS z8000emu
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)
add_dependencies(run-regression-tests assemble-tests)
