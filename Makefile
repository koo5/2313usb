#http://codeandlife.com/2012/01/22/avr-attiny-usb-tutorial-part-1/

# WinAVR cross-compiler toolchain is used here
CC = avr-gcc -DF_CPU=12000000L
OBJCOPY = avr-objcopy
DUDE = avrdude
V = "h"

# If you are not using ATtiny2313 and the USBtiny programmer, 
# update the lines below to match your configuration
CFLAGS = -Wall -Os -Iusbdrv -mmcu=attiny2313
OBJFLAGS = -j .text -j .data -O ihex
DUDEFLAGS = -p t2313 -c arduino -b 19200 -P /dev/ttyACM0 $(V)

# Object files for the firmware (usbdrv/oddebug.o not strictly needed I think)
OBJECTS = usbdrv/usbdrv.o usbdrv/oddebug.o usbdrv/usbdrvasm.o main.o

# Command-line client
CMDLINE = usbtest.exe


all: flash

v: x flash
	cowsay done

x:
	$(eval V = -v)

# By default, build the firmware and command-line client, but do not flash

# With this, you can flash the firmware by just typing "make flash" on command-line
flash: main.hex
	cowsay moo
	$(DUDE) $(DUDEFLAGS) -U flash:w:$<

# One-liner to compile the command-line client from usbtest.c
$(CMDLINE): usbtest.c
	gcc -I ./libusb/include -L ./libusb/lib/gcc -O -Wall usbtest.c -o usbtest.exe -lusb

# Housekeeping if you want it
clean:
	$(RM) *.o *.hex *.elf usbdrv/*.o

# From .elf file to .hex
%.hex: %.elf
	$(OBJCOPY) $(OBJFLAGS) $< $@

# Main.elf requires additional objects to the firmware, not just main.o
main.elf: $(OBJECTS) main.c
	$(CC) $(CFLAGS) $(OBJECTS) -o $@

# Without this dependance, .o files will not be recompiled if you change 
# the config! I spent a few hours debugging because of this...
$(OBJECTS): usbdrv/usbconfig.h

# From C source to .o object file
%.o: %.c	
	$(CC) $(CFLAGS) -c $< -o $@

# From assembler source to .o object file
%.o: %.S
	$(CC) $(CFLAGS) -x assembler-with-cpp -c $< -o $@
