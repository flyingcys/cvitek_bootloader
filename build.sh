#!/bin/bash

USER_CMD=$1

ROOT_PATH=$(pwd)
echo $ROOT_PATH

source env.sh

get_build_board ${USER_CMD}

CHIP_ARCH_L=$(echo $CHIP_ARCH | tr '[:upper:]' '[:lower:]')

build_info

do_build

if [ -d ${ROOT_PATH}/../c906_little ]; then
    cp -rf build/output/${MV_BOARD_LINK}/cvi_board_memmap.ld ${ROOT_PATH}/../c906_little/board/script/${CHIP_ARCH_L}
fi