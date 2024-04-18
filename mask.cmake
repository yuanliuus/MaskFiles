## mask.cmake

# DO NOT modifiy codes below
# set(${SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/sources)
# file(GLOB TEST_FILES "sources/test.cpp")

add_compile_definitions(MASK_GDS_FILENAME="${MASK_GDS_FILENAME}")
add_compile_definitions(MASK_TOPCELL_NAME="${MASK_TOPCELL_NAME}")

add_compile_definitions(TEST_GDS_FILENAME="${TEST_GDS_FILENAME}")
add_compile_definitions(TEST_TOPCELL_NAME="${TEST_TOPCELL_NAME}")

set(MASK_SOURCE_FILES_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src)
set(PDK_SOURCE_FILES_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src/components)
set(RESOURCE_FILES_DIR ${CMAKE_CURRENT_SOURCE_DIR}/res)

file(GLOB MASK_FILES ${MASK_SOURCE_FILES_DIR}/${MASK_FILES})
file(GLOB TEST_FILES ${MASK_SOURCE_FILES_DIR}/${TEST_FILES})


#FILE(READ ${CMAKE_SOURCE_DIR}/CMakeLists.txt CMAKELISTS)
#STRING(REGEX REPLACE "https://bintray.com/cmalips/libmask/download_file\\?file_path=" "https://raw.githubusercontent.com/yuanliuus/MaskFiles/master/" CMAKELISTS "${CMAKELISTS}" )
#STRING(REGEX REPLACE "from https://bintray.com/cmalips/libmask/" "..." CMAKELISTS "${CMAKELISTS}" )
#FILE(WRITE ${CMAKE_SOURCE_DIR}/CMakeLists.txt "${CMAKELISTS}")

if(NOT DEFINED MASK_URL)
    set(MASK_URL "https://gitlab.com/api/v4/projects/25869414/packages/conan")
endif()
if(NOT DEFINED MASK_USER)
    set(MASK_USER "cmalips")
    set(MASK_SECRET "nYicFZBWhHe8z7xTVzY7")
endif()

set(CMAKE_BUILD_TYPE Release)

# set(CMAKE_CXX_STANDARD 23)
# set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -lc++ -lc++abi")

# set(CMAKE_C_FLAGS "--std=c2x")
# set(CMAKE_CXX_FLAGS "--std=gnu++23")

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
# add_compile_options(-fmodules-ts)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/output/)

#set(LIBMASK_PATH "../libmaskV7")
#include_directories(${LIBMASK_PATH}/includes/)
#link_directories(${LIBMASK_PATH}/libs/)


# file(REMOVE "${CMAKE_BINARY_DIR}/conanfile.py")


# Download automatically, you can also just copy the conan.cmake file
if(NOT EXISTS "${CMAKE_BINARY_DIR}/conan.cmake")
    message(STATUS "Downloading conan.cmake from https://github.com/conan-io/cmake-conan")
    file(DOWNLOAD "https://raw.githubusercontent.com/conan-io/cmake-conan/0.18.1/conan.cmake"
            "${CMAKE_BINARY_DIR}/conan.cmake")
endif()

include(${CMAKE_BINARY_DIR}/conan.cmake)
conan_check()
conan_add_remote(NAME masklayout
        URL ${MASK_URL})
execute_process(COMMAND ${CONAN_CMD} user ${MASK_USER} -r=masklayout -p ${MASK_SECRET} OUTPUT_VARIABLE OUTPUTV ERROR_VARIABLE OUTPUTV)
message(STATUS ${OUTPUTV})
execute_process(COMMAND ${CONAN_CMD} remote disable conan-center OUTPUT_VARIABLE OUTPUTV ERROR_VARIABLE OUTPUTV)
message(STATUS ${OUTPUTV})


# # Construct the REQUIRES string
# set(REQUIRES_STR "")
# foreach(PDK IN LISTS PDK_REQUIRED)
#     string(APPEND REQUIRES_STR "${PDK} ")
# endforeach()

# # Trim the trailing space
# string(STRIP "${REQUIRES_STR}" REQUIRES_STR)

# Convert the CMake list into a semicolon-separated string, then replace semicolons with Python list syntax
if(DEFINED PDK_NAME)
    list(APPEND PDK_REQUIRED "Libmask/${MASK_KIT_VERSION}@cmalips/stable")
endif()
# message(STATUS ${PDK_REQUIRED})


file(REMOVE ${CMAKE_CURRENT_BINARY_DIR}/conanfile.py)

conan_cmake_run(REQUIRES 
        ${PDK_REQUIRED}
        BASIC_SETUP
        UPDATE
        BUILD missing
        IMPORTS "res, * -> ./bin"
        NO_OUTPUT_DIRS
        )




file(GLOB_RECURSE SOURCE_FILES
        "${MASK_SOURCE_FILES_DIR}/*.cpp"
        )
# aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/sources SOURCE_FILES)

list(REMOVE_ITEM SOURCE_FILES ${MASK_FILES})
list(REMOVE_ITEM SOURCE_FILES ${TEST_FILES})


file(GLOB COPY_FILES
        ${RESOURCE_FILES_DIR}/*
)

# foreach(PDK_NAME_FULL ${PDK_REQUIRED})
#     string(REGEX MATCH "^[^/]+" dir ${PDK_NAME_FULL})
#     string(TOUPPER "${dir}" dir)
#     # Generate a list of files in the current directory
#     file(GLOB files_in_dir "CONAN_${dir}_ROOT/resources/*")
#     # Append the files in the current directory to the main list
#     list(APPEND COPY_FILES ${files_in_dir})
# endforeach()

# file(COPY ${COPY_FILES} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/)
# file(COPY ${COPY_FILES} DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/)
# file(COPY ${COPY_FILES} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/bin)
file(COPY ${COPY_FILES} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/bin)


if(NOT DEFINED PDK_NAME)
    list(REMOVE_ITEM SOURCE_FILES "${MASK_SOURCE_FILES_DIR}/technology.cpp")
    add_executable("MASK_GDS" ${MASK_FILES} ${SOURCE_FILES})
    target_link_libraries("MASK_GDS" ${CONAN_LIBS} )
    target_include_directories("MASK_GDS" PRIVATE "${PDK_SOURCE_FILES_DIR}")
    # target_link_options("MASK_GDS" PRIVATE "--wrap=Check_Lic")
    add_executable("TEST_GDS" ${TEST_FILES} ${SOURCE_FILES})
    target_link_libraries("TEST_GDS" ${CONAN_LIBS})
    target_include_directories("TEST_GDS" PRIVATE "${PDK_SOURCE_FILES_DIR}")
    return()
endif()

if(DEFINED PDK_NAME)
    message(STATUS "Downloading pdk.cmake ...")
    # file(DOWNLOAD "https://raw.githubusercontent.com/yuanliuus/MaskFiles/master/pdk.cmake"
    #         "${CMAKE_BINARY_DIR}/pdk.cmake")
    include(${CMAKE_MASK_CMAKE_FILE_DIR}/pdk.cmake)
endif()



