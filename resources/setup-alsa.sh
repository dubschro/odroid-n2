#!/bin/sh

# I was not the author of this.  
# There are lots of places this is posted.
# Behold, here's another.
# This flips the internal bits around so the 3.5mm analog jack works.
# I added the alsactl store.

# Note that even after this, you will get a HUGE pop sound when the 
#  audio is first activated, which is why I use pulseaudio with "suspend"
#  disabled.  Basically, even with this installed, you get the HUGE pop
#  sound when loggin into a desktop that activates pulseaudio, but it
#  is quiet after that.


# Reset and re-initiate ALSA mixer states
rm /var/lib/alsa/asound.state
alsactl init
# Enable 3.5mm output
amixer -c 0 set 'TOACODEC OUT EN' 'on'
# Use I2S B as source for 3.5mm output, I2C A is somehow not usable
amixer -c 0 set 'TOACODEC SRC' 'I2S B'
# Use ALSA device 0 as input for I2S B
amixer -c 0 set 'TDMOUT_B SRC SEL' 'IN 0'
# Enable I2S B (SRC 2) on device 0 (_A)
amixer -c 0 set 'FRDDR_A SRC 2 EN' 'on'
# Set output channels for device 0 (_A)
amixer -c 0 set 'FRDDR_A SINK 1 SEL' 'OUT 0'
amixer -c 0 set 'FRDDR_A SINK 2 SEL' 'OUT 1'
amixer -c 0 set 'FRDDR_A SINK 3 SEL' 'OUT 2'
# Set master volume to 85%
amixer -c 0 set 'ACODEC' '85%'

# persist in case shutdown scripts don't
alsactl store
