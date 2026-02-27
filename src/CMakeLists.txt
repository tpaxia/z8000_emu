add_executable(z8000emu main.cpp)
target_link_libraries(z8000emu PRIVATE z8000)
install(TARGETS z8000emu)
