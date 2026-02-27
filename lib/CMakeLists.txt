add_library(z8000 STATIC
  src/z8000.cpp
  src/z8000dasm.cpp
)

target_include_directories(z8000 PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}/include/
)

configure_file(libz8000.pc.in pkgconfig/libz8000.pc @ONLY)

install(TARGETS z8000 ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/pkgconfig
  DESTINATION ${CMAKE_INSTALL_LIBDIR})
