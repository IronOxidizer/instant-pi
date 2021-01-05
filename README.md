# instant-pi
Achieving the fastest possible boot times with various Raspberry Pi devices

When describing boot speed, we typically mean the time it takes for a device to go from un-powered to userspace. For this project, boot time will be measured from the moment the device receives power, to interactive shell with HDMI+USB+keyboard enabled. In your project this could instead be something like taking a picture, playing a video, or sending a message via WiFi or SMS.

Based on the following projects:
- [Buildroot](https://buildroot.org/)
    - Can generate tiny, self-contained systems. [Smaller and simpler](https://events.static.linuxfound.org/sites/events/files/slides/belloni-petazzoni-buildroot-oe_0.pdf) than [Yocto](https://www.yoctoproject.org/) and [RPi OS Lite](https://www.raspberrypi.org/downloads/raspberry-pi-os/).
- [musl libc](https://www.musl-libc.org/)
    - A [small, simple, and fast](https://www.etalabs.net/compare_libcs.html) LibC.
- [BusyBox](https://busybox.net/)
    - Default system utilities for Buildroot. Also includes an init system.
- [F2FS](https://en.wikipedia.org/wiki/F2FS)
    - Unlike EXT4, F2FS was designed from the ground up for flash. It provides a [performance](https://www.phoronix.com/scan.php?page=article&item=linux-58-filesystems&num=4) and simplicity advantage compared to popular alternatives. This gives it the opportunity to boot faster and gives flash storage better endurance for long-term use.


### Results

Values represent time from unpowered to userland in seconds (+/-0.3s)

|  | RPi OS Full | Buildroot | Buildroot Instant Pi | CD Bootloader Overhead |
|-|-:|-:|-:|-:|
| [0w](instant-pi-0w) | 70 | 10.5 | 8.5 | 4.1 |
| [1B](instant-pi-1b) | 77 | 13.0 | 9.2 | 4.3 |
| 4B |  |  |  |  |

CD Bootloader Overhead is the theoretical fastest boot time with the closed source cut down bootloader. On [Punchboot](https://github.com/jonasblixt/punchboot) capable SoCs (open source bootloader), this overhead can be as low as 60ms.

### Related projects and documentation

- https://himeshp.blogspot.com/2018/08/fast-boot-with-raspberry-pi.html
- https://www.furkantokac.com/rpi3-fast-boot-less-than-2-seconds/
- https://github.com/romainreignier/minimal_raspberrypi_buildroot
- https://ltekieli.com/buildroot-with-raspberry-pi-what-where-and-how/
- https://medium.com/@hungryspider/building-custom-linux-for-raspberry-pi-using-buildroot-f81efc7aa817
- https://weeraman.com/building-a-tiny-linux-kernel-8c07579ae79d?gi=8c9ce5189663
- https://www.raspberrypi.org/documentation/linux/kernel/
- https://www.raspberrypi.org/documentation/configuration/config-txt/README.md
- https://www.raspberrypi.org/documentation/configuration/cmdline-txt.md
- https://www.linuxsecrets.com/elinux-wiki/images/7/70/Opdenacker-boot-time-ELC-2014.pdf
- https://bootlin.com/doc/training/boot-time/boot-time-slides.pdf
- https://www.nxp.com/files-static/training_pdf/VFTF09_MONTAVISTA_LINUXBOOT.pdf
- https://source.android.com/devices/tech/perf/boot-times
- https://github.com/jonasblixt/punchboot

## How to go fast

In a modern OS, there is a surprising amount of working being done just to boot. Luckily for us, a lot of it is unnecessary and can be simplified to reduce the time it takes.

A system can do the following for a minimal boot:
1. System is powered on, hardware is initialized
    - Disable unnecessary hardware features
2. OS is loaded and started
    - Reduce loading steps and reduce OS size
3. Login or application is started
    - Remove startup services and reduce application size

## Boot[loading]

Unlike x86 which uses the [BIOS](https://en.wikipedia.org/wiki/BIOS) and [UEFI](https://en.wikipedia.org/wiki/Unified_Extensible_Firmware_Interface) specification, and most ARM devices which use [UBoot](https://en.wikipedia.org/wiki/Das_U-Boot), the boot process for RPis (and any Broadcom device) is unique and depends entirely on binary blobs. As such, it's not possible optimize them for boot speed and will be main bottle neck to achieve faster boot times.

The boot process for Broadcom SoCs is well documented here:
- https://wiki.beyondlogic.org/index.php?title=Understanding_RaspberryPi_Boot_Process
- https://raspberrypi.stackexchange.com/questions/10442#10595
- https://www.furkantokac.com/rpi3-fast-boot-less-than-2-seconds/

To boot, we'll need the following files in the root of our [V]FAT formatted boot partition:

- `bootcode.bin`
    - Activates RAM and runs `start.elf`
    - Currently only available as a binary blob
    - Fetch it from here: https://github.com/raspberrypi/firmware/raw/stable/boot/bootcode.bin

- `start.elf`
    - Loads the kernel image then loads config files and `.dtb` modules then starts kernel, contains GPU firmware
    - [Multiple variants](https://www.raspberrypi.org/documentation/configuration/boot_folder.md), we'll use Cut Down variant `start_cd.elf` to improve boot times
    - Currently only available as a binary blob
    - Fetch it from here: https://github.com/raspberrypi/firmware/raw/stable/boot/start.elf

- `fixup.dat`
    - Linker files required by start.elf
    - [Multiple variants](https://www.raspberrypi.org/documentation/configuration/boot_folder.md) corresponding to start.elf, we'll use Cut Down variant `fixup_cd.elf` to improve boot times
    - Currently only available as a binary blob
    - Fetch it from here: https://github.com/raspberrypi/firmware/raw/stable/boot/fixup.
    
- `kernel.img` or `zImage`
    - Linux kernel
    - Runs `/init` with PID1

There are also optional files that contribute to the boot processes:

- `cmdline.txt`
    - Passes parameters / options to the kernel when it starts

- `config.txt`
    - Read by `start.elf` to configure the hardware before the kernel is loaded

## Kernel

Unfortunately, RPis are currently incapable of using the [mainline kernel](https://git.kernel.org/) so we'll have to use the one [provided by the RPi Foundation](https://github.com/raspberrypi/linux) based on 5.4. For the kernel config, we will be making a custom one from scratch with inspiration from [bcmrpi](https://github.com/raspberrypi/linux/blob/rpi-5.4.y/arch/arm/configs/bcmrpi_defconfig) and [tinyconfig](https://tiny.wiki.kernel.org/). This will allow us to produce the smallest possible kernel for our use case.

The final kernel will also be compressed into `zImage` using [LZ4](https://github.com/lz4/lz4) to reduce load times while maintaining very fast decompression. Overall, this should [improve boot times](https://events.static.linuxfound.org/sites/events/files/lcjpcojp13_klee.pdf).

## Init

We'll be using the Busybox `init` for system initialization (PID1). No services / daemons will be launched other than Busybox `getty` which will provide the login prompt.

If you would like to launch a specific application, an init system isn't even required, all that's needed is a method for mounting the filesystem then symlink the application to `/sbin/init`:
- https://www.furkantokac.com/rpi3-fast-boot-less-than-2-seconds/

If you would like to launch a GUI on boot, QT linuxfb is the best option:
- https://doc.qt.io/qt-5/embedded-linux.html#linuxfb
- https://doc-snapshots.qt.io/qt6-dev/embedded-linux.html#linuxfb
- GTK [no longer supports](https://www.phoronix.com/scan.php?page=news_item&px=ODU4OQ) DirectFB as of GTK+ 2.90

## Buildroot

Buildroot optimizations:
- libraries static only
- Toolchain musl
- Enable compiler lto
- Use F2FS with `fastboot` [enabled](https://linux-f2fs-devel.narkive.com/cND2je9J/f2fs-mount-o-sync-sync-and-cut-off-power) for rootfs

## Putting it together

To get things started, we'll use the default Buildroot config for the RPi 1B as a baseline. This is done by simply running `make raspberrypi_defconfig` followed by `make`. This will give us a baseline for a standard Buildroot system.

This generates a `sdcard.img` file in `buildroot/output/images` that's 153MB (60MB rootfs, 5MB zImage, 26MB all gzipped) and boots in ~13.0s. For reference, Raspberry Pi OS Full image is ~2.5GB and takes ~77s to boot to userspace.

Now we can start to make a custom Buildroot config by looking through the default one and cherry picking what we want: https://fossies.org/linux/buildroot/configs/raspberrypi_defconfig

First I made the created my own defconfig with the following changes:
- Remove shared libraries, statically build everything
- Enable LTO
- Use F2FS for rootfs
- Resize rootfs to 136MB to accommodate F2FS
- Compress the kernel using LZ4
- Remove default RPi firmware

Then I created my own `genimage.cfg` to look for a F2FS `rootfs` instead of EXT4. I also shrunk the boot partition size to 8208KB as a result of the smaller cut down firmware.

Finally, I removed unnecessary parameters in `cmdline.txt` and added `rootflags=fastboot` for F2FS. I created a blank `config.txt` and added the following lines to use the cut down firmware and specify our compressed kernel.

```
# Cut down kernel only works with 16MB of VRAM
gpu_mem=16

start_file=start_cd.elf
fixup_file=fixup_cd.dat

kernel=zImage
```

I used `make savedefconfig` to generate a defconfig which I saved to `buildroot/configs/instantpi1b_defconfig` to be built using `make instantpi1b_defconfig` and `make` (If you're having issues, wipe the buildroot dir and clean build).

This generates a 145MB (25MB gzipped) `sdcard.img` which includes a 136MB `rootfs.f2fs` and 6MB `zImage`. Our optimizations result in boot times that are consistently ~29% faster at ~9.2s.

**TODO:**
- Make boot partition smaller: https://github.com/raspberrypi/firmware/issues/1486#issuecomment-745093948
- Our next step is to minimize the kernel, rootfs, and drivers / modules.
- Last step is to disable logging and kernel output messages, we haven't done this till now to make it easier to debug.
