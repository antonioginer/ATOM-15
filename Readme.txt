---------------------------------------------------------------------------------------

    ATOM-15 v1.6 - ATOMBIOS 15/25/31 kHz Modder

    by Calamity - October 2014 - October 2021

    for further documentation, visit: http://geedorah.com/eiusdemmodi/

---------------------------------------------------------------------------------------

WARNING!: THIS SOFTWARE IS EXPERIMENTAL. USE AT YOUR OWN RISK. THIS SOFTWARE HAS THE
POTENTIAL OF LEAVING YOUR VIDEO CARD IN AN UNUSABLE STATE. Before you use this software,
please make sure you understand the consequences of flashing a faulty or wrong BIOS
to your video card. You WILL NOT be able to boot your system in order to restore the
original BIOS. Usually you will need a PC which motherboard has TWO display card sockets
and a second usable video card in order to be able to boot the system and flash the
bricked display card back into its original state. Keep in mind that the motherboard's
integrated GPU usually DO NOT serve this purpose because it's automatically disabled by
the BIOS as soon as an AGP or PCI-e video card is plugged in. Always use the ORIGINAL
BIOS image obtained from your physical card when using this program.


Overview
--------

ATOM-15 is an experimental tool designed to customize the video output of ATI/AMD display
cards based on the ATOMBIOS firmware (probably all models since the Radeon X800). It works
by modifying the BIOS firmware in such a way that the output frequencies of all video
modes are adjusted into the user's specified frequency ranges. Its purpose is to reduce
the possibility of sending pontentially dangerous frequencies during the BIOS post and
loading process of the operating system, when using these cards with standard resolution
and multi-sync CRT monitors.

Bear in mind that the modifications applied to the firmware only operate during the BIOS
post and the operating system loading process. Once the operating system device drivers
take control of the display card it will behave exactly the same as any normal card. This
means that you will need to use system specific methods in order to customize the video
output from the operating system itself, provided these methods are available.

This is a research project. It has been possible thanks to the documentation publicly
available in the Linux open source drivers (ATOMBIOS headers and hardware registers for
the different asics).


ATOM-15 usage
-------------

ATOM-15 is quite simple to use. Simply open the bios image (*.bin or *.rom). If the BIOS
format is recognized, the "Patch BIOS" button will become active. Now select your monitor
operational ranges by ticking their corresponding checkboxes. Then press "Patch BIOS". If
everything goes well, you will have a modified BIOS image (marked with the "-mod" suffix)
ready to work.

You can select one, two, or three of the provided ranges, in order to match your monitor's
capabilities. Keep in mind that ATOM-15 will always try to recalculate each BIOS' native
mode into the range which results in a better picture quality, from the ranges you allow
it to work with. For instance:

 - If both 15 and 31 kHz ranges are selected, then 640 x 480 will be calculated in the
   31 kHz range, to avoid using an interlaced mode.

 - If both 25 and 31 kHz ranges are selected, then 1024 x 768 will be calculated in the
   25 kHz range, as interlaced, to avoid requiring big black borders.

Besides, ATOM-15 will always readjust the vertical frequency so it falls within the
50-60 Hz range. This will prevent 31 kHz arcade monitors to go out of sync due to 400-line
BIOS modes that have a native vertical frequency of 70 Hz although their horizontal
frequency is 31 kHz.

For a detailed log of the BIOS native modes and how they're modified, use the "View log"
button.


Flash tools
-----------

You will need third party software in order to obtain the BIOS from your display card,
and to flash the modified BIOS back to the card. Your options are:

- ATIFlash: MS-DOS,  http://www.techpowerup.com/downloads/2306/atiflash-4-17/mirrors
            How-to: http://www.techpowerup.com/forums/threads/how-to-use-atiflash.57750/

    1) Boot into MS-DOS from a bootable USB disk, with atiflash.exe in it.
    2) atiflash -s 0 bios.rom
    3) Reboot, into Windows and use atom-15.exe to patch the BIOS, put it in your USB disk.
    4) Boot again into MS-DOS.
    5) atiflash -p 0 bios-mod.rom
    6) Reboot
    * Make sure to use short names in MS-DOS (8 characters + 3 for extension).
    * Caution: "-p 0" and "-s 0" point to the first PCI device. Check this in case you have
      more than one video card installed.

- ATI Winflash: Windows, http://www.techpowerup.com/downloads/2311/ati-winflash-2-6-7/

    1) cd C:\atiwinflash
    2) atiflash -s 0 bios.rom
    3) Use atom-15.exe to patch the BIOS.
    4) atiflash -p 0 bios-mod.rom
    5) Reboot
    * Caution: "-p 0" and "-s 0" point to the first PCI device. Check this in case you have
      more than one video card installed.

While ATI Winflash is very convenient, our preference is for ATIFlash (it requires
creating an MS-DOS usb boot disk), because from MS-DOS you can test your patched BIOS
before actually flashing it to the card, by means of "lbios", as explained below.


Using the BIOS loader lbios.com
-------------------------------

lbios.com is a simple BIOS loader. It loads a BIOS image into the system's RAM so it
takes control of the video card instead of its own ROM BIOS. You can use this tool
before actually flashing the patched BIOS to the video card, to reduce the chances of
flashing your card with a faulty BIOS. It is not guaranteed however that a BIOS that works
when loaded into the RAM won't leave your card unusable later when flashed to the actual
hardware: you're warned. But definitely, if the system hangs after running lbios, then
DO NOT flash the BIOS. The effects of lbios are not persistent, everything will be back
to normal after restarting the system.

lbios must be run from MS-DOS command line:

   c:\lbios romname.rom

To actually do a proper testing of the patched BIOS, you'll need to switch to different
video modes, both standard and VESA ones. For this task, I find this tool to be the
most convenient: http://www.filegate.net/utiln/utilnet/z.zip


UEFI notes
----------

ATOM-15 is not guaranteed to work with UEFI bios. It may work as long as the UEFI code uses
VESA modes. If this is the case, notice that probably UEFI will require the VESA mode
1024 x 768 to be available. This will be true if either the 25 or 31 kHz ranges are used.
Unfortunately 1024 x 768 is not possible for the 15 kHz range, so this mode is disabled
when only the 15 kHz range is used. In this case, entering the UEFI setup will result in
a black screen.


Source code
-----------

The full source code of this program for the PowerBASIC 10.04 compiler is available at:
http://geedorah.com/eiusdemmodi/

Version history
---------------

- v1.6 - October 2021
    - Added support R9 380/380X.

- v1.5 - December 2017
    - Added support for composite sync.
    - Reduced BIOS hook size by 40 bytes, now only 532 bytes of blank space are required.

- v1.4 - November 2017
    - Fixed bug that caused wrong checksum correction in some cases.

- v1.3 - March 2017
    - Implemented GOP reallocation for EFI bios.

- v1.2 - September 2016
    - Detect blank space as a combination of 0x00 and 0xFF characters.
    - Reduce by 256 bytes the size required by the BIOS hook, now only 572 bytes of blank
      space are needed to patch the BIOS.
    - Fixed bug that caused wrong checksum correction in some cases.

- v1.1 - October 2014
    - Fixed critical bug that affected older Radeon cards (the X series at least).

- v1.0 - October 2014
    - First version released.


