cmake_minimum_required(VERSION 3.10)
project(kogutopedia LANGUAGES CXX)

set(BINARY_NAME "kogutopedia")
set(APPLICATION_ID "com.wegiel360.kogutopedia")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

configure_file(
    "${CMAKE_SOURCE_DIR}/linux/flutter/CMakeLists.txt"
    "${CMAKE_BINARY_DIR}/flutter/CMakeLists.txt"
    COPYONLY
)

add_subdirectory(
    "${FLUTTER_MANAGED_DIRECTORY}"
    "${CMAKE_BINARY_DIR}/flutter"
)

add_executable(${BINARY_NAME}
    "my_application/my_application.cc"
    "flutter/generated_plugin_registrant.cc"
)

target_link_libraries(${BINARY_NAME} PRIVATE flutter)

target_include_directories(${BINARY_NAME} PRIVATE "${PROJECT_SOURCE_DIR}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
