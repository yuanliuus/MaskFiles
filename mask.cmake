## mask.cmake - Modernized for Conan 2 and CMake 3.28+

# DO NOT modify codes below unless you know what you're doing
# ============================================================================
# Compile Definitions
# ============================================================================

add_compile_definitions(MASK_GDS_FILENAME="${MASK_GDS_FILENAME}")
add_compile_definitions(MASK_TOPCELL_NAME="${MASK_TOPCELL_NAME}")

add_compile_definitions(TEST_GDS_FILENAME="${TEST_GDS_FILENAME}")
add_compile_definitions(TEST_TOPCELL_NAME="${TEST_TOPCELL_NAME}")

# ============================================================================
# Directory Configuration
# ============================================================================

set(MASK_SOURCE_FILES_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src)
set(PDK_SOURCE_FILES_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src/components)
set(RESOURCE_FILES_DIR ${CMAKE_CURRENT_SOURCE_DIR}/res)
set(OUTPUT_DIR ${CMAKE_SOURCE_DIR}/output/)

file(GLOB MASK_FILES ${MASK_SOURCE_FILES_DIR}/${MASK_FILES})
file(GLOB TEST_FILES ${MASK_SOURCE_FILES_DIR}/${TEST_FILES})

# ============================================================================
# Server Configuration
# ============================================================================

if(NOT DEFINED MASK_URL)
    set(MASK_URL "https://fnmlz9lk-9300.usw3.devtunnels.ms")
endif()
if(NOT DEFINED MASK_USER)
    set(MASK_USER "cmalips")
    set(MASK_SECRET "cmalips")
endif()

# ============================================================================
# Build Configuration
# ============================================================================

set(CMAKE_BUILD_TYPE Release)

# Modern C/C++ standards
set(CMAKE_C_STANDARD 23)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${OUTPUT_DIR})

# ============================================================================
# Conan 2 Integration
# ============================================================================

# Always require libmask bundle package
if(DEFINED PDK_NAME)
    # PDK development mode - add libmask as dependency
    list(APPEND PDK_REQUIRED "libmask/${MASK_KIT_VERSION}@${MASK_USER}/stable")
endif()

# Generate conanfile.txt for Conan 2
file(REMOVE ${CMAKE_CURRENT_BINARY_DIR}/conanfile.txt)

set(CONAN_REQUIRES_LIST "")
foreach(PKG IN LISTS PDK_REQUIRED)
    string(APPEND CONAN_REQUIRES_LIST "${PKG}\n")
endforeach()

file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/conanfile.txt
"[requires]
${CONAN_REQUIRES_LIST}
[generators]
CMakeDeps
CMakeToolchain

[options]
libmask/*:shared=False
")

message(STATUS "Generated conanfile.txt for Conan 2")
message(STATUS "Required packages: ${PDK_REQUIRED}")

# Check if Conan has already been run
if(NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/conan_toolchain.cmake)
    message(STATUS "==============================================================")
    message(STATUS "Conan 2 dependencies not found. Please run:")
    message(STATUS "  cd ${CMAKE_CURRENT_BINARY_DIR}")
    message(STATUS "  conan install . --build=missing")
    message(STATUS "Then re-run CMake configuration.")
    message(STATUS "==============================================================")
    message(FATAL_ERROR "Conan dependencies not installed. Run 'conan install' first.")
endif()

# Include Conan-generated CMake files
list(APPEND CMAKE_PREFIX_PATH ${CMAKE_CURRENT_BINARY_DIR})
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_BINARY_DIR})

# Find libmask package
find_package(libmask REQUIRED CONFIG)


# ============================================================================
# Generate CMakePresets.json for VS Code CMake Extension
# ============================================================================

# Generate CMakePresets.json in the project root for VS Code
if(NOT EXISTS ${CMAKE_SOURCE_DIR}/CMakePresets.json)
    message(STATUS "Generating CMakePresets.json for VS Code CMake Extension...")
    file(WRITE ${CMAKE_SOURCE_DIR}/CMakePresets.json
"{
    \"version\": 3,
    \"vendor\": {
        \"conan\": {}
    },
    \"cmakeMinimumRequired\": {
        \"major\": 3,
        \"minor\": 15,
        \"patch\": 0
    },
    \"configurePresets\": [
        {
            \"name\": \"conan-release\",
            \"displayName\": \"Conan Release (Ninja)\",
            \"description\": \"Release build using Ninja generator with Conan dependencies\",
            \"generator\": \"Ninja\",
            \"cacheVariables\": {
                \"CMAKE_POLICY_DEFAULT_CMP0091\": \"NEW\",
                \"CMAKE_BUILD_TYPE\": \"Release\",
                \"CMAKE_EXPORT_COMPILE_COMMANDS\": \"ON\"
            },
            \"toolchainFile\": \"\${sourceDir}/build/conan_toolchain.cmake\",
            \"binaryDir\": \"\${sourceDir}/build\"
        }
    ],
    \"buildPresets\": [
        {
            \"name\": \"conan-release\",
            \"configurePreset\": \"conan-release\",
            \"jobs\": 4
        }
    ]
}
")
    message(STATUS "✅ CMakePresets.json generated successfully")
endif()




# ============================================================================
# Source Files Collection
# ============================================================================

file(GLOB_RECURSE SOURCE_FILES
        "${MASK_SOURCE_FILES_DIR}/*.cpp"
        )

list(REMOVE_ITEM SOURCE_FILES ${MASK_FILES})
list(REMOVE_ITEM SOURCE_FILES ${TEST_FILES})

# ============================================================================
# Resource Files
# ============================================================================

file(GLOB COPY_FILES
        ${RESOURCE_FILES_DIR}/*
        "license.yml"
)

file(COPY ${COPY_FILES} DESTINATION ${OUTPUT_DIR})

# ============================================================================
# Build Targets
# ============================================================================

if(NOT DEFINED PDK_NAME)
    # Simple mask project without PDK development
    list(REMOVE_ITEM SOURCE_FILES "${MASK_SOURCE_FILES_DIR}/technology.cpp")
    
    add_executable("MASK_GDS" ${MASK_FILES} ${SOURCE_FILES})
    target_link_libraries("MASK_GDS" PRIVATE libmask::libmask)
    target_include_directories("MASK_GDS" PRIVATE "${PDK_SOURCE_FILES_DIR}")
    
    add_executable("TEST_GDS" ${TEST_FILES} ${SOURCE_FILES})
    target_link_libraries("TEST_GDS" PRIVATE libmask::libmask)
    target_include_directories("TEST_GDS" PRIVATE "${PDK_SOURCE_FILES_DIR}")
    
    message(STATUS "Configured simple mask project (no PDK development)")
    return()
endif()

if(DEFINED PDK_NAME)
    # PDK development mode
    message(STATUS "PDK development mode enabled for: ${PDK_NAME}")
    include(${CMAKE_MASK_CMAKE_FILE_DIR}/pdk.cmake)
endif()



