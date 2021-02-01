#!/bin/sh

if [ $# -eq 0 ] || [ $1 != "-N" ]; then
    curl https://buildroot.org/downloads/buildroot-2020.08.1.tar.bz2 | tar xj && \
    wget -N https://github.com/raspberrypi/firmware/raw/master/boot/bcm2708-rpi-b.dtb -P buildroot-2020.08.1/output/images/
    wget -N https://github.com/raspberrypi/firmware/raw/master/boot/bootcode.bin -P buildroot-2020.08.1/output/images/
    wget -N https://github.com/raspberrypi/firmware/raw/master/boot/start_cd.elf -P buildroot-2020.08.1/output/images/
    wget -N https://github.com/raspberrypi/firmware/raw/master/boot/fixup_cd.dat -P buildroot-2020.08.1/output/images/
fi

yes | cp -f instantpi1b_defconfig buildroot*/configs && \
make -C buildroot* instantpi1b_defconfig && \
make -C buildroot* && \
yes | mv -f buildroot*/output/images/sdcard.img . && \
echo "Image built at $(pwd)/sdcard.img"
