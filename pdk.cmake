
#PDK.cmake
set(CMAKE_INSTALL_PREFIX ${CMAKE_SOURCE_DIR}/export_pdk/)

# Add mask layout core
# list(APPEND PDK_REQUIRED "Libmask/${MASK_KIT_VERSION}@cmalips/stable")
string(REPLACE ";" "\",\"" PDK_REQUIRED_CONAN "${PDK_REQUIRED}")
set(PDK_REQUIRED_CONAN "\"${PDK_REQUIRED_CONAN}\"")
# message(STATUS ${PDK_REQUIRED_CONAN})

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
    requires = (${PDK_REQUIRED_CONAN})

    def package_id(self):
        self.info.settings.build_type = \"Any\"

    def package(self):
        self.copy(\"*.h\", dst=\"include\", src=\"${PDK_SOURCE_FILES_DIR}\", excludes=(\"*cmake-build-*\", \"*build*\"), keep_path=True)
        self.copy(\"*.a\", dst=\"lib\", src=\"lib\", keep_path=False)
        self.copy(\"*\", dst=\"res\", src=\"${RESOURCE_FILES_DIR}\", keep_path=True)

    def package_info(self):
        self.cpp_info.libs = [\"${PDK_NAME}\"] ")


file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/conanfile.py ${CONANFILE_PY})
# file(COPY conanfile.py DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/)

add_custom_command(
    OUTPUT res.o
    WORKING_DIRECTORY ${RESOURCE_FILES_DIR}
    COMMAND ld -r -b binary -o ${CMAKE_CURRENT_BINARY_DIR}/res.o *
    COMMENT "Compile resource files to res.o"
)

file(GLOB PDK_SOURCE_FILES
        "${PDK_SOURCE_FILES_DIR}/*.cpp"
        )
add_library(${PDK_NAME} STATIC ${PDK_SOURCE_FILES} res.o)
# target_compile_definitions(${PDK_NAME} PRIVATE -include ${PDK_SOURCE_FILES_DIR}/${PDK_NAME}.h)
# message(${PDK_SOURCE_FILES_DIR}/${PDK_NAME}.h)

# file(GLOB HEADER_FILES
#         "sources/*.h"
#         )
# install(TARGETS ${PDK_NAME} ARCHIVE DESTINATION lib/)
# install(FILES ${HEADER_FILES} DESTINATION include/${PDK_NAME}/)
# install(FILES ${SOURCE_FILES} DESTINATION src/${PDK_NAME}/)

add_custom_target(export_${PDK_NAME}
        # COMMAND $(MAKE) install
        DEPENDS install
        COMMENT "Exporting ${PDK_NAME}")

add_executable("MASK_GDS" ${MASK_FILES})
add_dependencies("MASK_GDS" ${PDK_NAME})
target_link_libraries("MASK_GDS" ${PDK_NAME} ${CONAN_LIBS})
target_include_directories("MASK_GDS" PUBLIC "${PDK_SOURCE_FILES_DIR}")


add_executable("TEST_GDS" ${TEST_FILES})
add_dependencies("TEST_GDS" ${PDK_NAME})
target_link_libraries("TEST_GDS" ${PDK_NAME} ${CONAN_LIBS})
target_include_directories("TEST_GDS" PUBLIC "${PDK_SOURCE_FILES_DIR}")


# foreach(dir ${CONAN_INCLUDE_DIRS})
#     set(M_D "${M_D} -I \"${dir}\"")
# endforeach()

add_custom_target(upload_PDK
#        COMMAND ${CMAKE_CXX_COMPILER} -O3 -std=gnu++17 -x c++-header ${CMAKE_CURRENT_SOURCE_DIR}/${PDK_NAME}.h ${M_D}
        # WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        COMMAND conan export-pkg . ${PDK_NAME}/${PDK_VERSION}@${PDK_OWNER}/${PDK_FOUNDRY} -f --build-folder ${CMAKE_CURRENT_BINARY_DIR}
        COMMAND conan remote add masklayout ${MASK_URL} -f
        COMMAND conan user -p ${MASK_SECRET} -r masklayout  ${MASK_USER}
        COMMAND conan upload ${PDK_NAME}/${PDK_VERSION}@${PDK_OWNER}/${PDK_FOUNDRY} -r masklayout --all
        DEPENDS ${PDK_NAME}
        COMMENT "Uploading ${PROJECT_NAME}")


# 
# 
# 
