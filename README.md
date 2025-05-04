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
* [setup-alsa.sh](setup-alsa.sh) Mainline kernel alsa enablement script 
* [odroid-n2-plus-overlock.dtbo](odroid-n2-plus-overlock.dtbo) ODROID N2 Plus Device Tree Overlay for overclocking
  * [odroid-n2-plus-overlock.dts](odroid-n2-plus-overlock.dts) Source for the above
* [extlinux.conf](extlinux.conf) My /boot/extlinux/extlinux.conf for mainline u-boot file as a starting point 

# What works?
The following is all working on Arch Linux arm.  I'm confident I could get it working on pretty much any distro that provides an aarch64 kernel though.

* Mainline Linux (6.14.4 at last update)
* Mainline U-Boot
* Panfrost GPU support 
* Mainline mesa releases from arch arm
* Accelerated Wayland (WAY faster than X11)
* Analog audio out
* OS / Home on LVM2 volumes on an external USB3 M.2 SSD
* Latest plasma/kde with full 3d acceleration
* Hardware accelerated page rendering in firefox
* ODROID N2 Plus overclocked via device tree overlay
  * Yes the fan kicks on under high load and the speed and millivolts were
* USB Ports continue to work after a reboot--previously required power cycle
borrowed from the hardkernel stock kernel that enables this.

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
* Still have stock u-boot (old) 

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
and specific to the hardkernel kernels.***

Installing mainline u-boot is a pretty simple process 




## Analog Audio Enablment
The [setup-alsa.sh](./analog-audio/setup-alsa.sh) script will twiddle the alsa
config in order and save its state across reboot.  From that point on, alsa 
output will come from the analog output jack.  Maybe you can get pipewire-pulse
towork, but I always end up back on vanilla pulseaudio with suspending disabled
to avoid the massive POP sound every time audio is played for the first time.

