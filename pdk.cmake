
# PDK.cmake - Modernized for Conan 2 and CMake 3.28+
# ============================================================================

set(CMAKE_INSTALL_PREFIX ${CMAKE_SOURCE_DIR}/export_pdk/)

# ============================================================================
# Generate Conan 2 Recipe (conanfile.py)
# ============================================================================

# Convert PDK_REQUIRED list to Python format
string(REPLACE ";" "\", \"" PDK_REQUIRED_CONAN "${PDK_REQUIRED}")
set(PDK_REQUIRED_CONAN "\"${PDK_REQUIRED_CONAN}\"")

# Calculate relative paths for conanfile.py
file(RELATIVE_PATH PDK_SOURCE_FILES_DIR_REL ${CMAKE_CURRENT_SOURCE_DIR} ${PDK_SOURCE_FILES_DIR})
file(RELATIVE_PATH RESOURCE_FILES_DIR_REL ${CMAKE_CURRENT_SOURCE_DIR} ${RESOURCE_FILES_DIR})

# Generate modern Conan 2 conanfile.py
set(CONANFILE_PY "
from conan import ConanFile
from conan.tools.files import copy
import os

class PdkConan(ConanFile):
    name = \"${PDK_NAME}\"
    version = \"${PDK_VERSION}\"
    license = \"\"
    author = \"${PDK_AUTHOR}\"
    description = \"${PDK_DESCRIPTION}\"
    settings = \"os\", \"compiler\", \"build_type\", \"arch\"
    options = {\"shared\": [True, False]}
    default_options = {\"shared\": False}
    
    # Modern Conan 2 exports
    exports_sources = \"*\", \"!build*\", \"!cmake-build-*\", \"!.*\", \"!*.gch\"
    
    def requirements(self):
        # Dependencies in Conan 2 format
        reqs = [${PDK_REQUIRED_CONAN}]
        for req in reqs:
            if req:  # Skip empty strings
                self.requires(req)
    
    def package_id(self):
        # Pre-built package compatible with any build type
        del self.info.settings.build_type
    
    def package(self):
        # Package headers
        copy(self, \"*.h\", 
             src=os.path.join(self.source_folder, \"${PDK_SOURCE_FILES_DIR_REL}\"),
             dst=os.path.join(self.package_folder, \"include\"),
             keep_path=True,
             excludes=(\"*cmake-build-*\", \"*build*\"))
        
        # Package library
        copy(self, \"*.a\",
             src=os.path.join(self.build_folder, \"lib\"),
             dst=os.path.join(self.package_folder, \"lib\"),
             keep_path=False)
        
        # Package resources
        copy(self, \"*\",
             src=os.path.join(self.source_folder, \"${RESOURCE_FILES_DIR_REL}\"),
             dst=os.path.join(self.package_folder, \"res\"),
             keep_path=True)
    
    def package_info(self):
        self.cpp_info.libs = [\"${PDK_NAME}\"]
        self.cpp_info.set_property(\"cmake_file_name\", \"${PDK_NAME}\")
        self.cpp_info.set_property(\"cmake_target_name\", \"${PDK_NAME}::${PDK_NAME}\")
")

file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/conanfile.py ${CONANFILE_PY})
message(STATUS "Generated Conan 2 recipe: ${CMAKE_CURRENT_BINARY_DIR}/conanfile.py")

# ============================================================================
# Resource Embedding
# ============================================================================

add_custom_command(
    OUTPUT res.o
    WORKING_DIRECTORY ${RESOURCE_FILES_DIR}
    COMMAND ld -r -b binary -o ${CMAKE_CURRENT_BINARY_DIR}/res.o *
    COMMENT "Embedding resource files into res.o"
)

# ============================================================================
# PDK Library Target
# ============================================================================

file(GLOB PDK_SOURCE_FILES "${PDK_SOURCE_FILES_DIR}/*.cpp")

add_library(${PDK_NAME} STATIC ${PDK_SOURCE_FILES} res.o)

# Link against libmask bundle
target_link_libraries(${PDK_NAME} PUBLIC libmask::libmask)
target_include_directories(${PDK_NAME} PUBLIC "${PDK_SOURCE_FILES_DIR}")

# Install PDK library
install(TARGETS ${PDK_NAME} 
        ARCHIVE DESTINATION lib/
        LIBRARY DESTINATION lib/)

add_custom_target(export_${PDK_NAME}
        DEPENDS install
        COMMENT "Exporting ${PDK_NAME} to ${CMAKE_INSTALL_PREFIX}")

# ============================================================================
# Executable Targets
# ============================================================================

add_executable("MASK_GDS" ${MASK_FILES})
add_dependencies("MASK_GDS" ${PDK_NAME})
target_link_libraries("MASK_GDS" PRIVATE ${PDK_NAME} libmask::libmask)
target_include_directories("MASK_GDS" PUBLIC "${PDK_SOURCE_FILES_DIR}")

add_executable("TEST_GDS" ${TEST_FILES})
add_dependencies("TEST_GDS" ${PDK_NAME})
target_link_libraries("TEST_GDS" PRIVATE ${PDK_NAME} libmask::libmask)
target_include_directories("TEST_GDS" PUBLIC "${PDK_SOURCE_FILES_DIR}")



# ============================================================================
# Conan 2 Upload Target
# ============================================================================

add_custom_target(upload_PDK
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        
        # Create package using Conan 2 syntax
        COMMAND conan create ${CMAKE_SOURCE_DIR} 
                --user=${PDK_OWNER} 
                --channel=${PDK_FOUNDRY}
                --build-folder=${CMAKE_CURRENT_BINARY_DIR}
                
        # Add remote server
        COMMAND conan remote add masklayout ${MASK_URL} --force
        
        # Login to server
        COMMAND conan remote login masklayout ${MASK_USER} -p ${MASK_SECRET}
        
        # Upload package
        COMMAND conan upload ${PDK_NAME}/${PDK_VERSION}@${PDK_OWNER}/${PDK_FOUNDRY} 
                -r masklayout --all
                
        DEPENDS ${PDK_NAME}
        COMMENT "Creating and uploading ${PDK_NAME} package to Conan server")

message(STATUS "PDK configured: ${PDK_NAME} v${PDK_VERSION}")
message(STATUS "  Upload target available: make upload_PDK") 
