#!/bin/sh

if [ $# -eq 0 ] || [ $1 != "-N" ] && [ $1 != "-L" ] ; then
    curl https://buildroot.org/downloads/buildroot-2020.08.1.tar.bz2 | tar xj
    mv buildroot* buildroot
    wget -N https://github.com/raspberrypi/firmware/raw/master/boot/bcm2708-rpi-b.dtb -P buildroot/output/images/
    wget -N https://github.com/raspberrypi/firmware/raw/master/boot/bootcode.bin -P buildroot/output/images/
    wget -N https://github.com/raspberrypi/firmware/raw/master/boot/start_cd.elf -P buildroot/output/images/
    wget -N https://github.com/raspberrypi/firmware/raw/master/boot/fixup_cd.dat -P buildroot/output/images/
fi

make -j $(nproc) -C buildroot defconfig BR2_DEFCONFIG=../br_instantpi1b_defconfig && \
if [ $# -eq 0 ] || [ $1 != "-L" ] ; then
    make -j $(nproc) -C buildroot linux-dirclean
fi
make -j $(nproc) -C buildroot && \
yes | mv -f buildroot/output/images/sdcard.img . && \
echo "Image built at $(pwd)/sdcard.img"

