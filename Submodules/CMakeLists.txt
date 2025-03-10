cmake_minimum_required(VERSION 3.16.9)
project("rpcsx-ios")

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_POSITION_INDEPENDENT_CODE on)
set(DEPLOYMENT_TARGET "16.0")

# set(FFMPEG_VERSION 5.1)
set(LLVM_VERSION 19.1.6)

set(VCPKG_PATH "vcpkg_installed/arm64-ios")
set(CMAKE_TOOLCHAIN_FILE "vcpkg/scripts/buildsystems/vcpkg.cmake" CACHE PATH "vcpkg toolchain file")
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "ios.toolchain.cmake" CACHE PATH "ios toolchain file")
set(PLATFORM OS64)

# if (TEST_OVERRIDE_CPU)
#     if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
#         set(ARCH_FLAGS "-mcpu=cortex-a53")
#     else()
#         set(ARCH_FLAGS "-mno-avx")
#     endif()


#     set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${ARCH_FLAGS}")
#     set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${ARCH_FLAGS}")
#     set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${ARCH_FLAGS}")
#     set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${ARCH_FLAGS}")
# endif()

# if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
    set(RPCS3_DOWNLOAD_ARCH "iphoneos")
# else()
    # set(RPCS3_DOWNLOAD_ARCH "x86-64")
# endif()


function(import_ffmpeg_library name)
    # add_custom_target(ffmpeg-unpack-${name} DEPENDS "${VCPKG_PATH}/lib/lib${name}.a")
    add_library(ffmpeg::${name} STATIC IMPORTED GLOBAL)
    set_property(TARGET ffmpeg::${name} PROPERTY IMPORTED_LOCATION "${VCPKG_PATH}/lib/lib${name}.a")
    set_property(TARGET ffmpeg::${name} PROPERTY INTERFACE_INCLUDE_DIRECTORIES "${FFMPEG_PATH}/include")
    add_dependencies(ffmpeg::${name} ffmpeg-unpack-${name})
endfunction()

link_directories(${VCPKG_PATH}/lib)

import_ffmpeg_library(avcodec)
import_ffmpeg_library(avformat)
import_ffmpeg_library(avfilter)
import_ffmpeg_library(avdevice)
import_ffmpeg_library(avutil)
import_ffmpeg_library(swscale)
import_ffmpeg_library(swresample)

add_library(3rdparty_ffmpeg INTERFACE)
target_link_libraries(3rdparty_ffmpeg INTERFACE
    ffmpeg::avformat
    ffmpeg::avcodec
    ffmpeg::avutil
    ffmpeg::swscale
    ffmpeg::swresample
)

add_dependencies(3rdparty_ffmpeg ffmpeg-unpack)

set(LLVM_DIR ${CMAKE_CURRENT_LIST_DIR}/LLVM-${RPCS3_DOWNLOAD_ARCH}/lib/cmake/llvm)

if (NOT EXISTS ${LLVM_DIR})
    message(STATUS "Downloading llvm-${LLVM_VERSION}")
    file(DOWNLOAD
        https://github.com/XITRIX/LLVM-On-iOS/releases/download/v${LLVM_VERSION}/LLVM-${RPCS3_DOWNLOAD_ARCH}.zip
        ${CMAKE_CURRENT_LIST_DIR}/llvm-${LLVM_VERSION}.zip
        SHOW_PROGRESS
    )

    message(STATUS "Unpacking llvm-${LLVM_VERSION}")
    execute_process(
        COMMAND unzip ${CMAKE_CURRENT_LIST_DIR}/llvm-${LLVM_VERSION}.zip
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    )
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xzf ${CMAKE_CURRENT_LIST_DIR}/LLVM-${RPCS3_DOWNLOAD_ARCH}.tar.xz
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    )

    message(STATUS "Applying llvm-${LLVM_VERSION} patch")
    execute_process(
        COMMAND cp ${CMAKE_CURRENT_LIST_DIR}/patch/LLVMExports.cmake ${CMAKE_CURRENT_LIST_DIR}/LLVM-iphoneos/lib/cmake/llvm
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    )

    message(STATUS "Removing llvm-${LLVM_VERSION} files")
    execute_process(
        COMMAND rm ${CMAKE_CURRENT_LIST_DIR}/llvm-19.1.6.zip ${CMAKE_CURRENT_LIST_DIR}/LLVM-iphoneos.tar.xz
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    )
    
endif()

set(VULKAN_SDK ${CMAKE_CURRENT_LIST_DIR}/MoltenVK)
set(Vulkan_LIBRARY ${VULKAN_SDK}/dynamic/MoltenVK.xcframework/ios-arm64/MoltenVK.framework/MoltenVK)

set(WITH_RPCSX off)
set(WITH_RPCS3 on)
set(USE_SYSTEM_LIBUSB off)
set(USE_SYSTEM_CURL off)
set(USE_DISCORD_RPC off)
set(USE_SYSTEM_OPENCV off)
set(USE_SYSTEM_FFMPEG off)
set(USE_FAUDIO off)
set(USE_SDL2 off)
set(BUILD_LLVM off)
set(STATIC_LINK_LLVM on)
set(DISABLE_LTO on)
set(USE_LTO off)
set(USE_OPENSL off)
set(ASMJIT_NO_SHM_OPEN on)
set(USE_SYSTEM_ZLIB on)
set(USE_LIBEVDEV off)
set(COMPILE_FFMPEG off)
set(USE_SYSTEM_MVK on)
set(USE_AUDIOUNIT off)
set(WITHOUT_OPENGL on)

add_subdirectory(rpcs3 EXCLUDE_FROM_ALL)

add_library(${CMAKE_PROJECT_NAME} SHARED
    native-lib.mm
)

target_include_directories(${CMAKE_PROJECT_NAME} PUBLIC rpcs3/rpcs3)

target_link_libraries(${CMAKE_PROJECT_NAME}
    rpcs3
    rpcsx::fw::ps3
    ${CMAKE_SOURCE_DIR}/LLVM-iphoneos/llvm.a
    ${CMAKE_SOURCE_DIR}/MoltenVK/static/MoltenVK.xcframework/ios-arm64/libMoltenVK.a
    "-framework CoreMedia"
    "-framework CoreVideo"
    "-framework CoreGraphics"
    "-framework QuartzCore"
    "-framework UIKit"
    "-framework IOSurface"
    "-framework Metal"
    "-framework VideoToolbox"
)