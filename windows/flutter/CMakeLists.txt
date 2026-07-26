cmake_minimum_required(VERSION 3.14)
project(kogutopedia LANGUAGES CXX)

set(BINARY_NAME "kogutopedia")
set(APPLICATION_ID "com.wegiel360.kogutopedia")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

configure_file(
    "${CMAKE_SOURCE_DIR}/windows/flutter/CMakeLists.txt"
    "${CMAKE_BINARY_DIR}/flutter/CMakeLists.txt"
    COPYONLY
)

add_subdirectory(
    "${FLUTTER_MANAGED_DIRECTORY}"
    "${CMAKE_BINARY_DIR}/flutter"
)

add_executable(${BINARY_NAME} WIN32
    "flutter/generated_plugin_registrant.cc"
    "runner/win32_window.cpp"
    "runner/utils.cpp"
    "runner/runner.cpp"
    "runner/flutter_window.cpp"
)

target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)

target_include_directories(${BINARY_NAME} PRIVATE "${PROJECT_SOURCE_DIR}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
