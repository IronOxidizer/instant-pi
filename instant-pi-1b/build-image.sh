#!/bin/sh

if [ $# -eq 0 ] || [ $1 != "-N" ]; then
    curl https://buildroot.org/downloads/buildroot-2020.08.1.tar.bz2 | tar xj
    mv buildroot* buildroot
    wget -N https://github.com/raspberrypi/firmware/raw/master/boot/bcm2708-rpi-b.dtb -P buildroot/output/images/
    wget -N https://github.com/raspberrypi/firmware/raw/master/boot/bootcode.bin -P buildroot/output/images/
    wget -N https://github.com/raspberrypi/firmware/raw/master/boot/start_cd.elf -P buildroot/output/images/
    wget -N https://github.com/raspberrypi/firmware/raw/master/boot/fixup_cd.dat -P buildroot/output/images/
fi

yes | cp -f br_instantpi1b_defconfig buildroot/configs && \
mkdir -p buildroot/output/build/linux-custom/arch/arm/configs && \
yes | cp -f linux_instantpi1b_defconfig buildroot/output/build/linux-custom/arch/arm/configs && \
make -j $(nproc) -C buildroot br_instantpi1b_defconfig && \
make -j $(nproc) -C buildroot && \
yes | mv -f buildroot/output/images/sdcard.img . && \
echo "Image built at $(pwd)/sdcard.img"

