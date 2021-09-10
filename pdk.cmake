## pdk.cmake

# DO NOT modifiy codes below

file(GLOB TEST_FILES "test.cpp")
add_compile_definitions(GDS_FILENAME="${GDS_FILENAME}")
add_compile_definitions(MASK_NAME="${MASK_NAME}")

#FILE(READ ${CMAKE_SOURCE_DIR}/CMakeLists.txt CMAKELISTS)
#STRING(REGEX REPLACE "https://bintray.com/cmalips/libmask/download_file\\?file_path=" "https://raw.githubusercontent.com/yuanliuus/MaskFiles/master/" CMAKELISTS "${CMAKELISTS}" )
#STRING(REGEX REPLACE "from https://bintray.com/cmalips/libmask/" "..." CMAKELISTS "${CMAKELISTS}" )
#FILE(WRITE ${CMAKE_SOURCE_DIR}/CMakeLists.txt "${CMAKELISTS}")

set(CONAN_URL "https://gitlab.com/api/v4/projects/25869414/packages/conan")
set(CONAN_USER "cmalips")
set(CONAN_TOKEN "nYicFZBWhHe8z7xTVzY7")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_LINKER_LINKER_FLAGS "-lc++ -lc++abi")
#set(CMAKE_INSTALL_PREFIX ${CMAKE_SOURCE_DIR}/../libmaskV7/)
set(CMAKE_INSTALL_PREFIX ${CMAKE_SOURCE_DIR}/export_pdk/)

project(${PDK_NAME})


#set(LIBMASK_PATH "../libmaskV7")
#include_directories(${LIBMASK_PATH}/includes/)
#link_directories(${LIBMASK_PATH}/libs/)


file(REMOVE "${CMAKE_BINARY_DIR}/conanfile.py")


# Download automatically, you can also just copy the conan.cmake file
if(NOT EXISTS "${CMAKE_BINARY_DIR}/conan.cmake")
    message(STATUS "Downloading conan.cmake from https://github.com/conan-io/cmake-conan")
    file(DOWNLOAD "https://raw.githubusercontent.com/conan-io/cmake-conan/master/conan.cmake"
            "${CMAKE_BINARY_DIR}/conan.cmake")
endif()

include(${CMAKE_BINARY_DIR}/conan.cmake)
conan_check()
conan_add_remote(NAME libmask
        URL ${CONAN_URL})
execute_process(COMMAND ${CONAN_CMD} user ${CONAN_USER} -r=libmask -p ${CONAN_TOKEN} OUTPUT_VARIABLE OUTPUTV ERROR_VARIABLE OUTPUTV)
message(STATUS ${OUTPUTV})
conan_cmake_run(REQUIRES Libmask/${MASK_LIB_VERSION}@cmalips/stable
        BASIC_SETUP
        UPDATE
        BUILD missing)



# Generate conanfile.py
set(CONANFILE_PY "
from conans import ConanFile, CMake
class PdkConan(ConanFile):
    name = \"${PDK_NAME}\"
    version = \"${PDK_VERSION}\"
    license = \"\"
    author = \"${PDK_AUTHOR}\"
    description = \"${PDK_DESCRIPTION}\"
    settings = \"os\", \"compiler\", \"build_type\", \"arch\"
    options = {\"shared\": [True, False]}
    default_options = \"shared=False\"
    generators = \"cmake\"
    exports_sources = (\"*\", \"!build*\", \"!cmake-build-*\", \"!.*\", \"!*.gch\")
    requires = \"Libmask/${MASK_LIB_VERSION}@cmalips/stable\"

    def package_id(self):
        self.info.settings.build_type = \"Any\"

    def package(self):
        self.copy(\"*.h\", dst=\"include\", src=\".\", excludes=(\"*cmake-build-*\", \"*build*\"))
        self.copy(\"*.gch\", dst=\"include\", src=\".\", excludes=\"*cmake-build-*\")
        self.copy(\"*.a\", dst=\"lib\", src=\"lib\", keep_path=False)
        self.copy(\"*.gds\", dst=\".\", src=\".\", keep_path=False, excludes=\"*${GDS_FILENAME}\")
        self.copy(\"*.plf\", dst=\".\", src=\".\", keep_path=False)

    def package_info(self):
        self.cpp_info.libs = [\"${PDK_NAME}\"] ")


file(WRITE conanfile.py ${CONANFILE_PY})
# file(COPY conanfile.py DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/)





# file(GLOB SOURCE_FILES
#         "*.cpp"
#         )
aux_source_directory(. SOURCE_FILES)

list(REMOVE_ITEM SOURCE_FILES ${TEST_FILES})

add_library(${PDK_NAME} STATIC ${SOURCE_FILES})

file(GLOB HEADER_FILES
        "*.h"
        )
# file(COPY ${HEADER_FILES}
#         DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/)

file(GLOB COPY_FILES
        "*.gds"
        "${CONAN_LIBMASK_ROOT}/*.plf"
        "*.plf"
        "license.yml"
        )
# file(COPY ${COPY_FILES} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/)
file(COPY ${COPY_FILES} DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/)
file(COPY ${COPY_FILES} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/bin)


install(TARGETS ${PDK_NAME} ARCHIVE DESTINATION lib/)
install(FILES ${HEADER_FILES} DESTINATION include/${PDK_NAME}/)
install(FILES ${SOURCE_FILES} DESTINATION scr/${PDK_NAME}/)

add_custom_target(export_${PROJECT_NAME}
        COMMAND $(MAKE) install
        DEPENDS ${PDK_NAME}
        COMMENT "Exporting ${PROJECT_NAME}")

add_executable(test_${PROJECT_NAME} ${TEST_FILES})
ADD_DEPENDENCIES(test_${PROJECT_NAME} ${PDK_NAME})
target_link_libraries(test_${PROJECT_NAME} ${PDK_NAME} ${CONAN_LIBS})



foreach(dir ${CONAN_INCLUDE_DIRS})
    set(M_D "${M_D} -I \"${dir}\"")
endforeach()

add_custom_target(upload_PDK
#        COMMAND ${CMAKE_CXX_COMPILER} -O3 -std=gnu++17 -x c++-header ${CMAKE_CURRENT_SOURCE_DIR}/${PDK_NAME}.h ${M_D}
        COMMAND conan export-pkg ./.. ${PDK_NAME}/${PDK_VERSION}@cmalips/stable -f --build-folder ${CMAKE_CURRENT_BINARY_DIR}
        COMMAND conan remote add libmask ${CONAN_URL} -f
        COMMAND conan user -p ${CONAN_TOKEN} -r libmask  ${CONAN_USER}
        COMMAND conan upload ${PDK_NAME}/${PDK_VERSION}@cmalips/stable -r libmask --all
        DEPENDS ${PDK_NAME}
        COMMENT "Uploading ${PROJECT_NAME}")
