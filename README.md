# instant-pi
Achieving the fastest possible boot times on the Raspberry Pi

This project will be done on a Pi Zero since it's the simplest RPi and the simplicity in drivers and firmware will likely make allow it to boot faster. However, it is possible that the RPi 4 could boot faster as a result of it's massively performance advantage.

Based on the following projects:
- [Buildroot](https://buildroot.org/)
- [musl libc](https://www.musl-libc.org/)
- [BusyBox](https://busybox.net/)
- [F2FS](https://en.wikipedia.org/wiki/F2FS)

Related projects:
- https://github.com/romainreignier/minimal_raspberrypi_buildroot
- https://github.com/jonasblixt/punchboot
- https://weeraman.com/building-a-tiny-linux-kernel-8c07579ae79d?gi=8c9ce5189663

## How to go fast

When describing boot speed, we typically mean the time it takes for a device to go from un-powered to userspace (login, taking a picture, using the terminal, interactive GUI).

In a modern OS, there is a surprising amount of working being done between these two states. Luckily for us, a lot of it is unnecessary and can be simplified to reduce the time it takes to boot.

A system can do the following for a minimal boot:
1. System is powered on, hardware is initialized
    - Disable unnecessary hardware features
2. OS is loaded and started
    - Reduce loading steps and minimize OS size
3. Login or application is started
    - Remove startup dependencies and reduce application size

## Boot[loading]

The RPi Zero uses the Broadcom BCM2835 SoC, its boot process is well documented here:
- https://wiki.beyondlogic.org/index.php?title=Understanding_RaspberryPi_Boot_Process
- https://raspberrypi.stackexchange.com/questions/10442#10595

To boot, we'll need the following files in the root of our [V]FAT formatted boot partition:
- `bootcode.bin`
    - Enables SDRAM and runs `start.elf`
    - Currently only available as a binary blob
    - Fetch it from here: https://github.com/raspberrypi/firmware/raw/stable/boot/bootcode.bin
- `start.elf`
    - Loads `kernel.img` then loads config files and `.dtb` modules then starts kernel
    - Currently only available as a binary blob
    - Fetch it from here: https://github.com/raspberrypi/firmware/raw/stable/boot/start.elf
- `kernel.img`
    - Linux kernel
    - Will be built with minimal modules using Buildroot
    - Runs `/init` with PID1

```sh
curl https://buildroot.org/downloads/buildroot-2020.08.1.tar.bz2 | tar -xzf
cd buildroot
wget https://github.com/raspberrypi/firmware/raw/stable/boot/bootcode.bin
wget https://github.com/raspberrypi/firmware/raw/stable/boot/start.elf
make menuconfig

Buildroot options:
ARM (little endian)
ELF
ARM1176JZF-S
EABIhf
VFPv2
ARM
strip target binaries
gcc optimize for size
libraries static only
Toolchain musl
Enable compiler lto


git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/
```

extract buildroot into this dir
run make

## Init

### Need run levels?
- Systemd
- Runinit (void)
- OpenRC (alpine)
- sysvinit / busybox init
    - https://unix.stackexchange.com/questions/146284

## Userspace

### Framebuffer

- https://doc.qt.io/qt-5/embedded-linux.html#linuxfb
- GTK [no longer supports](https://www.phoronix.com/scan.php?page=news_item&px=ODU4OQ) DirectFB as of GTK+ 2.90

## Putting it together