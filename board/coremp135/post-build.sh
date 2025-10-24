#!/bin/bash

fixup_extlinux_dtb_name()
{
	local DTB_NAME="$(sed -n 's/^BR2_LINUX_KERNEL_INTREE_DTS_NAME="\(.*\)"$/\1/p' ${BR2_CONFIG})"
	local EXTLINUX_PATH="${TARGET_DIR}/boot/extlinux/extlinux.conf"
	if [ ! -e ${EXTLINUX_PATH} ]; then
		echo "Can not find extlinux ${EXTLINUX_PATH}"
		exit 1
	fi

	sed -i -e "s/%DTB_NAME%/${DTB_NAME}/" ${EXTLINUX_PATH}
}

# Copy RAUC certificate
if [ -v RAUC_CERT_PATH ]; then
	if [ -e ${RAUC_CERT_PATH} ]; then
		install -D -m 0644 ${RAUC_CERT_PATH} ${TARGET_DIR}/etc/rauc/cert.pem
	else
		echo "RAUC CA certificate not found!"
		echo ${RAUC_CERT_PATH}
		#exit 1
	fi
else 
	echo "RAUC_CERT_PATH not set, so no certificate is being installed to target filesystem"
fi

# Create an image for the data partition
rm -rf ${BINARIES_DIR}/data.img
fallocate -l 512M ${BINARIES_DIR}/data.img

if [ -v COREMP135_EXFAT_DATA ]; then
	mkfs.exfat -L Data ${BINARIES_DIR}/data.img
	FSTAB_OPTIONS="exfat defaults,rw 0 0"
else
	mkfs.ext4 -L Data ${BINARIES_DIR}/data.img
	FSTAB_OPTIONS="ext4 defaults,data=journal,noatime 0 0"
fi
	
# Mount persistent data partition
if [ -e ${TARGET_DIR}/etc/fstab ]; then
	# For configuration data
	# WARNING: data=journal is safest, but potentially slow!
	if $(grep -qE '/dev/disk/by-label/Data' ${TARGET_DIR}/etc/fstab); then
		# replace line
		sed -i "/\/dev\/disk\/by-label\/Data/c\/dev\/disk\/by-label\/Data \/data ${FSTAB_OPTIONS}" output/target/etc/fstab
	else
		# add line
		echo "/dev/disk/by-label/Data /data ${FSTAB_OPTIONS}" >> ${TARGET_DIR}/etc/fstab	
	fi
fi


fixup_extlinux_dtb_name $@
