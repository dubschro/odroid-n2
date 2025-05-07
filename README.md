# WORK IN PROGRESS
This is a work in progress.  Please note that I have not yet followed these
steps end to end to ensure I didn't miss anything.  I just documented
what I remembered from doing the process myself using my resulting
working system as a guide.

# ODROID N2 Resources / Guide
This repo and this README.md provide the recipie and utilities I use on my
ODROID N2+ to run modern arch (arch arm port) with.  I'm sure this information
can help you get other distribitions working with mainline linux and u-boot as
well, but be aware that this guide specifically provides instructions for Arch
Linux Arm.  Everything except the overclocking should be the same for an
original N2.  
<!-- TOC start (generated with https://github.com/derlin/bitdowntoc) -->

- [Resources](#resources)
- [What works?](#what-works)
- [What isn't perfect...](#what-isnt-perfect)
   * [Hardware video decoding](#hardware-video-decoding)
   * [GPU issues in Wayland (Rare)](#gpu-issues-in-wayland-rare)
   * [Audio Pop](#audio-pop)
   * [Suspend](#suspend)
- [The Recipe](#the-recipe)
   * [Install Arch Linux Arm](#install-arch-linux-arm)
   * [Finish Up a Normal Arch Linux Install](#finish-up-a-normal-arch-linux-install)
   * [Backup the Stock Boot Partition and Kernel Modules](#backup-the-stock-boot-partition-and-kernel-modules)
   * [Install Mainline U-Boot](#install-mainline-u-boot)
      + [Download U-Boot Source](#download-u-boot-source)
      + [Build U-Boot on ODROID](#build-u-boot-on-odroid)
      + [Sign U-Boot on x86 Linux](#sign-u-boot-on-x86-linux)
      + [Install U-Boot ](#install-u-boot)
   * [Update mkinitcpio to Load Panfrost ASAP for Console](#update-mkinitcpio-to-load-panfrost-asap-for-console)
   * [Install Mainline aarch64 Linux Kernel](#install-mainline-aarch64-linux-kernel)
   * [Uninstall stock uboot](#uninstall-stock-uboot)
   * [U-Boot Distro Boot extlinux.conf file](#u-boot-distro-boot-extlinuxconf-file)
   * [Change FSTAB to Use UUID for Boot Partition](#change-fstab-to-use-uuid-for-boot-partition)
   * [Reboot Into Mainline Linux](#reboot-into-mainline-linux)
   * [Network Interface Change / NetworkManager](#network-interface-change--networkmanager)
   * [Pin Your EDID File to Resolve Display Sleep Issues](#pin-your-edid-file-to-resolve-display-sleep-issues)
      + [Extract the EDID File From Your Monitor](#extract-the-edid-file-from-your-monitor)
      + [Put the EDID in Your initrd](#put-the-edid-in-your-initrd)
   * [Setup the "Fix USB" Reboot Hook](#setup-the-fix-usb-reboot-hook)
   * [Analog Audio Enablment](#analog-audio-enablment)
      + [Install Pulseaudio and Disable Sink Suspend](#install-pulseaudio-and-disable-sink-suspend)
- [Optional / Additional Pieces](#optional--additional-pieces)
   * [Overclocking](#overclocking)
   * [Disable Suspend](#disable-suspend)
   * [Wayland](#wayland)
   * [Plasma on Wayland](#plasma-on-wayland)
   * [SDDM Display Manager on Wayland](#sddm-display-manager-on-wayland)
   * [Firefox Settings](#firefox-settings)
   * [USB Quirks for Cheap USB SSDs](#usb-quirks-for-cheap-usb-ssds)
   * [Root / Home Volumes on external SSD with LVM2](#root--home-volumes-on-external-ssd-with-lvm2)
      + [Install LVM2 in the INITRD](#install-lvm2-in-the-initrd)
      + [Change root in extlinux.conf](#change-root-in-extlinuxconf)

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
    degree via the base ``meson-g12b-s922x.dtsi`` that is used for many arm
    sbc.  I *assume* the mainline cpu voltage and frequencies work with the n2, but I do not own one to test with.
    I have created created the n2 overclock overlay based on the stock
    hardkernel kernel's additional a73 mhz/mv for the 2004 speed from the stock device tree.
* [extlinux.conf](resources/extlinux.conf) A /boot/extlinux/extlinux.conf for mainline u-boot file as a starting point
* [touch-reboot-flag.service](resources/touch-reboot-flag.service) A systemd service to hook reboot and touch a /boot/reboot file


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

## Suspend
The thing never wakes up.  Don't really care, I just disable suspend system
wide.

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

### Download U-Boot Source
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
Now edit the resulting .config file and change the ``CONFIG_BOOTCOMMAND``
to the following value.
```
CONFIG_BOOTCOMMAND="fatrm mmc 0:1 reboot && echo Resetting USB on reboot... && usb reset && sleep 10; run distro_bootcmd"
```
The above was setup on my device that does not have an eMMC installed.  If your
sdcard is on ``mmc 1:1``, change the above accordingly.  What the above
command does is check for (and remove) a file named ``reboot`` in the root of
the sdcard boot partition and then reset the usb ports and sleep for 10
seconds.  This will only happen once, obviously, and it is triggered by a
reboot hook in a systemd service we will install later.  The effect is every
requested reboot in linux puts this *flag file* in the boot partition, which
causes the very next boot to reset usb and give it time to recover.  It's a
hack, yes, but I'll take it over having to unplug the device at every reboot
and never being able to reboot remotely.  Note that the ``usb reset`` command
in u-boot will break cold boots, so it is important that this behavior is only
triggered from the existings of the reboot flag file indicating the next boot
is a reboot without power cycle.  In the worst case scenario, if you reboot but
turn the power off, the next cold boot will fail due to thinking it is in
"reboot mode" and bouncing the USB, but the next boot will succeed because it
only will try the reboot logic once thanks to the ``fatrm`` command.

Now that you have the .config created, run ``make`` to build your u-boot.bin
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

## Update mkinitcpio to Load Panfrost ASAP for Console
Generally speaking, panfrost will load pretty quick, but I've found myself
waiting for it to pop up and activate a console on hdmi output, especially if
there is a failure early on during boot.  Forcing the module to load in initrd
will ensure you get console messages on your monitor as soon as possible.  Add
``panfrost`` to the modules list in ``/etc/mkinitcpio.conf``.  The top of
the file should look like the example below.
```
# MODULES
# The following modules are loaded before any boot hooks are
# run.  Advanced users may wish to specify all system modules
# in this array.  For instance:
#     MODULES=(usbhid xhci_hcd)
MODULES=(panfrost)
```
**DO NOT run ``mkinitcpio -P`` as it will be ran for you when we install the mainline kernel.**

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
``/extlinux/extlinux.conf`` on any supported filesystem and use it to launch
the kernel.  We will be placing this on the /boot partition which is the first
partition (vfat) on the sdcard.  Sudo / su to root and create the file
``/boot/extlinux/extlinux.conf`` as shown below.
```
LABEL mainline-linux
  MENU LABEL Mainline Linux Kernel
  LINUX ../Image
  INITRD ../initramfs-linux.img
  FDT ../dtbs/amlogic/meson-g12b-odroid-n2.dtb
  APPEND root=UUID=a5a6b723-1b8d-4844-9ca6-3047d3399600 rw rootwait console=ttyAML0,115200n8 console=tty1 video=1920x1080@60 drm.edid_firmware=HDMI-A-1:edid/my-monitor.bin
```
Now change the following:
* Change the UUID if YOUR root filesystem.  Use the ``blkid`` command to find
  it.
* Change or remove the video= argument.  I have my display locked at 1080 60hz
  because the odroid tries to use 120hz on this monitor and... it does not work
  well.
* If you have an N2+ model, change the FDT to
  ``.../dtbs/amlogic/meson-g12b-odroid-n2-plus.dtb``.

Now also go verify that the dtb file (device tree blob) you are specifying
exists.  Leave the ``drm.edid_firmware`` argument alone.  We will extract
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
``blkid`` command.

## Reboot Into Mainline Linux
Hopefully, if everything has gone as planned, you can ``shutdown`` and
re-apply power to the system and boot into your system on mainline linux.  I'd
always suggest a hard power cycle when changing away from the hardkernel
kernel.  

## Network Interface Change / NetworkManager
Arch + mainline kernel 6 means your ethernet device probably changed from ``eth0`` to ``end0``.  
You will need to update your systemd-networkd config at a minimum, but I found the device renaming
to have race conditions with systemd-networkd.  My solution was to install NetworkManager and 
disable systemd-networkd, which is something I do in the end on most machines as I prefer it, 
especially if using a plasma desktop with the network manager integration.
```
pacman -S networkmanager
systemctl disable --now systemd-networkd
```
Now execute ``nmtui`` to configure your network interface.

## Pin Your EDID File to Resolve Display Sleep Issues
You may need to do this when you change monitors as well, especially if they
don't support the same modes.  We are extracting the EDID file from your
monitor because mainline linux on the odroid n2 will sometimes lose the modes
your monitor supports after some period of time with the display asleep.  The
system doesn't crash, but you can't SEE anything.  I determined this from some
very useful kernel messages.  

### Extract the EDID File From Your Monitor
Use the following commands as root to place your
monitor's EDID data into a file in your firmware directory.
```
mkdir /lib/firmware/edid
cp /sys/devices/platform/soc/*/drm/card*/*/edid /lib/firmware/edid/my-monitor.bin
```

### Put the EDID in Your initrd
Crack open the ``/etc/mkinitcpio.conf`` file again and add ``/lib/fimrware/edid/my-monitor.bin``
to the FILES section.  This will cause this file to be present in your initrd so the kernel can load it 
before the root filesystem has been mounted.  An example of the section is provided below.
```
# FILES
# This setting is similar to BINARIES above, however, files are added
# as-is and are not parsed in any way.  This is useful for config files.
FILES=(/lib/firmware/edid/my-monitor.bin)
```
Now run ``mkinitcpio -P`` to re-generate your initrd.  Run ``shutdown now``
and power cycle the system.  The EDID error should be gone.  **Note that I
didn't say reboot?**  That's because you're likely using USB keyboard and mouse
and rebooting the mainline kernel will lose the usb ports until we complete the
workaround for that issue.

## Setup the "Fix USB" Reboot Hook
This will cause u-boot with our custom boot command to reset the usb ports
and wait a moment only if the last shutdown was caused by a reboot request.
This is a work around for the usb ports being broken after reboots.  As root, add the following 
to a new file called ``/etc/systemd/system/touch-reboot-flag.service``.
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
Enable the service via the following commands.  **Note that this is entirely dependent on the custom u-boot boot command we setup when we built and installed u-boot!**
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

### Install Pulseaudio and Disable Sink Suspend
Install the ``pulseaudio`` package and then modify the
``/etc/pulse/default.pa`` file by commenting out the ``load-module
module-suspend-on-idle`` statement.
```
### Automatically suspend sinks/sources that become idle for too long
#load-module module-suspend-on-idle
```
Now when you login via a desktop environment such as plasma, there will be a
loud pop initially, but after that, only a much quieter "tick/click" at the start of
new audio playing after a period of silence.

# Optional / Additional Pieces
The remaining items are how I got my system into it's final form.  Everything
before this point was essential or *common* to pretty much any install.  From
point on, I focus on setting the system up as a daily driven desktop on plasma.
It's a pretty good experience on Wayland--full accelerated graphics in the
graphical shell and a generally snappy experience, which is a far cry from the
past X11 fb experience, even with DRI enabled.  About the only thing I could
complain about is pages super fat web pages can be a drag, but there are some
firefox settings I will provide that make this experience more of a "wait for
the page to be ready" rather than "this thing slows my whole machine down."

## Overclocking
I do not have an original N2 to test with, only my N2+, so this has only been
tested on an N2.  I've created two device tree overlays that will add the
additional overclock speeds and voltages to both boards.  The N2+ DTO has 2
additional a73 clock speeds and 2 additional a53 clock speeds.  The N2 DTO has
one additional a73 clock speed over the base s922x speeds the mainline kernel
already uses by default.  The implication here is that some of the clock speeds
the odroid n2 wiki considers overclocked are considered standard speeds for the
underlying SoC and are used on many SBCs.  

Grab either the N2 or N2+ overclocking DTO from the [Resources](#resources) section and install in a directory called
``/boot/overlays``, then add it as an ``FDTOVERLAYS`` line in your extlinux.conf.
An example is included below.  **Ensure you are using the n2+ dtb with the n2+ overclock dtbo or the n2 dtb with the n2 overclock dtbo.  Do not mix and match!**
```
LABEL mainline-linux
  MENU LABEL Mainline Linux Kernel
  LINUX ../Image
  INITRD ../initramfs-linux.img
  FDT ../dtbs/amlogic/meson-g12b-odroid-n2-plus.dtb
  FDTOVERLAYS ../overlays/odroid-n2-plus-overlock.dtbo
  APPEND root=UUID=a5a6b723-1b8d-4844-9ca6-3047d3399600 rw rootwait console=ttyAML0,115200n8 console=tty1 video=1920x1080@60 drm.edid_firmware=HDMI-A-1:edid/my-monitor.bin
```
After a reboot, you can install the ``cpupower`` package and run ``cpupower -c 0 frequency-info`` to see the a53 core frequency and 
``cpupower -c 2 frequency-info`` to see the a73 core frequency.
```
[raz@alarm ~]$ cpupower -c 0 frequency-info
analyzing CPU 0:
  driver: cpufreq-dt
  CPUs which run at the same hardware frequency: 0 1
  CPUs which need to have their frequency coordinated by software: 0 1
  maximum transition latency: 50.0 us
  hardware limits: 1000 MHz - 2.02 GHz
  available frequency steps:  1000 MHz, 1.20 GHz, 1.40 GHz, 1.51 GHz, 1.61 GHz, 1.70 GHz, 1.80 GHz, 1.91 GHz, 2.02 GHz
  available cpufreq governors: conservative ondemand userspace powersave performance schedutil
  current policy: frequency should be within 1000 MHz and 2.02 GHz.
                  The governor "performance" may decide which speed to use
                  within this range.
  current CPU frequency: Unable to call hardware
  current CPU frequency: 2.02 GHz (asserted by call to kernel)
[raz@alarm ~]$ cpupower -c 2 frequency-info
analyzing CPU 2:
  driver: cpufreq-dt
  CPUs which run at the same hardware frequency: 2 3 4 5
  CPUs which need to have their frequency coordinated by software: 2 3 4 5
  maximum transition latency: 50.0 us
  hardware limits: 1000 MHz - 2.40 GHz
  available frequency steps:  1000 MHz, 1.20 GHz, 1.40 GHz, 1.51 GHz, 1.61 GHz, 1.70 GHz, 1.80 GHz, 1.91 GHz, 2.02 GHz, 2.11 GHz, 2.21 GHz, 2.30 GHz, 2.40 GHz
  available cpufreq governors: conservative ondemand userspace powersave performance schedutil
  current policy: frequency should be within 1000 MHz and 2.40 GHz.
                  The governor "performance" may decide which speed to use
                  within this range.
  current CPU frequency: Unable to call hardware
  current CPU frequency: 2.40 GHz (asserted by call to kernel)
```
I've never had my board crash from running overclocked, but if you want to
disable the highest clock speeds and/or *step down*, you can download the dts
source and remove the clocks you don't want and use the ``dtc`` command to
create a new dtbo with the reduced overclock speed.  You could also create your
own DTBO to disable the higher clock speeds that the mainline linux kernel is
setting on the original N2 if you have instability with them (unlikely.)

## Disable Suspend
Any time I suspend the device, there's no waking it back up via keyboard/mouse, so I
just disable suspend at the systemd level by editing ``/etc/systemd/sleep.conf`` and uncommenting / changing 
most options to no.
```
[Sleep]
AllowSuspend=no
AllowHibernation=no
AllowSuspendThenHibernate=no
AllowHybridSleep=no
#SuspendState=mem standby freeze
#HibernateMode=platform shutdown
#MemorySleepMode=
#HibernateDelaySec=
HibernateOnACPower=no
#SuspendEstimationSec=60min
```

## Wayland
Wayland is dramatically faster that Xorg with DRI.  Wayland is 98% there with
panfrost and absolutely the right choice today.  Just install the wayland
packages, no special configuration needed.

## Plasma on Wayland
Plasma is actually changing to Wayland by for Plasma 7.  It works very
well TODAY.  SDDM works well TODAY.  The only thing I have not seen work 100%
is the hot corners overview feature causes a black screen until you exit from
the hot corners overview.  I just turn that off and don't really miss it.
Perhaps I'll figure out what the issue is and file a bug, that day is not
today.  **Plasma on Wayland is beautiful and fast with full graphics effects turned on.**

Just install KDE/Plasma via the [KDE -
ArchWiki](https://wiki.archlinux.org/title/KDE) page.  My preferred route is to
install the ``plasma-meta`` package to get the "full plasma" and then follow up
by installing the ``kde-applications-group`` package and then only installing
individual apps by number when prompted.  At a minimum, I install konsole,
dolphin, kate, kcalc, and then pick and choose things that sound beneficial or
I know I've used in the past.

You can run plasma (as a non root user, of course) by logging in on a text
console and running ``startplasma-wayland``, or you can install a display
manager such as SDDM and choose the "Plasma (Wayland)" option.

## SDDM Display Manager on Wayland
SDDM will run on X11, but I've had it *get angry* and stop working when using
it in tandem with Wayland Plasma, so I switched to Wayland for it as well.
Thankfully it is super easy to do.  Just install the ``sddm`` package, then
follow the steps for [Wayland](https://wiki.archlinux.org/title/SDDM#Wayland)
from the arch wiki.  I only did the first ``KDE Plasma / Kwin`` step, which
involves installing a few packages and making one config file.

After the above is done, enable/start sddm: ``systemctl enable --now sddm``

## Firefox Settings
Firefox will gladly use all your cores and drag down your entire system.  Open
``about:config`` and change ``dom.ipc.processCount.webIsolated`` to 2 or 3.
The default value of ``4`` will essentially use all of your a73 cores under
load and that makes the ui less responsive.  I like to limit it to ``2``
personally.  Additionally, switch ``browser.tabs.unloadOnLowMemory`` to
``true`` to unload tabs and keep the system from OOM killing things or going to
swap (if you have swap!) if a background tab runs away.  These two settings
make a pretty large usability difference with the only real down side is a slow
page may be slow while the browser and system remains responsive.

## USB Quirks for Cheap USB SSDs
I have a "MOKiN" USB3 M2 drive enclosure with SSD inside.  It worked great up
until I upgraded to Linux 6.  Turns out that many cheap USB storage devices
*claim* to support ``uas`` mode, but it falls apart when used put to the test.
Prior versions of Linux used ``usb-storage`` mode, but newer Linux versions
started to use uas mode and trust the claims of cheap devices with
less-than-compliant firmware about their ability to do uas.  If you have one of
these, the device will generally work, then just fall on its face and stop
responding.  The solution for these devices is to black list them for uas mode
via a *usb quirk*, either as a kernel command line option, or a udev
configuration.  For me, since I actually run my entire root and home volumes
off of LVM on an external USB M2 SSD that has this issue, I have no choice but
to quirk it up on the kernel command line.  You can use ``lsusb -tv`` to find
your device id and add a quirk like ``usb-storage.quirks=0bda:9210:u`` to your
kernel parameters.  The device id is ``0bda:9210`` and the ``:u`` disables uas
mode.  This isn't specific to the odroid, but I find that cheap SSD enclosures tend
to go hand-in-hand with SBC enthusiasts 😅.

## Root / Home Volumes on external SSD with LVM2
I am not going to go into the details (at this time, maybe later) about
how I do this, but I will give you the details on the prerequisites.  I will
leave out the gory details about setting up your VGs, LVs, and tar transferring
the root / home filesystems as that is not even remotely odroid n2 / arch
specific.  FOR NOW, I'm assuming before you go into the next steps, you know
how to do this part and have your root and or home LVs ready.

### Install LVM2 in the INITRD
In order to have lvm2 volumes available as your root filesystem, the initrd 
must have the lvm2 module in the right place.  This, of course, assumes you have
the ``lvm2`` package installed and some LVs ready to go with your root fs
contents transffered to it.  Open the ``/etc/mkinitcpio.conf`` and update the ``HOOKS``
value so that ``lvm2`` is after ``block`` and before ``filesystems``.  This will
cause all LVs to be available and identified so that the ``root=UUID=<your rootfs uuid>`` argument
can find your root LV.  My hooks came out looking like the following.
```
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block lvm2 filesystems fsck)
```
Now you can run ``mkinitcpio -P`` to generate the initrd with lvm2 support.

### Change root in extlinux.conf
If you have moved ``/home`` to a new LV as well, ensure that your new ``root`` LV filesystem has
an ``fstab`` that mounts /home as your new LV's uuid from ``blkid``. 

Change the ``root=`` kernel option in ``/boot/extlinux/extlinux.conf`` to point the **new** UUID of the LV
you transferred the root filesystem to.

At this point, if you reboot, the system should come up and find/mount the root (and optionally home) LVs.

This is hardly an odroid n2 item, but I wanted to at least cover the LV initrd stuff and changing the kernel 
boot command line in the context of the system setup I had advocated for.

I will likely expand this section with some gory detail when I get time, so maybe it's not so likely.

