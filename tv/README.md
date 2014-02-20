Fibaro SAMSUNG TV
=================

FIBARO HC2 + SAMSUNG TV
http://fibaro.rafikel.pl (2013-2014)
Lincense: GPL. Donate: http://goo.gl/49n81K

LUA script for manage and usage Samsung TV in Fibaro.
Completely and in automatic way creates and configures
virtual device in HC2 for that purpose.

Needed:
1. Your name of device (eg. Samsung TV).
2. IP address and port (52235) for communication.
3. Login and password for HC2, entered in config section (below).

What script will do: 
1. Find TV on defined IP and grab all necessary data.
2. Prepare full sets of buttons to use by user in scenes 
   and user interfaces (like phone app and web page).
3. Auto update script by self if newer version comes.
4. Download images from server fibaro.rafikel.pl and store
   those in HC2 for later usage by this virtual device.
5. Create global variable to give state of device for users
   and scene usage (name of variable created from entered name).
6. In fully way gives possibility to control and read state
   of device in block scenes.

Instruction:
1. Create new virtual device in HC2.
2. Enter name for device (eg. "Samsung TV"), IP address and 
   port (eg. 52235).
3. Put content of this script to MainLoop.
4. Change login and password to correct values inside script.
5. Save virtual device and wait about 1-2 minutes. You can 
   observe progress in debug window.
6. If everything will work in right way, then you will see 
   ready device to usage!
