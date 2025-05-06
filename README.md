# THIS IS IN THE PROCESS OF BEING CREATED AND IS NOT COMPLETE
# ODROID N2 Resources / Guide
This repo and this README.md provide the recipie and utilities I use on my
odroid-n2 to run modern arch (arch arm port) with.  I'm sure this information
can help you get other distribitions working with mainline linux and u-boot as
well, but be aware that this guide specifically provides instructions for Arch
Linux Arm.  

<!-- TOC start (generated with https://github.com/derlin/bitdowntoc) -->

- [Resources](#resources)
- [What works?](#what-works)
- [What isn't perfect...](#what-isnt-perfect)
   * [Hardware video decoding](#hardware-video-decoding)
   * [GPU issues in Wayland (Rare)](#gpu-issues-in-wayland-rare)
   * [Audio Pop](#audio-pop)
- [The Recipe](#the-recipe)
   * [Install Arch Linux Arm](#install-arch-linux-arm)
   * [Finish Up a Normal Arch Linux Install](#finish-up-a-normal-arch-linux-install)
   * [Backup the Stock Boot Partition and Kernel Modules](#backup-the-stock-boot-partition-and-kernel-modules)
   * [Install Mainline U-Boot](#install-mainline-u-boot)
   * [Analog Audio Enablment](#analog-audio-enablment)

<!-- TOC end -->

# Resources
These are used below but to make them easily accessible quickly, here they all
are...
* [setup-alsa.sh](resources/setup-alsa.sh) Mainline kernel alsa enablement script 
* [odroid-n2-plus-overlock.dtbo](resources/odroid-n2-plus-overlock.dtbo) ODROID N2 Plus Device Tree Overlay for overclocking
  * [odroid-n2-plus-overlock.dts](resources/odroid-n2-plus-overlock.dts) Source for the above
* [odroid-n2-overlock.dtbo](resources/odroid-n2-overlock.dtbo) **UNTESTED** ODROID N2 Device Tree Overlay for overclocking
  * [odroid-n2-overlock.dts](resources/odroid-n2-overlock.dts) **UNTESTED** Source for the above
  * The mainline kernel already *"overclocks"* the non plus variant to some
    degree via the base ```meson-g12b-s922x.dtsi``` that is used for many arm
    sbc.  I *assume* the mainline cpu voltage and frequencies work with the n2,
    and I have created created the n2 overclock overlay based on the stock
    hardkernel kernel's additional a73 clock of 2004.
* [extlinux.conf](resources/extlinux.conf) A /boot/extlinux/extlinux.conf for mainline u-boot file as a starting point 

# What works?
The following is all working on Arch Linux arm.  I'm confident I could get it
working on pretty much any distro that provides an aarch64 kernel though.

* Mainline Linux (6.14.4 at last update)
* Mainline U-Boot
* Panfrost GPU support 
* Mainline mesa releases from arch arm
* Accelerated Wayland (WAY faster than X11)
* Hardware accelerated page rendering in firefox
* Analog audio out
* Latest plasma/kde with full 3d acceleration
* ODROID N2 Plus overclocked via device tree overlay
  * Yes the fan kicks on under high load and the speed and millivolts were
    borrowed from the hardkernel stock kernel that enables this.
* USB Ports continue to work after a reboot--previously required power cycle
* OS / Home on LVM2 volumes on an external USB3 M.2 SSD

I still boot off of sdcard, but, that's pretty utilitarian given that I can pop
it into another working machine and resolve boot issues I might cause.  

# What isn't perfect...

## Hardware video decoding
As of this writing (April 29, 2025) I do not have hardware video decoding yet
in firefox--there is a way to do it, but the libraries that used to enable that
functionality have long since been abandoned and the kernel interfaces have
changed so it no longer builds.  I am still looking for a good port, or I could
port it myself, but I'm not too concerned about software rendering youtube to
be honest.  For those wondering, the mainline kernel has support for hardware
video decoding with the VPU via the v4l2 interface but there is no
libva-v4l2-request library that compiles against the modern v4l2 interface in
the kernel, hence libva (required by firefox for hardware video decoding)
cannot interface with the kernel.  This is a solvable problem, but the solution
is not here as if this writing, or I haven't found it yet.  Shucks.

## GPU issues in Wayland (Rare)
Additionally, while the system is rock solid, when primarily operating in
plasma, I do sometimes get some video artifacting or screen flickering that
will resolve quickly on its own.  It's rare, and really a non issue, and I'm
picky, so trust me, it's no sweat: it's few and far between.  The one thing
that is a persistant issue, however, is the hot corners overview in plasma just
makes the entire screen go black until you exit hot corners.  This feels more
like a plasma issue, and it works fine in X11, but wayland is sooo much faster
with gpu effects turned on that I would never run X11 without disabling drop
shadows and other plasma compositor, so I just live with the rare artifact and
turn off hot corners.  I'm sure it will get fixed, and I'm 100% on wayland on
this machine while I still rock X11 on others.

## Audio Pop
Whenever you open the audio device and play something for the first time, it
will make a loud pop.  This is especially the case if you use pipewire-pulse as
your sound server.  If you use pulseaudio and disable suspension of sinks, then
you get the pop when you login to the desktop and that's basically it.  There
may be a little click the first time you play audio in a long time, but the
massive POP is gone, so until they provide a good way to stop pipewire-pulse
from suspending and causing this, I'll stick with vanilla pulseaudio.

# The Recipe

## Install Arch Linux Arm
Go to the [Arch Linux Arm ODROID-N2 page](https://archlinuxarm.org/platforms/armv8/amlogic/odroid-n2)
and install arch on an SD card.  **Make sure you make your vfat boot partition
start at 4096 or 8192 instead of 2048** or you will be sad when you try to write
the newer mainline u-boot image to the front of this card and you clobber your
boot filesystem because the new u-boot is far larger than 2048\*512 = 1MB.
**Additionally, make the boot filesystem +1G** so you can store a few different
kernels and initrd there. I tried 512M and was still cutting it close with the
various backups I had taken.

## Finish Up a Normal Arch Linux Install
After installing Arch Linux Arm, there's a lot of stuff like locale, timezone,
etc that are not complete.  Boot into your new Arch Linux Arm install and Go to
the [Arch Linux Installation Guide](https://wiki.archlinux.org/title/Installation_guide)
and jump right in at...
* Step 3.3 Time, directly after the instructions to chroot as if
it was an x86 system.  
* Skip the part about installing a boot loader as it does not apply to the arm install.  
* Skip the step for rebooting as you're already booted in on the new system.

At this point I like to pacman -Syy and pacman -Su to bring my system up to the
latest and greatest.  When done, reboot back in to ensure everything is good.

***At this point, you have a vanilla Arch Linux Arm install with the following:***
* Enough space after your MBR partition table and before your boot partition for a much larger u-boot.
* Stock (hardkernel) u-boot
* Stock (hardkernel) linux kernel

*Note: The amlogic board is going to look 512B into the sdcard for a signed
boot loader, it doesn't actually do the whole MBR thing or understand
filesystems.  This is why the dd command seeked 512B into the sdcard in the
instructions (bs=512 seek=1).  It's up to you to leave that area for a signed
bootloader and to leave enough room before your boot partition that has your
kernel etc needed by u-boot.*

## Backup the Stock Boot Partition and Kernel Modules
```
cd /boot
mkdir backup
# This will complain about backup but it is fine
cp -a * backup

cd /lib/modules
mkdir backup
# Same complaint, ignore it
cp -a * backup
```
*Note that the original uboot image gets backed up this way in case you need to swap it out too*

## Install Mainline U-Boot
***Note: Once you install mainline u-boot on your sdcard, you cannot boot the
"stock" hardkernel kernel because the handoff method to the kernel is different
and specific to the hardkernel kernels.***  Once you install a mainline kernel
or install mainline u-boot, you need both to boot.

*From this point on it is assumed that you have network access on the ODROID
and a USB drive or access via ssh/scp or other mechanism to transfer files back
and forth from the ODROID.  You will also need an x86 linux machine to sign the
resulting u-boot build.  It is also assumed that, if you are venturing into
mainline linux on an arm sbc, you are familiar enough with linux that you know
how to setup the network and prepare / mount usb drives.  I would kindly suggest
you also install and setup sshd so that you can login remotely for the steps
that require large config file pasting and or installing files provided here.*

### Download
Go get a mainline release (v2025.04 as of this writing) from [U-Boot Github
Releases](https://github.com/u-boot/u-boot/tags).  Download the archive and
transfer it to your alarm user (or other non-root user if you have already
added one) home directory and extract.  We will be building u-boot on the
ODROID.

### Build U-Boot on ODROID
Review the [U-Boot for
ODROID-N2/N2+](https://docs.u-boot.org/en/latest/board/amlogic/odroid-n2.html)
page for the basic install instructions.  Beware that most of the instructions
are in regard to manually signing the resulting u-boot image, but I used the
pre-built FIP repo.  **The instructions are geared toward cross compiling on an x86
system** but it is far easier to just build on the odroid itself.  This means
we will **not export CROSS_COMPILE**. We also need to make a small change to
the odroid n2 build config after it is generated to bounce the USB ports at
reboot (ONLY reboot)--this is something I came up with in order to make the USB
ports function after reboot instead of requiring a power cycle at every boot.
I'm not sure why this happens, but it is a reliable solution from my testing.

**You will have to install base-devel and potentially other packages to build
u-boot.** (TODO: determine which packages are needed an document here)

*Make sure you're building as a non root user, even if you're using root for other purposes.*
```
cd u-boot-2025.04
make odroid-n2_defconfig
```
Now edit the resulting .config file and change the ```CONFIG_BOOTCOMMAND```
to the following value.
```
CONFIG_BOOTCOMMAND="fatrm mmc 0:1 reboot && echo Resetting USB on reboot... && usb reset && sleep 10; run distro_bootcmd"
```
The above was setup on my device that does not have an eMMC installed.  If your
sdcard is on ```mmc 1:1```, change the above accordingly.  What the above
command does is check for (and remove) a file named ```reboot``` in the root of
the sdcard boot partition and then reset the usb ports and sleep for 10
seconds.  This will only happen once, obviously, and it is triggered by a
reboot hook in a systemd service we will install later.  The effect is every
requested reboot in linux puts this *flag file* in the boot partition, which
causes the very next boot to reset usb and give it time to recover.  It's a
hack, yes, but I'll take it over having to unplug the device at every reboot
and never being able to reboot remotely.  Note that the ```usb reset``` command
in u-boot will break cold boots, so it is important that this behavior is only
triggered from the existings of the reboot flag file indicating the next boot
is a reboot without power cycle.  In the worst case scenario, if you reboot but
turn the power off, the next cold boot will fail due to thinking it is in
"reboot mode" and bouncing the USB, but the next boot will succeed because it
only will try the reboot logic once thanks to the ```fatrm``` command.

Now that you have the .config created, run ```make``` to build your u-boot.bin
file.

### Sign U-Boot on x86 Linux
Transfer the resulting u-boot.bin file to an x86 linux machine and download the
pre-built FIP repo.  Follow the instructions from u-boot page, included below.
```
git clone https://github.com/LibreELEC/amlogic-boot-fip --depth=1
cd amlogic-boot-fip
mkdir my-output-dir
./build-fip.sh odroid-n2 /path/to/u-boot/u-boot.bin my-output-dir
```

### Install U-Boot 
**This step will make the system unbootable** until you install the mainline linux
kernel and create a extlinux.conf to launch it from u-boot.  It's all or
nothing--no guts, no glory.

Transfer the resulting signed u-boot.bin.sd.bin file back to the odroid.  It's
now time to dd this to the right offset in the sdcard. Login / su to root on the odroid
and determine which device is your sdcard.  
```
$ mount | grep /boot
/dev/mmcblk1p1 on /boot type vfat (rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,errors=remount-ro)
```
This is partition 1 on mmcblk1, which is what the sdcard device should be on
the stock kernel.  You will be writing this AFTER the MBR partition table 
and before the start of the p1 boot partition.  The dd command that
accomplishes this is provided below (change mmcblk1 if not correct.)  Please
note that it is reading 512 bytes into the signed image (not sure why,) and
then seeking 512 bytes into the SD card (past the MBR partition table) to
write.  This is why we moved the beginning of the boot partition out a bit
because mainline uboot is a bit more plump.
```
dd if=/path/to/u-boot.bin.sd.bin of=/dev/mmcblk1 conv=fsync,notrunc bs=512 skip=1 seek=1
```
*(Replace mmcblk1 with the appropriate device if that is not your sdcard)*

## Update mkinitcpio to Load Panfrost ASAP
Generally speaking, panfrost will load pretty quick, but I've found myself
waiting for it to pop up and activate a console on hdmi output, especially if
there is a failure early on during boot.  Forcing the module to load in initrd
will ensure you get console messages on your monitor as soon as possible.  Add
```panfrost``` to the modules list in ```/etc/mkinitcpio.conf```.  The top of
the file should look like the example below.
```
# MODULES
# The following modules are loaded before any boot hooks are
# run.  Advanced users may wish to specify all system modules
# in this array.  For instance:
#     MODULES=(usbhid xhci_hcd)
MODULES=(panfrost)
```
**DO NOT run ```mkinitcpio -P``` as it will be ran for you when we install the mainline kernel.**

## Install Mainline aarch64 Linux Kernel
```
pacman -S linux-aarch64 linux-aarch64-headers
```
After a few moments you should have a new kernel installed and you should have seen it generate a new initrd.  This will contain your request to load
the panfrost module early.  The only thing left to do to boot strap the system and allow it to boot back up is to setup an extlinux configuration.

## Uninstall stock uboot
This doesn't actually remove stock u-boot from your sdcard's uboot area, but it will keep it from being accidentally used 
by future things, and now that the stock kernel is not installed, it can be removed as it was a depenency before.
```
pacman -R uboot-odroid-n2
```

## U-Boot Distro Boot extlinux.conf file
New u-boot defaults to distro boot, which will look for
```/extlinux/extlinux.conf``` on any supported filesystem and use it to launch
the kernel.  We will be placing this on the /boot partition which is the first
partition (vfat) on the sdcard.  Sudo / su to root and create the file
```/boot/extlinux/extlinux.conf``` as shown below.
```
LABEL mainline-linux
  MENU LABEL Mainline Linux Kernel
  LINUX ../Image
  INITRD ../initramfs-linux.img
  FDT ../dtbs/amlogic/meson-g12b-odroid-n2.dtb
  APPEND root=UUID=a5a6b723-1b8d-4844-9ca6-3047d3399600 rw rootwait console=ttyAML0,115200n8 console=tty1 loglevel=7 video=1920x1080@60 drm.edid_firmware=HDMI-A-1:edid/my-monitor.bin
```
Now change the following:
* Change the UUID if YOUR root filesystem.  Use the ```blkid``` command to find
  it.
* Change or remove the video= argument.  I have my display locked at 1080 60hz
  because the odroid tries to use 120hz on this monitor and... it does not work
  well.
* If you have an N2+ model, change the FDT to
  ```.../dtbs/amlogic/meson-g12b-odroid-n2-plus.dtb```.

Now also go verify that the dtb file (device tree blob) you are specifying
exists.  Leave the ```drm.edid_firmware``` argument alone.  We will extract
this edid from your monitor later and put it in the right location.  For now,
it will produce an error but move on without issue.  **We use an EDID file to
keep the system from falling into the black screen abyss after long periods of
display sleep** which is due to a bug in re-pulling the EDID at display resume.

## Change FSTAB to Use UUID for Boot Partition
Out of the box, the /boot partition is set to mount on /dev/mmcblk1p1.  This
will likey change with the mainline linux kernel (did for me) so now is a good
time to not guess about it and just change it to use UUID like the below
example.
```
# Static information about the filesystems.
# See fstab(5) for details.

# <file system> <dir> <type> <options> <dump> <pass>
UUID="3CC0-3C4B" /boot   vfat    defaults        0       0
```
Change the UUID to YOUR /boot vfat filesystem.  Find it by using the
```blkid``` command.

## Reboot Into Mainline Linux
Hopefully, if everything has gone as planned, you can ```shutdown``` and
re-apply power to the system and boot into your system on mainline linux.  I'd
always suggest a hard power cycle when changing away from the hardkernel
kernel.  

## Pin Your Monitor's EDID file

### Extract the EDID File From Your Monitor
You may need to do this when you change monitors as well, especially if they
don't support the same modes.  We are extracting the EDID file from your
monitor because mainline linux on the odroid n2 will sometimes lose the modes
your monitor supports after some period of time with the display asleep.  The
system doesn't crash, but you can't SEE anything.  I determined this from some
very useful kernel messages.  Use the following commands as root to place your
monitor's EDID data into a file in your firmware directory.
```
mkdir /lib/firmware/edid
cp /sys/devices/platform/soc/*/drm/card*/*/edid /lib/firmware/edid/my-monitor.bin
```

### Put the EDID in Your initrd
Crack open the ```/etc/mkinitcpio.conf``` file again and add ```/lib/fimrware/edid/my-monitor.bin```
to the FILES section.  This will cause this file to be present in your initrd so the kernel can load it 
before the root filesystem has been mounted.  An example of the section is provided below.
```
# FILES
# This setting is similar to BINARIES above, however, files are added
# as-is and are not parsed in any way.  This is useful for config files.
FILES=(/lib/firmware/edid/my-monitor.bin)
```
Now run ```mkinitcpio -P``` to re-generate your initrd.  Run ```shutdown now```
and power cycle the system.  The EDID error should be gone.  **Note that I
didn't say reboot?**  That's because you're likely using USB keyboard and mouse
and rebooting the mainline kernel will lose the usb ports until we complete the
workaround for that issue.

## Setup the "Fix USB" Reboot Hook
This will cause u-boot with our custom boot command to reset the usb ports
and wait a moment only if the last shutdown was caused by a reboot request.
This is a work around for the usb ports being broken after reboots.  As root, add the following 
to a new file called ```/etc/systemd/system/touch-reboot-flag.service```.
```
[Unit]
Description=Touch /boot/reboot when rebooting
DefaultDependencies=no
Before=reboot.target

[Service]
Type=oneshot
ExecStart=/usr/bin/touch /boot/reboot

[Install]
WantedBy=reboot.target
```
This is a simple service that runs only at reboot to touch the /boot/reboot file to trigger our usb reset at reboot.
Enable the service via the following commands.
```
systemctl daemon-reload
systemctl enable touch-reboot-flag.service
```
Congrats, now you have usb ports after reboots!

## Analog Audio Enablment
The [setup-alsa.sh](./analog-audio/setup-alsa.sh) script will twiddle the alsa
config in order to activate the 3.5mm analog jack and save its state across
reboot.  From that point on, alsa output will come from the analog output jack.
Maybe you can get pipewire-pulse towork, but I always end up back on vanilla
pulseaudio with suspending disabled to avoid the massive POP sound every time
audio is played for the first time.

#

