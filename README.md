# MaskFiles - Libmask Build System (Conan 2)

This directory contains the core CMake build system for Libmask projects and PDK development, modernized for **Conan 2** and **CMake 3.28+**.

## Files

- **`mask.cmake`** - Core build system for mask layout projects
- **`pdk.cmake`** - PDK development and packaging system

## Quick Start

### 1. Simple Mask Project (No PDK Development)

Your `CMakeLists.txt`:
```cmake
cmake_minimum_required(VERSION 3.28)
project("MyMask")

set(MASK_GDS_FILENAME "my_mask.gds")
set(MASK_TOPCELL_NAME "my_mask")
set(MASK_FILES "mask_main.cpp")

set(TEST_GDS_FILENAME "test.gds")
set(TEST_TOPCELL_NAME "TEST")
set(TEST_FILES "test_main.cpp")

set(MASK_URL "https://your-conan-server.com")
set(MASK_USER "your_user")
set(MASK_SECRET "your_password")
set(MASK_KIT_VERSION "7.6")

# PDK dependencies (optional)
set(PDK_REQUIRED 
    # "some_pdk/1.0@owner/stable"
)

include(path/to/mask.cmake)
```

Build workflow:
```bash
# 1. Create conanfile.txt (done automatically by mask.cmake)
# 2. Install dependencies
cd build
conan install . --build=missing

# 3. Configure and build
cmake -S .. -B . -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake
cmake --build .

# 4. Run
./output/MASK_GDS
./output/TEST_GDS
```

### 2. PDK Development Mode

Your `CMakeLists.txt`:
```cmake
cmake_minimum_required(VERSION 3.28)
project("MyPDK")

# ... (same as above, plus:)

set(PDK_NAME            "my_pdk")
set(PDK_VERSION         "1.0")
set(PDK_OWNER           "your_name")
set(PDK_FOUNDRY         "foundry_name")
set(PDK_AUTHOR          "Your Name <email@example.com>")
set(PDK_DESCRIPTION     "My custom PDK")
set(MASK_KIT_VERSION    "7.6")

include(path/to/mask.cmake)
```

Build and upload:
```bash
# Build PDK library
cd build
conan install . --build=missing
cmake -S .. -B . -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake
cmake --build .

# Upload to Conan server
cmake --build . --target upload_PDK
```

## Key Changes from Legacy System

### ✅ Conan 2 Migration

| Old (Conan 1.x) | New (Conan 2.x) |
|-----------------|-----------------|
| `conan.cmake` wrapper | Native `conan install` + `CMakeToolchain` |
| `conan_cmake_run()` | `find_package(libmask)` |
| `${CONAN_LIBS}` | `libmask::libmask` target |
| Legacy `conans` module | Modern `conan` module |
| `generators = "cmake"` | `generators = CMakeDeps, CMakeToolchain` |

### ✅ Modern CMake Practices

- **Imported Targets**: Use `libmask::libmask` instead of `${CONAN_LIBS}`
- **Target Properties**: `target_link_libraries(PRIVATE/PUBLIC)` with proper visibility
- **C++23**: Standard set to `CMAKE_CXX_STANDARD 23`
- **Generator Expressions**: Support for multi-config generators

### ✅ Workflow Changes

**Old workflow:**
```bash
cmake -S . -B build
cmake --build build  # Conan runs automatically
```

**New workflow:**
```bash
cd build
conan install . --build=missing  # Explicit step
cmake -S .. -B . -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake
cmake --build .
```

## Generated Files

### `conanfile.txt` (by mask.cmake)

Automatically generated in build directory:
```ini
[requires]
libmask/7.6@user/stable
# + any PDK_REQUIRED packages

[generators]
CMakeDeps
CMakeToolchain

[options]
libmask/*:shared=False
```

### `conanfile.py` (by pdk.cmake, PDK mode only)

Generated for PDK packaging:
```python
from conan import ConanFile
from conan.tools.files import copy

class PdkConan(ConanFile):
    name = "my_pdk"
    version = "1.0"
    # ... modern Conan 2 recipe
```

## Variables Reference

### Required Variables (set in your CMakeLists.txt)

| Variable | Description | Example |
|----------|-------------|---------|
| `MASK_GDS_FILENAME` | Output mask GDS filename | `"mask.gds"` |
| `MASK_TOPCELL_NAME` | Top cell name for mask | `"MASK_TOP"` |
| `MASK_FILES` | Mask source file(s) | `"mask_main.cpp"` |
| `TEST_GDS_FILENAME` | Test GDS filename | `"test.gds"` |
| `TEST_TOPCELL_NAME` | Top cell name for test | `"TEST_TOP"` |
| `TEST_FILES` | Test source file(s) | `"test_main.cpp"` |
| `MASK_KIT_VERSION` | Libmask version to use | `"7.6"` |

### Server Configuration (optional)

| Variable | Description | Default |
|----------|-------------|---------|
| `MASK_URL` | Conan server URL | `https://fnmlz9lk-9300.usw3.devtunnels.ms` |
| `MASK_USER` | Conan username | `"cmalips"` |
| `MASK_SECRET` | Conan password | `"cmalips"` |

### PDK Development Variables (optional)

| Variable | Description | Required for PDK |
|----------|-------------|------------------|
| `PDK_NAME` | PDK package name | ✅ |
| `PDK_VERSION` | PDK version | ✅ |
| `PDK_OWNER` | Package owner | ✅ |
| `PDK_FOUNDRY` | Package channel | ✅ |
| `PDK_AUTHOR` | Author info | ✅ |
| `PDK_DESCRIPTION` | Package description | ✅ |
| `PDK_REQUIRED` | List of dependencies | ❌ |

### Auto-Set Variables (used by mask.cmake/pdk.cmake)

| Variable | Description |
|----------|-------------|
| `MASK_SOURCE_FILES_DIR` | `${CMAKE_CURRENT_SOURCE_DIR}/src` |
| `PDK_SOURCE_FILES_DIR` | `${CMAKE_CURRENT_SOURCE_DIR}/src/components` |
| `RESOURCE_FILES_DIR` | `${CMAKE_CURRENT_SOURCE_DIR}/res` |
| `OUTPUT_DIR` | `${CMAKE_SOURCE_DIR}/output/` |

## Directory Structure

Expected project layout:
```
MyProject/
├── CMakeLists.txt
├── src/
│   ├── mask_main.cpp       # MASK_FILES
│   ├── test_main.cpp       # TEST_FILES
│   └── components/         # PDK development (optional)
│       └── my_component.cpp
├── res/                    # Resource files
│   └── ...
└── build/
    ├── conanfile.txt       # Auto-generated
    ├── conan_toolchain.cmake  # From conan install
    └── output/             # Executables go here
```

## Targets

### Simple Mode (no PDK_NAME)
- **`MASK_GDS`** - Main mask executable
- **`TEST_GDS`** - Test executable

### PDK Development Mode (PDK_NAME defined)
- **`${PDK_NAME}`** - PDK static library
- **`MASK_GDS`** - Mask executable (links PDK)
- **`TEST_GDS`** - Test executable (links PDK)
- **`export_${PDK_NAME}`** - Install PDK locally
- **`upload_PDK`** - Create and upload Conan package

## Troubleshooting

### Error: "Conan dependencies not installed"
**Solution:** Run `conan install` before CMake:
```bash
cd build
conan install . --build=missing
```

### Error: "libmask package not found"
**Solution:** Add Conan remote and authenticate:
```bash
conan remote add masklayout https://your-server.com
conan remote login masklayout your_user -p your_password
```

### Error: "conan_toolchain.cmake not found"
**Solution:** Use `-DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake` when configuring:
```bash
cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake
```

## Migration Guide (Legacy → Modern)

### 1. Update CMakeLists.txt
- No major changes needed - variable names stay the same!
- Optional: Add `LANGUAGES C CXX` to `project()`
- Update `mask.cmake` download URL to release_7.6 branch

### 2. Change Build Workflow
Replace:
```bash
cmake -S . -B build && cmake --build build
```

With:
```bash
cd build
conan install . --build=missing
cmake -S .. -B . -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake
cmake --build .
```

### 3. Update CI/CD
If you have automation:
```yaml
- name: Install dependencies
  run: |
    cd build
    conan install . --build=missing

- name: Configure
  run: cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=build/conan_toolchain.cmake

- name: Build
  run: cmake --build build
```

## Additional Resources

- **Conan 2 Documentation**: https://docs.conan.io/2/
- **CMake Documentation**: https://cmake.org/cmake/help/latest/
- **Libmask Repository**: https://github.com/yuanliuus/Libmask
- **Example Projects**: See `Mask_Template/` and `PDK_Template/` in the repository

## Support

For issues or questions:
1. Check this README
2. Review example projects
3. Contact: lewisyuan@gmail.com
