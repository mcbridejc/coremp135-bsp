#!/usr/bin/env bash

#
# atf_image extracts the ATF binary image from DTB_FILE_NAME that appears in
# BR2_TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_VARIABLES in ${BR_CONFIG},
# then prints the corresponding file name for the genimage
# configuration file
#
atf_image()
{
	local ATF_VARIABLES="$(sed -n 's/^BR2_TARGET_ARM_TRUSTED_FIRMWARE_ADDITIONAL_VARIABLES="\(.*\)"$/\1/p' ${BR2_CONFIG})"

	local DTB_NAME="$(sed -n 's/.*DTB_FILE_NAME=\([^ ]*\)/\1/p' <<< ${ATF_VARIABLES})"
	local STM_NAME="tf-a-$(cut -f1 -d'.' <<< ${DTB_NAME}).stm32"
	echo ${STM_NAME}
}

main()
{
	local ATFBIN="$(atf_image)"
	if [ ! -e ${BINARIES_DIR}/${ATFBIN} ]; then
		echo "Can not find ATF binary ${ATFBIN}"
		exit 1
	fi
	local GENIMAGE_CFG="$(mktemp --suffix genimage.cfg)"
	local GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"
	local SCRIPT_PATH=$(dirname "$0")

	sed -e "s/%ATFBIN%/${ATFBIN}/" \
		${SCRIPT_PATH}/genimage.cfg > ${GENIMAGE_CFG}

	support/scripts/genimage.sh -c ${GENIMAGE_CFG}

	rm -f ${GENIMAGE_CFG}

	sed -e "s/%ATFBIN%/${ATFBIN}/" \
		${SCRIPT_PATH}/flash.tsv > ${BINARIES_DIR}/flash.tsv

	exit $?
}


set -e

RAUC_CERT_PATH=${BR2_EXTERNAL_COREMP135_PATH}/rauc_keys/cert.pem
RAUC_KEY_PATH=${BR2_EXTERNAL_COREMP135_PATH}/rauc_keys/key.pem

if [ -v RAUC_CERT_PATH && -v RAUC_KEY_PATH ]; then

	mkdir -p ${BINARIES_DIR}/temp-update
	rm -f ${BINARIES_DIR}/temp-update/rootfs.ext4
	ln -L ${BINARIES_DIR}/rootfs.ext4 ${BINARIES_DIR}/temp-update/

	rm -f ${BINARIES_DIR}/temp-update/manifest.raucm
	rm -f ${BINARIES_DIR}/bundle.raucb
	cat >> ${BINARIES_DIR}/temp-update/manifest.raucm << EOF
[update]
compatible=${RAUC_COMPATIBLE:-coremp135-example}
version=${VERSION}
[bundle]
format=verity
[image.rootfs]
filename=rootfs.ext4
EOF
	${HOST_DIR}/bin/rauc --cert ${RAUC_CERT_PATH} \
	--key ${RAUC_KEY_PATH} \
	bundle ${BINARIES_DIR}/temp-update \
	${BINARIES_DIR}/bundle.raucb
else 
    echo "RAUC_CERT_PATH and RAUC_KEY_PATH are not both set, so no bundle is created"
fi

main $@
