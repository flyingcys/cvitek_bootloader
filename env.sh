#!/bin/bash

MILKV_BOARD_ARRAY=
MILKV_BOARD_ARRAY_LEN=
MILKV_BOARD=
MILKV_BOARD_CONFIG=
MILKV_IMAGE_CONFIG=
MILKV_DEFAULT_BOARD=milkv-duo
COUNTRY=China

function get_country()
{
	restult=$(curl -m 10 -s http://www.ip-api.com/json)
	COUNTRY=$(echo $restult | sed 's/.*"country":"\([^"]*\)".*/\1/')
	echo "Country: $COUNTRY"
}

function get_available_board()
{
	MILKV_BOARD_ARRAY=( $(find device -mindepth 1 -maxdepth 1 -not -path 'device/common' -type d -print ! -name "." | awk -F/ '{ print $NF }' | sort -t '-' -k2,2) )
	# echo ${MILKV_BOARD_ARRAY[@]}

	MILKV_BOARD_ARRAY_LEN=${#MILKV_BOARD_ARRAY[@]}
	if [ $MILKV_BOARD_ARRAY_LEN -eq 0 ]; then
		echo "No available config"
		exit 1
	fi

	# echo ${MILKV_BOARD_ARRAY[@]} | xargs -n 1 | sed "=" | sed "N;s/\n/. /"
}

function choose_board()
{
	echo "Select a target to build:"

	echo ${MILKV_BOARD_ARRAY[@]} | xargs -n 1 | sed "=" | sed "N;s/\n/. /"

	local index
	read -p "Which would you like: " index

	if [[ -z $index ]]; then
		echo "Nothing selected."
		exit 0
	fi

	if [[ -n $index && $index =~ ^[0-9]+$ && $index -ge 1 && $index -le $MILKV_BOARD_ARRAY_LEN ]]; then
		MILKV_BOARD="${MILKV_BOARD_ARRAY[$((index - 1))]}"
		#echo "index: $index, Board: $MILKV_BOARD"
	else
		echo "Invalid input!"
		exit 1
	fi
}

function prepare_env()
{
  source ${MILKV_BOARD_CONFIG}

  source build/${MV_BUILD_ENV} > /dev/null 2>&1
  defconfig ${MV_BOARD_LINK} > /dev/null 2>&1

  echo "OUTPUT_DIR: ${OUTPUT_DIR}"  # @build/milkvsetup.sh

  if [ "${STORAGE_TYPE}" == "sd" ]; then
    MILKV_IMAGE_CONFIG=device/${MILKV_BOARD}/genimage.cfg

    if [ ! -f ${MILKV_IMAGE_CONFIG} ]; then
      echo "${MILKV_IMAGE_CONFIG} not found!"
      exit 1
    fi
  fi
}

function build_info()
{
  echo "Target Board: ${MILKV_BOARD}"
  echo "Target Board Storage: ${STORAGE_TYPE}"
  echo "Target Board Config: ${MILKV_BOARD_CONFIG}"
  if [ "${STORAGE_TYPE}" == "sd" ]; then
    echo "Target Image Config: ${MILKV_IMAGE_CONFIG}"
  fi
}

function get_build_board()
{
	get_available_board

	if [ $# -ge 1 ]; then
	    if [ "$1" = "lunch" ]; then
		    choose_board || exit 0
	    else
		    if [[ ${MILKV_BOARD_ARRAY[@]} =~ (^|[[:space:]])"${1}"($|[[:space:]]) ]]; then
		        MILKV_BOARD=${1}
		        echo "$MILKV_BOARD"
	        else
		        echo "${1} not supported!"
		        echo "Available boards: [ ${MILKV_BOARD_ARRAY[@]} ]"
		        exit 1
		    fi
	    fi

	else
		choose_board || exit 0
	fi

	MILKV_BOARD_CONFIG=device/${MILKV_BOARD}/boardconfig.sh

	if [ ! -f ${MILKV_BOARD_CONFIG} ]; then
		echo "${MILKV_BOARD_CONFIG} not found!"
		exit 1
	fi

	prepare_env
}

function get_toolchain()
{
  if [ ! -d host-tools ]; then
    echo "Toolchain does not exist, download it now..."

    toolchain_url="https://sophon-file.sophon.cn/sophon-prod-s3/drive/23/03/07/16/host-tools.tar.gz"

    echo "toolchain_url: ${toolchain_url}"
    toolchain_file=${toolchain_url##*/}
    echo "toolchain_file: ${toolchain_file}"

    wget ${toolchain_url} -O ${toolchain_file}
    if [ $? -ne 0 ]; then
      echo "Failed to download ${toolchain_url} !"
      exit 1
    fi

    if [ ! -f ${toolchain_file} ]; then
      echo "${toolchain_file} not found!"
      exit 1
    fi

    echo "Extracting ${toolchain_file}..."
    tar -xf ${toolchain_file}
    if [ $? -ne 0 ]; then
      echo "Extract ${toolchain_file} failed!"
      exit 1
    fi

    [ -f ${toolchain_file} ] && rm -rf ${toolchain_file}

  fi
}

function do_build()
{
	get_toolchain

	source build/milkvsetup.sh

	clean_all
	build_fsbl
}

function do_combine()
{
	BLCP_IMG_RUNADDR=0x05200200
	BLCP_PARAM_LOADADDR=0
	NAND_INFO=00000000
	NOR_INFO='FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'
	FIP_COMPRESS=lzma

	BUILD_PLAT=fsbl/build/${MV_BOARD_LINK}

	CHIP_CONF_PATH=${BUILD_PLAT}/chip_conf.bin
	DDR_PARAM_TEST_PATH=fsbl/test/cv181x/ddr_param.bin
	BLCP_PATH=fsbl/test/empty.bin

	MONITOR_PATH=opensbi/build/platform/generic/firmware/fw_dynamic.bin
	LOADER_2ND_PATH=u-boot-2021.10/build/${MV_BOARD_LINK}/u-boot-raw.bin

	echo "Combining fip.bin..."
	. ./fsbl/build/${MV_BOARD_LINK}/blmacros.env && \
	./fsbl/plat/cv180x/fiptool.py -v genfip \
	${BUILD_PLAT}/fip.bin \
	--MONITOR_RUNADDR="${MONITOR_RUNADDR}" \
	--BLCP_2ND_RUNADDR="${BLCP_2ND_RUNADDR}" \
	--CHIP_CONF=${CHIP_CONF_PATH} \
	--NOR_INFO=${NOR_INFO} \
	--NAND_INFO=${NAND_INFO} \
	--BL2=${BUILD_PLAT}/bl2.bin \
	--BLCP_IMG_RUNADDR=${BLCP_IMG_RUNADDR} \
	--BLCP_PARAM_LOADADDR=${BLCP_PARAM_LOADADDR} \
	--BLCP=${BLCP_PATH} \
	--DDR_PARAM=${DDR_PARAM_TEST_PATH} \
	--BLCP_2ND=${BLCP_2ND_PATH} \
	--MONITOR=${MONITOR_PATH} \
	--LOADER_2ND=${LOADER_2ND_PATH} \
	--compress=${FIP_COMPRESS}

	cp -rf ${BUILD_PLAT}/fip.bin install/soc_${MV_BOARD_LINK}/fip.bin
}