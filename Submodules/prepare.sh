#!/bin/zsh

./vcpkg/bootstrap-vcpkg.sh
./vcpkg/vcpkg install --triplet=arm64-ios

cmake -B ./xcode -GXcode -DCMAKE_TOOLCHAIN_FILE=vcpkg/scripts/buildsystems/vcpkg.cmake \
    -DVCPKG_CHAINLOAD_TOOLCHAIN_FILE=ios.toolchain.cmake \
    -DDEPLOYMENT_TARGET=16.0 \
    -DPLATFORM=OS64 \
    -DIOS=ON