## mask.cmake

# DO NOT modifiy codes below

# Provide your project name
project(${MASK_NAME})

# Provide your source file for compiling
# file(GLOB SOURCE_FILES
#         "*.cc"
#         "*.cpp"
#         )
aux_source_directory(. SOURCE_FILES)


add_compile_definitions(GDS_FILENAME="${GDS_FILENAME}")
add_compile_definitions(MASK_NAME="${MASK_NAME}")

set(MASK_FILENAME ${GDS_FILENAME} CACHE STRING "")

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
#set(ENV{CONAN_LOGIN_USERNAME}, ${CONAN_USER})
#set(ENV{CONAN_PASSWORD}, ${CONAN_TOKEN})

#set(CMAKE_CXX_FLAGS "-Wno-literal-suffix")
set(CMAKE_CXX_STANDARD 17)
#set(CMAKE_CXX_FLAGS_RELEASE "-DNDEBUG")
#set(CMAKE_C_FLAGS_RELEASE   "-DNDEBUG")
#set(CMAKE_EXE_LINKER_FLAGS ${CMAKE_EXE_LINKER_FLAGS} -static-libstdc++)

#set(LIBMASK_PATH "../libmaskV7")
#include_directories(${LIBMASK_PATH}/includes)
#link_directories(${LIBMASK_PATH}/libs)

#file(GLOB GDS_FILES
#        "*.gds"
#        )
#INSTALL(FILES ../libmaskV7/caps.plf
#        DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/)
#
#INSTALL(FILES ${GDS_FILES}
#        DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/)

#add_custom_target(install_${PROJECT_NAME}
#        COMMAND $(MAKE) install
#        DEPENDS ${PROJECT_NAME}
#        COMMENT "Installing ${PROJECT_NAME}")


# Download automatically, you can also just copy the conan.cmake file
if(NOT EXISTS "${CMAKE_BINARY_DIR}/conan.cmake")
    message(STATUS "Downloading conan.cmake from https://github.com/conan-io/cmake-conan")
    file(DOWNLOAD "https://raw.githubusercontent.com/conan-io/cmake-conan/master/conan.cmake"
            "${CMAKE_BINARY_DIR}/conan.cmake")
endif()

include(${CMAKE_BINARY_DIR}/conan.cmake)
conan_check()
conan_add_remote(NAME masklayout INDEX 1
        URL ${MASK_URL}
        VERIFY_SSL True)

#execute_process(COMMAND ${CONAN_CMD} user --clean)
execute_process(COMMAND ${CONAN_CMD} user ${MASK_USER} -r=masklayout -p ${MASK_SECRET} OUTPUT_VARIABLE OUTPUTV ERROR_VARIABLE OUTPUTV)
message(STATUS ${OUTPUTV})
execute_process(COMMAND ${CONAN_CMD} remote disable conan-center OUTPUT_VARIABLE OUTPUTV ERROR_VARIABLE OUTPUTV)
message(STATUS ${OUTPUTV})


conan_cmake_run(REQUIRES
        ${PDK_NAME}/${PDK_VERSION}@cmalips/stable
        BASIC_SETUP
        UPDATE
        BUILD missing)




file(GLOB COPY_FILES
        "*.gds"
        "${CONAN_LIBMASK_ROOT}/*.plf"
        "*.plf"
        )
# message("${CONAN_LIBMASK_ROOT}/*.plf")
file(COPY ${COPY_FILES} DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/)
file(COPY ${COPY_FILES} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/bin)



add_executable(${PROJECT_NAME} ${SOURCE_FILES})
target_link_libraries(${PROJECT_NAME} ${CONAN_LIBS} "-static")

# set_target_properties(${PROJECT_NAME} 
#                      PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
#                      )

add_custom_target(Generate_GDS
        COMMAND $<TARGET_FILE:${PROJECT_NAME}>
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        DEPENDS ${PROJECT_NAME}
        COMMENT "Generate ${GDS_FILENAME}")
