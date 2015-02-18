-- FIBARO HC2 + SAMSUNG TV
-- http://fibaro.rafikel.pl (2013-2014)
-- Lincense: GPL. Donate: http://goo.gl/49n81K

-- LUA script for manage and usage Samsung TV in Fibaro.
-- Completely and in automatic way creates and configures
-- virtual device in HC2 for that purpose.

-- Needed:
-- 1. Your name of device (eg. Samsung TV).
-- 2. IP address and port (52235) for communication.
-- 3. Login and password for HC2, entered in config section (below).

-- What script will do: 
-- 1. Find TV on defined IP and grab all necessary data.
-- 2. Prepare full sets of buttons to use by user in scenes 
--    and user interfaces (like phone app and web page).
-- 3. Auto update script by self if newer version comes.
-- 4. Download images from server fibaro.rafikel.pl and store
--    those in HC2 for later usage by this virtual device.
-- 5. Create global variable to give state of device for users
--    and scene usage (name of variable created from entered name).
-- 6. In fully way gives possibility to control and read state
--    of device in block scenes.

-- Instruction:
-- 1. Create new virtual device in HC2.
-- 2. Enter name for device (eg. "Samsung TV"), IP address and 
--    port (eg. 52235).
-- 3. Put content of this script to MainLoop.
-- 4. Change login and password to correct values inside script.
-- 5. Save virtual device and wait about 1-2 minutes. You can 
--    observe progress in debug window.
-- 6. If everything will work in right way, then you will see 
--    ready device to usage!

-- HC2 Credentials
-- Those are needed by script for proper working! Script will create
-- and setup content of virtual device without user, in automatic way!
-- Like buttons, global variables, icons, updates, etc. For that fully
-- access to HC2 is needed!
USER = "admin"
PASSWORD = "admin"

-- SERVER_CONTACT = 0 | 1 [Default = 1]
-- Script can contact with server (when starts) to get icons and check 
-- if version is up to date. Also new TV sets definitions available on
-- the server can be grabbed automaticly by this script. Set this 
-- option to value 0 if you want to keep yours icons and TV sets.
SERVER_CONTACT = 1

-- AUTO_UPDATE = 0 | 1 [Default = 1]
-- Automatic updates setup allow script to self update from server
-- fibaro.rafikel.pl. Script will not send any private data! Only
-- reading file from server and getting new version if it's needed.
-- Content of script will be swapped automaticly to new version.
-- User configuration for device will be safe in this case.
AUTO_UPDATE = 1

-- WAIT_TIME_AFTER_CHANGES = 0.. [Default = 10]
-- Time in seconds before script restarting after each step
-- of auto-configuration or initialization. For normal work
-- 5 seconds is enought, but for safe reasons keep default value 
-- and be sure everything is working in right way before change 
-- this to lower value!
WAIT_TIME_AFTER_CHANGES = 10

-- WAIT_TIME_AFTER_DISCONNECT = 0..60 [Default = 5]
-- Time in seconds before script will try to reconnect to device.
-- Lower value is better for best responsive but takes much more
-- power in HC2 and can even froze it!
WAIT_TIME_AFTER_DISCONNECT = 5

-- TV PORT FOR SENDKEY FUNCTION = 0..64000 [Default = 55000]
-- Communication port for sending keys to TV. Left default 55000
-- if you don't know what is it!
TV_SENDKEY_PORT = 55000

-- END OF CONFIGURATION SECTION!
-- Below is only code, working standalone without changes.
-- If you have good knowledge about programming and want to use
-- or change something, feel free! Remember to share yours
-- solution with others users. That's all!



--[[TV_SAMSUNG
  pl.rafikel.fibaro.tv.samsung
]]--

VERSION = "{0_2_2}"

--[[
  HISTORY
  
  0.3.0 (2015-02-18)
  - Fixed for HC 4.0

  0.2.2 (2014-02-27)
  - Fixed upnp communication.

  0.2.1 (2014-02-21)
  - Adjusted upnp reading timeouts.

  0.2.0 (2014-02-20)
  - Added upnp as optional services.

  0.1.0 (2014-02-18)
  - First beta version.
  
]]--



--[[
  ERRORS NUMS BEFORE SCRIPT WILL RESTART
]]--
ERRORS_BEFORE_RESTART = 2

--[[
  BUTTONS DEFINITION
]]--
local BUTTONS = '['..
  '{"type":"label","elements":[{"id":1,"lua":false,"waitForResponse":false,"caption":"State","name":"State","favourite":true,"main":true}]},'..
  '{"type":"button","elements":[{"id":2,"lua":false,"waitForResponse":false,"caption":"⎋ Power","name":"Power","empty":false,"msg":"KEY_POWEROFF","buttonIcon":0,"favourite":false,"main":true},{"id":3,"lua":false,"waitForResponse":false,"caption":"Source ⏏","name":"Source","empty":false,"msg":"KEY_SOURCE","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":4,"lua":false,"waitForResponse":false,"caption":"⇡ Vol","name":"VolUp","empty":false,"msg":"KEY_VOLUP","buttonIcon":0,"favourite":false,"main":false},{"id":5,"lua":false,"waitForResponse":false,"caption":"♬","name":"Mute","empty":false,"msg":"KEY_MUTE","buttonIcon":0,"favourite":false,"main":false},{"id":6,"lua":false,"waitForResponse":false,"caption":"Vol ⇣","name":"VolDown","empty":false,"msg":"KEY_VOLDOWN","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":7,"lua":false,"waitForResponse":false,"caption":"⇡ Prog","name":"ProgUp","empty":false,"msg":"KEY_CHUP","buttonIcon":0,"favourite":false,"main":false},{"id":8,"lua":false,"waitForResponse":false,"caption":"☷","name":"ChannelList","empty":false,"msg":"KEY_CH_LIST","buttonIcon":0,"favourite":false,"main":false},{"id":9,"lua":false,"waitForResponse":false,"caption":"Prog ⇣","name":"ProgDown","empty":false,"msg":"KEY_CHDOWN","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"slider","elements":[{"id":10,"lua":false,"waitForResponse":false,"caption":"Volume","name":"Volume","msg":"","buttonIcon":0,"value":0,"favourite":false,"main":true}]},'..
  '{"type":"slider","elements":[{"id":11,"lua":false,"waitForResponse":false,"caption":"Brightness","name":"Brightness","msg":"","buttonIcon":0,"value":0,"favourite":false,"main":false}]},'..
  '{"type":"slider","elements":[{"id":12,"lua":false,"waitForResponse":false,"caption":"Contrast","name":"Contrast","msg":"","buttonIcon":0,"value":0,"favourite":false,"main":false}]},'..
  '{"type":"slider","elements":[{"id":13,"lua":false,"waitForResponse":false,"caption":"Sharpness","name":"Sharpness","msg":"","buttonIcon":0,"value":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":14,"lua":false,"waitForResponse":false,"caption":"1 [.,-]","name":"Num1","empty":false,"msg":"KEY_1","buttonIcon":0,"favourite":false,"main":false},{"id":15,"lua":false,"waitForResponse":false,"caption":"2 [abc]","name":"Num2","empty":false,"msg":"KEY_2","buttonIcon":0,"favourite":false,"main":false},{"id":16,"lua":false,"waitForResponse":false,"caption":"3 [def]","name":"Num3","empty":false,"msg":"KEY_3","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":17,"lua":false,"waitForResponse":false,"caption":"4 [ghi]","name":"Num4","empty":false,"msg":"KEY_4","buttonIcon":0,"favourite":false,"main":false},{"id":18,"lua":false,"waitForResponse":false,"caption":"5 [jkl]","name":"Num5","empty":false,"msg":"KEY_5","buttonIcon":0,"favourite":false,"main":false},{"id":19,"lua":false,"waitForResponse":false,"caption":"6 [mno]","name":"Num6","empty":false,"msg":"KEY_6","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":20,"lua":false,"waitForResponse":false,"caption":"7 [pqrs]","name":"Num7","empty":false,"msg":"KEY_7","buttonIcon":0,"favourite":false,"main":false},{"id":21,"lua":false,"waitForResponse":false,"caption":"8 [tuv]","name":"Num8","empty":false,"msg":"KEY_8","buttonIcon":0,"favourite":false,"main":false},{"id":22,"lua":false,"waitForResponse":false,"caption":"9 [wxyz]","name":"Num9","empty":false,"msg":"KEY_9","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":23,"lua":false,"waitForResponse":false,"caption":"TText","name":"TeleText","empty":false,"msg":"KEY_TEXT","buttonIcon":0,"favourite":false,"main":false},{"id":24,"lua":false,"waitForResponse":false,"caption":"0 [ ]","name":"Num0","empty":false,"msg":"KEY_0","buttonIcon":0,"favourite":false,"main":false},{"id":25,"lua":false,"waitForResponse":false,"caption":"Pre-Ch","name":"PreChannel","empty":false,"msg":"KEY_PRECH","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"label","elements":[{"id":26,"lua":false,"waitForResponse":false,"caption":"Navigation","name":"Navigation","favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":27,"lua":false,"waitForResponse":false,"caption":"Content","name":"Content","empty":false,"msg":"KEY_CONTENT","buttonIcon":0,"favourite":false,"main":false},{"id":28,"lua":false,"waitForResponse":false,"caption":"MENU","name":"Menu","empty":false,"msg":"KEY_MENU","buttonIcon":0,"favourite":false,"main":false},{"id":29,"lua":false,"waitForResponse":false,"caption":"Guide","name":"Guide","empty":false,"msg":"KEY_GUIDE","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":30,"lua":false,"waitForResponse":false,"caption":"ⓘ Info","name":"Info","empty":false,"msg":"KEY_INFO","buttonIcon":0,"favourite":false,"main":false},{"id":31,"lua":false,"waitForResponse":false,"caption":"△","name":"Up","empty":false,"msg":"KEY_UP","buttonIcon":0,"favourite":false,"main":false},{"id":32,"lua":false,"waitForResponse":false,"caption":"Tools ⓟ","name":"Tools","empty":false,"msg":"KEY_TOOLS","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":33,"lua":false,"waitForResponse":false,"caption":"◁","name":"Left","empty":false,"msg":"KEY_LEFT","buttonIcon":0,"favourite":false,"main":false},{"id":34,"lua":false,"waitForResponse":false,"caption":"OK","name":"OK","empty":false,"msg":"KEY_ENTER","buttonIcon":0,"favourite":false,"main":false},{"id":35,"lua":false,"waitForResponse":false,"caption":"▷","name":"Right","empty":false,"msg":"KEY_RIGHT","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":36,"lua":false,"waitForResponse":false,"caption":"↺ Back","name":"Back","empty":false,"msg":"KEY_BACK\nKEY_RETURN","buttonIcon":0,"favourite":false,"main":false},{"id":37,"lua":false,"waitForResponse":false,"caption":"▽","name":"Down","empty":false,"msg":"KEY_DOWN","buttonIcon":0,"favourite":false,"main":false},{"id":38,"lua":false,"waitForResponse":false,"caption":"Exit ☷","name":"Exit","empty":false,"msg":"KEY_EXIT","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"label","elements":[{"id":39,"lua":false,"waitForResponse":false,"caption":"Player","name":"CurrentTransportState","favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":40,"lua":false,"waitForResponse":false,"caption":"⋘","name":"Backward","empty":false,"msg":"KEY_REWIND","buttonIcon":0,"favourite":false,"main":false},{"id":41,"lua":false,"waitForResponse":false,"caption":"►","name":"Play","empty":false,"msg":"KEY_PLAY","buttonIcon":0,"favourite":false,"main":false},{"id":42,"lua":false,"waitForResponse":false,"caption":"⋙","name":"Forward","empty":false,"msg":"KEY_FF","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":43,"lua":false,"waitForResponse":false,"caption":"◉","name":"Rec","empty":false,"msg":"KEY_REC","buttonIcon":0,"favourite":false,"main":false},{"id":44,"lua":false,"waitForResponse":false,"caption":"▮▮","name":"Pause","empty":false,"msg":"KEY_PAUSE","buttonIcon":0,"favourite":false,"main":false},{"id":45,"lua":false,"waitForResponse":false,"caption":"▇","name":"Stop","empty":false,"msg":"KEY_STOP","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"label","elements":[{"id":46,"lua":false,"waitForResponse":false,"caption":"Media","name":"Media","favourite":false,"main":false}]},'..
  '{"type":"slider","elements":[{"id":47,"lua":false,"waitForResponse":false,"caption":"Duration","name":"Duration","msg":"","buttonIcon":0,"value":0,"favourite":false,"main":false}]},'..
  '{"type":"label","elements":[{"id":48,"lua":false,"waitForResponse":false,"caption":"Presets","name":"Presets","favourite":false,"main":false}]},'..
  '{"type":"slider","elements":[{"id":49,"lua":true,"waitForResponse":false,"caption":"Channel","name":"Channel","msg":"","buttonIcon":0,"value":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":50,"lua":false,"waitForResponse":false,"caption":"Devil\'s channel...","name":"DevilChannel","empty":false,"msg":"CHANNEL_666","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":51,"lua":false,"waitForResponse":false,"caption":"Open network info","name":"NetworkInfo","empty":false,"msg":"KEY_EXIT\n\nKEY_MENU\n\n\n\n\nKEY_DOWN\nKEY_DOWN\nKEY_DOWN\n\n\n\nKEY_RIGHT\nKEY_DOWN\n\n\n\nKEY_RIGHT\n","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":52,"lua":false,"waitForResponse":false,"caption":"Test all keys","name":"TestKeys","empty":false,"msg":"KEY_0\nWAIT\nKEY_1\nWAIT\nKEY_2\nWAIT\nKEY_3\nWAIT\nKEY_4\nWAIT\nKEY_5\nWAIT\nKEY_6\nWAIT\nKEY_7\nWAIT\nKEY_8\nWAIT\nKEY_9\nWAIT\nKEY_11\nWAIT\nKEY_12\nWAIT\nKEY_3SPEED\nWAIT\nKEY_4_3\nWAIT\nKEY_16_9\nWAIT\nKEY_AD\nWAIT\nKEY_ADDDEL\nWAIT\nKEY_ALT_MHP\nWAIT\nKEY_ANGLE\nWAIT\nKEY_ANTENA\nWAIT\nKEY_ANYNET\nWAIT\nKEY_ANYVIEW\nWAIT\nKEY_APP_LIST\nWAIT\nKEY_ASPECT\nWAIT\nKEY_AUTO_ARC_ANTENNA_AIR\nWAIT\nKEY_AUTO_ARC_ANTENNA_CABLE\nWAIT\nKEY_AUTO_ARC_ANTENNA_SATELLITE\nWAIT\nKEY_AUTO_ARC_ANYNET_AUTO_START\nWAIT\nKEY_AUTO_ARC_ANYNET_MODE_OK\nWAIT\nKEY_AUTO_ARC_AUTOCOLOR_FAIL\nWAIT\nKEY_AUTO_ARC_AUTOCOLOR_SUCCESS\nWAIT\nKEY_AUTO_ARC_CAPTION_ENG\nWAIT\nKEY_AUTO_ARC_CAPTION_KOR\nWAIT\nKEY_AUTO_ARC_CAPTION_OFF\nWAIT\nKEY_AUTO_ARC_CAPTION_ON\nWAIT\nKEY_AUTO_ARC_C_FORCE_AGING\nWAIT\nKEY_AUTO_ARC_JACK_IDENT\nWAIT\nKEY_AUTO_ARC_LNA_OFF\nWAIT\nKEY_AUTO_ARC_LNA_ON\nWAIT\nKEY_AUTO_ARC_PIP_CH_CHANGE\nWAIT\nKEY_AUTO_ARC_PIP_DOUBLE\nWAIT\nKEY_AUTO_ARC_PIP_LARGE\nWAIT\nKEY_AUTO_ARC_PIP_LEFT_BOTTOM\nWAIT\nKEY_AUTO_ARC_PIP_LEFT_TOP\nWAIT\nKEY_AUTO_ARC_PIP_RIGHT_BOTTOM\nWAIT\nKEY_AUTO_ARC_PIP_RIGHT_TOP\nWAIT\nKEY_AUTO_ARC_PIP_SMALL\nWAIT\nKEY_AUTO_ARC_PIP_SOURCE_CHANGE\nWAIT\nKEY_AUTO_ARC_PIP_WIDE\nWAIT\nKEY_AUTO_ARC_RESET\nWAIT\nKEY_AUTO_ARC_USBJACK_INSPECT\nWAIT\nKEY_AUTO_FORMAT\nWAIT\nKEY_AUTO_PROGRAM\nWAIT\nKEY_AV1\nWAIT\nKEY_AV2\nWAIT\nKEY_AV3\nWAIT\nKEY_BACK_MHP\nWAIT\nKEY_BOOKMARK\nWAIT\nKEY_CALLER_ID\nWAIT\nKEY_CAPTION\nWAIT\nKEY_CATV_MODE\nWAIT\nKEY_CHDOWN\nWAIT\nKEY_CHUP\nWAIT\nKEY_CH_LIST\nWAIT\nKEY_CLEAR\nWAIT\nKEY_CLOCK_DISPLAY\nWAIT\nKEY_COMPONENT1\nWAIT\nKEY_COMPONENT2\nWAIT\nKEY_CONTENTS\nWAIT\nKEY_CONVERGENCE\nWAIT\nKEY_CONVERT_AUDIO_MAINSUB\nWAIT\nKEY_CUSTOM\nWAIT\nKEY_CYAN\nWAIT\nKEY_BLUE\nWAIT\nKEY_DEVICE_CONNECT\nWAIT\nKEY_DISC_MENU\nWAIT\nKEY_DMA\nWAIT\nKEY_DNET\nWAIT\nKEY_DNIe\nWAIT\nKEY_DNSe\nWAIT\nKEY_DOOR\nWAIT\nKEY_DOWN\nWAIT\nKEY_DSS_MODE\nWAIT\nKEY_DTV\nWAIT\nKEY_DTV_LINK\nWAIT\nKEY_DTV_SIGNAL\nWAIT\nKEY_DVD_MODE\nWAIT\nKEY_DVI\nWAIT\nKEY_DVR\nWAIT\nKEY_DVR_MENU\nWAIT\nKEY_DYNAMIC\nWAIT\nKEY_ENTER\nWAIT\nKEY_ENTERTAINMENT\nWAIT\nKEY_ESAVING\nWAIT\nKEY_EXIT\nWAIT\nKEY_EXT1\nWAIT\nKEY_EXT2\nWAIT\nKEY_EXT3\nWAIT\nKEY_EXT4\nWAIT\nKEY_EXT5\nWAIT\nKEY_EXT6\nWAIT\nKEY_EXT7\nWAIT\nKEY_EXT8\nWAIT\nKEY_EXT9\nWAIT\nKEY_EXT10\nWAIT\nKEY_EXT11\nWAIT\nKEY_EXT12\nWAIT\nKEY_EXT13\nWAIT\nKEY_EXT14\nWAIT\nKEY_EXT15\nWAIT\nKEY_EXT16\nWAIT\nKEY_EXT17\nWAIT\nKEY_EXT18\nWAIT\nKEY_EXT19\nWAIT\nKEY_EXT20\nWAIT\nKEY_EXT21\nWAIT\nKEY_EXT22\nWAIT\nKEY_EXT23\nWAIT\nKEY_EXT24\nWAIT\nKEY_EXT25\nWAIT\nKEY_EXT26\nWAIT\nKEY_EXT27\nWAIT\nKEY_EXT28\nWAIT\nKEY_EXT29\nWAIT\nKEY_EXT30\nWAIT\nKEY_EXT31\nWAIT\nKEY_EXT32\nWAIT\nKEY_EXT33\nWAIT\nKEY_EXT34\nWAIT\nKEY_EXT35\nWAIT\nKEY_EXT36\nWAIT\nKEY_EXT37\nWAIT\nKEY_EXT38\nWAIT\nKEY_EXT39\nWAIT\nKEY_EXT40\nWAIT\nKEY_EXT41\nWAIT\nKEY_FACTORY\nWAIT\nKEY_FAVCH\nWAIT\nKEY_FF\nWAIT\nKEY_FF_\nWAIT\nKEY_FM_RADIO\nWAIT\nKEY_GAME\nWAIT\nKEY_GREEN\nWAIT\nKEY_GUIDE\nWAIT\nKEY_HDMI\nWAIT\nKEY_HDMI1\nWAIT\nKEY_HDMI2\nWAIT\nKEY_HDMI3\nWAIT\nKEY_HDMI4\nWAIT\nKEY_HELP\nWAIT\nKEY_HOME\nWAIT\nKEY_ID_INPUT\nWAIT\nKEY_ID_SETUP\nWAIT\nKEY_INFO\nWAIT\nKEY_INSTANT_REPLAY\nWAIT\nKEY_LEFT\nWAIT\nKEY_LINK\nWAIT\nKEY_LIVE\nWAIT\nKEY_MAGIC_BRIGHT\nWAIT\nKEY_MAGIC_CHANNEL\nWAIT\nKEY_MDC\nWAIT\nKEY_MENU\nWAIT\nKEY_MIC\nWAIT\nKEY_MORE\nWAIT\nKEY_MOVIE1\nWAIT\nKEY_MS\nWAIT\nKEY_MTS\nWAIT\nKEY_MUTE\nWAIT\nKEY_NINE_SEPERATE\nWAIT\nKEY_OPEN\nWAIT\nKEY_PANNEL_CHDOWN\nWAIT\nKEY_PANNEL_CHUP\nWAIT\nKEY_PANNEL_ENTER\nWAIT\nKEY_PANNEL_MENU\nWAIT\nKEY_PANNEL_POWER\nWAIT\nKEY_PANNEL_SOURCE\nWAIT\nKEY_PANNEL_VOLDOW\nWAIT\nKEY_PANNEL_VOLUP\nWAIT\nKEY_PANORAMA\nWAIT\nKEY_PAUSE\nWAIT\nKEY_PCMODE\nWAIT\nKEY_PERPECT_FOCUS\nWAIT\nKEY_PICTURE_SIZE\nWAIT\nKEY_PIP_CHDOWN\nWAIT\nKEY_PIP_CHUP\nWAIT\nKEY_PIP_ONOFF\nWAIT\nKEY_PIP_SCAN\nWAIT\nKEY_PIP_SIZE\nWAIT\nKEY_PIP_SWAP\nWAIT\nKEY_PLAY\nWAIT\nKEY_PLUS100\nWAIT\nKEY_PMODE\nWAIT\nKEY_POWER\nWAIT\nKEY_POWEROFF_\nWAIT\nKEY_POWERON\nWAIT\nKEY_PRECH\nWAIT\nKEY_PRINT\nWAIT\nKEY_PROGRAM\nWAIT\nKEY_QUICK_REPLAY\nWAIT\nKEY_REC\nWAIT\nKEY_RED\nWAIT\nKEY_REPEAT\nWAIT\nKEY_RESERVED1\nWAIT\nKEY_RETURN\nWAIT\nKEY_REWIND\nWAIT\nKEY_REWIND_\nWAIT\nKEY_RIGHT\nWAIT\nKEY_RSS\nWAIT\nKEY_INTERNET\nWAIT\nKEY_RSURF\nWAIT\nKEY_SCALE\nWAIT\nKEY_SEFFECT\nWAIT\nKEY_SETUP_CLOCK_TIMER\nWAIT\nKEY_SLEEP\nWAIT\nKEY_SOUND_MODE\nWAIT\nKEY_SOURCE\nWAIT\nKEY_SRS\nWAIT\nKEY_STANDARD\nWAIT\nKEY_STB_MODE\nWAIT\nKEY_STILL_PICTURE\nWAIT\nKEY_STOP\nWAIT\nKEY_SUB_TITLE\nWAIT\nKEY_SVIDEO1\nWAIT\nKEY_SVIDEO2\nWAIT\nKEY_SVIDEO3\nWAIT\nKEY_TOOLS\nWAIT\nKEY_TOPMENU\nWAIT\nKEY_TTX_MIX\nWAIT\nKEY_TTX_SUBFACE\nWAIT\nKEY_TURBO\nWAIT\nKEY_TV\nWAIT\nKEY_TV_MODE\nWAIT\nKEY_UP\nWAIT\nKEY_VCHIP\nWAIT\nKEY_VCR_MODE\nWAIT\nKEY_VOLDOWN\nWAIT\nKEY_VOLUP\nWAIT\nKEY_WHEEL_LEFT\nWAIT\nKEY_WHEEL_RIGHT\nWAIT\nKEY_W_LINK\nWAIT\nKEY_YELLOW\nWAIT\nKEY_ZOOM1\nWAIT\nKEY_ZOOM2\nWAIT\nKEY_ZOOM_IN\nWAIT\nKEY_ZOOM_MOVE\nWAIT\nKEY_ZOOM_OUT","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":53,"lua":false,"waitForResponse":false,"caption":"Screen ON","name":"ScreenOn","empty":false,"msg":"KEY_POWERON\nKEY_VOLUP\nKEY_VOLDOWN","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":54,"lua":false,"waitForResponse":false,"caption":"Screen OFF","name":"ScreenOff","empty":false,"msg":"KEY_STANDARD\n\nKEY_VOLUP\nKEY_VOLDOWN\n\nKEY_MUTE\n\n\nKEY_ESAVING\n\nKEY_ESAVING\n\nKEY_ESAVING\n\nKEY_ESAVING\n\nKEY_ESAVING\n","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":55,"lua":false,"waitForResponse":false,"caption":"HDMI1","name":"HDMI1","empty":false,"msg":"KEY_EXT20","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":56,"lua":false,"waitForResponse":false,"caption":"HDMI2","name":"HDMI2","empty":false,"msg":"KEY_AUTO_ARC_PIP_WIDE","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":57,"lua":false,"waitForResponse":false,"caption":"HDMI3","name":"HDMI3","empty":false,"msg":"KEY_AUTO_ARC_PIP_RIGHT_BOTTOM","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":58,"lua":false,"waitForResponse":false,"caption":"HDMI4","name":"HDMI4","empty":false,"msg":"KEY_AUTO_ARC_AUTOCOLOR_FAIL","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":59,"lua":false,"waitForResponse":false,"caption":"Play demo MP4","name":"DemoMp4","empty":false,"msg":"http://techslides.com/demos/sample-videos/small.mp4","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":60,"lua":false,"waitForResponse":false,"caption":"Play demo MPEG2","name":"DemoMpeg2","empty":false,"msg":"http://hubblesource.stsci.edu/sources/video/clips/details/images/centaur_1.mpg","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":60,"lua":false,"waitForResponse":false,"caption":"Show demo JPEG","name":"DemoJpeg","empty":false,"msg":"http://www.fibaro.com/sites/default/files/headers/top_01_0_0.jpg","buttonIcon":0,"favourite":false,"main":false}]}'..
']';

--[[
  EXTRA FUNCTIONS
]]--
-- counting elements in array (table)
function count(tab) local k,v,i; i=0; for k, v in pairs(tab) do i = i + 1; end return i; end
-- xor bits operation
function bxor(a, b) local x,i,r;r=0; for i = 0, 31 do x = a / 2 + b / 2; if (x~=math.floor(x)) then r = r + 2^i; end a = math.floor(a / 2); b = math.floor(b / 2); end return r; end
-- calculate checksum
function checkSum(t) local i,b,c;c=0; for i = 1, #t do b = string.byte(t, i); if (c==0) then c = b; else c = bxor(c, b); end if (i>100) then break; end end return c; end
-- encoding to base64 
function encode(data) local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'; return ((data:gsub('.', function(x) local r,b='',x:byte() for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end return r; end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x) if (#x < 6) then return '' end local c=0 for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end return b:sub(c+1,c+1) end)..({ '', '==', '=' })[#data%3+1]) end 
-- integer to hex string
function num2hex(n) local i;local r="";for i=1,2 do r=r..string.char(n%256);n=math.floor(n/256);end return r;end
-- random string
function random(nums) local i,r;r="";for i=1,nums do r=r..tostring(math.random(0,9)); end; return r; end
-- trim string to varaible standard
function trim(name) local g=""; for v in string.gmatch(name, "%w") do if (g=="") then for sv in string.gmatch(v, "%a") do g = g .. sv; end else g = g .. v; end end return g; end
-- print any variable content
function printr(v,l,k) local d=function(t)fibaro:debug(t);end if(not l)then l=0;end local s=string.rep(string.char(0xC2,0xA0),(l*3)); local n="";if(k)then n=k.." = ";end if(v and type(v))then if(type(v)=="table")then d(s..n.."{");local i,j;for i,j in pairs(v)do printr(j,(l+1),tostring(i));end d(s.."}");elseif(type(v)=="function")then d(s..n..tostring(v).."() {");d(s.."}");elseif(type(v)=="userdata")then d(s..n..tostring(v).."() {");d(s.."}");elseif(type(v)=="string")then if(#v>50)then d(s..n.."String["..#v.."] = \""..string.sub(v,1,50).."\"...");else if(k)then v="\""..v.."\"";end d(s..n..tostring(v));end elseif(type(v)=="number")then d(s..n..tostring(v));else d(s..n..tostring(v).."["..type(v).."]");end else d(s..n.."{nil}");end end

--[[
  XML FUNCTIONS
--]]
function XML(content, property) -- valueFromXML
  local s = string.find(content, "<" .. property .. ">");
  local e = string.find(content, "</" .. property .. ">");
  if (s and e) then
    local m = string.match(content, "<" .. property .. ">(.-)</" .. property .. ">");
    local sl = string.len("<" .. property .. ">");
    local el = string.len("</" .. property .. ">");
    local fs = string.sub(content, 0, s-1);
    local te = string.sub(content, e + el);
    return m, fs .. te;
  end
  return nil, content;
end

--[[
  PROTECTION FOR FROZEN
  If something in this beta script will froze the HC2,
  then you can break the loop by setting global variable
  "SafeState" = 1 for break loop or = 2 for stop script.
--]]
local safeX = fibaro:getGlobal("SafeState");
function delay(ms)
  fibaro:sleep(ms);
end
function X(valX)
  local globX = fibaro:getGlobal("SafeState");
  if (not globX) then
    safeX = valX;
    --delay(1);
    return true;
  end
  if (globX=="1") then
    fibaro:setGlobal("SafeState", valX);
    fibaro:debug("SKIP [" .. valX .. "][" .. safeX .. "]...");
    return false;
  end
  if (globX=="2") then
  fibaro:setGlobal("SafeState", valX);
    fibaro:debug("ABORT [" .. valX .. "][" .. safeX .. "]...");
    fibaro:abort();
    return false;
  end
  safeX = valX;
  --delay(1);
  return true;
end



--[[
  SETUP
]]--

-- connection resources
local tcpHC2 = nil;
local tcpSERVER = nil;

-- declare button captions for icons
local buttonAtIcon = {};

-- declare actions for icons
local actionAtIcon = {};

-- ip address of device
local virtualIP = nil;
-- port for tcp reqests
local virtualPort = nil;
-- id of virtual device
local virtualId = nil;

-- global variable name
local globalName = nil;

-- icons
local IconsDef = {
  [-1] = "tv_err.png",
  [0] = "tv_off.png",
  [1] = "tv_on.png"
};
local Icons = {
  [-1] = 0,
  [0] = 0,
  [1] = 0
};



--[[
  STATUS
]]--
local actualState = 0;
function setState(newState, description)
  -- change state?
  if (newState~=nil and tonumber(newState)) then
    newState = tonumber(newState);
    -- set global variable
    if (globalName) then
      local gl = fibaro:getGlobalValue(globalName);
      if (gl and gl~=tostring(newState)) then
        fibaro:setGlobal(globalName, tostring(newState));
      end
    end
  end
  -- set actualState
  if (newState~=nil) then
    actualState = newState;
  end
  -- set icon
  local icon = Icons[actualState];
  if (virtualId and virtualId>0) then
    if (not icon or not tonumber(icon)) then
      icon = 0;
    end
    fibaro:call(virtualId, "setProperty", "currentIcon", icon);
  end
  -- print description
  if (description) then
    -- debug
    fibaro:debug(description);
    -- log on home screen
    fibaro:log(description);
    -- state label
    if (virtualId and virtualId>0) then
      fibaro:call(virtualId, "setProperty", "ui.State.value",  description:sub(1,15));
    end
  end
end



--[[
  READ THIS VIRTUAL DEVICE (id, ip, port)
--]]
function readVirtualDevice(tcp)
  -- future function to get this id
  -- fibaro:debug("Self ID: " .. fibaro:getSelfId());
  -- generate random string
  local rnd = random(32);
  -- send random string
  fibaro:log(rnd);
  -- grab virtual devices list from api
  local response, status, errorCode = tcp:GET("/api/virtualDevices");
  -- show status on debug window
  --fibaro:debug("Status of reqest: " .. status .. '.');
  -- if answer is wrong
  if (tonumber(status)~=200) then
    fibaro:log("");
    fibaro:debug("Error " .. errorCode .. ".");
    return nil, nil, nil, nil, nil;
  -- if answer is ok?
  else
    -- decode text to json object
    local jsonTable = json.decode(response);
    -- roll over all virtual devices
    --fibaro:debug("Checking configuration...");
    for virtualIndex, virtualData in pairs(jsonTable) do
      -- fibaro:debug('Virtual Device Id [' .. virtualData.id .. ']');
      -- if virtual device type and name is right?
      if (virtualData.type=="virtual_device") then
        local check = string.find(fibaro:get(virtualData.id, "log"), rnd);
        if (check and check>0) then
          fibaro:log("");
          return
            virtualData.id, 
            virtualData.name, 
            virtualData.properties.ip, 
            virtualData.properties.port, 
            virtualData.properties.deviceIcon
          ;
        end
      end
    end
  end
  fibaro:log("");
  return nil, nil, nil, nil, nil;
end

--[[
  GRAB FILE FROM SERVER
--]]
function getFileFromServer(tcp, path)
  r, s, e = tcp:GET(path);
  if (tonumber(s)~=200) then
    return 0, nil;
  else
    return string.len(r), r;
  end
  return nil;
end

--[[
  GET ID OF ICON MATH TO...
]]--
function getIconId(tcp, rawIcon)
  -- grab icons list from api
  response, status, errorCode = tcp:GET("/api/icons");
  -- if answer is wrong
  if (tonumber(status)~=200) then
    return nil;
  -- if answer is ok?
  else
    -- decode text to json object
    jsonTable = json.decode("[" .. response .. "]");
    -- look at device
    iconsArray = jsonTable[1].virtualDevice;
    -- check all icons
    for iconIndex, iconData in pairs(iconsArray) do
      if (iconData.id>=1000) then
        -- grab icon from HC2
        r, s, e = tcp:GET("/fibaro/n_vicons/" .. iconData.iconName .. ".png");
        if (s=="200" and e==0) then
          --fibaro:debug('  Icon [' .. iconData.id .. '][' .. iconData.iconName .. '][' .. string.len(r) .. ' bytes]');
          if (string.len(r)==string.len(rawIcon)) then
            if (checkSum(r)==checkSum(rawIcon)) then
              --fibaro:debug("FOUND [" .. iconData.id .. "]!");
              return iconData.id;
            end
          end
        end
      end
    end
  end
  return 0;
end

--[[
  UPLOAD ICON TO HC2
]]--
function uploadIcon(login, pass, rawIcon)
  fibaro:debug("---");
  fibaro:debug("Uploading icon to HC2...");
  tcp = Net.FTcpSocket("localhost", 80);
  if (not tcp) then
    fibaro:debug("TCP CONNECTING WITH HC2 ERROR!");
    return nil;
  end
  boundary = "WebKitFormBoundaryEy7xZuy1Trv7QrDe";
  enter = "\r\n";
  content = 
    "------" .. boundary .. enter ..
    "Content-Disposition: form-data; name=\"type\"" .. enter ..
    enter ..
    "virtualDevice" .. enter ..
    "------" .. boundary .. enter ..
    "Content-Disposition: form-data; name=\"icon0\"; filename=\"icon.png\"" .. enter ..
    "Content-Type: image/png" .. enter ..
    enter ..
    rawIcon .. enter ..
    "------" .. boundary .. "--" .. enter;
  tcp:write("POST /api/icons HTTP/1.1" .. enter);
  tcp:write("Host: localhost" .. enter);
  tcp:write("Content-Length: " .. string.len(content) .. enter);
  tcp:write("Authorization: Basic " .. encode(USER..":"..PASSWORD) .. enter);
  tcp:write("Content-Type: multipart/form-data; boundary=----" .. boundary .. enter .. enter);
  --fibaro:debug("Sending " .. #content .. " content bytes..." .. enter);
  s = 0; for i = 1, #content do
    b, e = tcp:write(string.char(string.byte(content, i)));
    s = s + b;
  end
  status, err = tcp:read();
  tcp:disconnect();
  fibaro:debug("Sended " .. s .. " content bytes with result [" .. err .. "].");
  -- if answer is wrong
  if (tonumber(err)>0) then
    return nil;
  end
  -- finishing
  fibaro:debug("---");
  fibaro:debug("ICON SUCESSFULLY UPLOADED!");
  return 0;
end

--[[
  PREPARE VIRTUAL DEVICE (buttons and icons)
--]]
function prepareVirtualDevice(tcp, id, mainIcon)
  -- button captions for icons
  buttons = {};
  -- channel numbers for icons
  actions = {};
  -- value to count ready buttons
  ready = 0;
  -- value to count changes in buttons
  changes = 0;
  -- type of change to made (icons, buttons)
  changeType = nil;
  -- grab virtual devices list from api
  response, status, errorCode = tcp:GET("/api/virtualDevices/" .. id);
  -- show status on debug window
  --fibaro:debug("Status of reqest: " .. status .. '.');
  -- if answer is wrong
  if (tonumber(status)~=200) then
    fibaro:debug("Error " .. errorCode .. ".");
    return nil, nil, nil, nil;
  -- if answer is ok?
  else
    -- decode text to json object
    jsonTable = json.decode("[" .. response .. "]");
    -- look at device
    virtualData = jsonTable[1];
    -- if virtual device is right?
    if (virtualData and virtualData.type=="virtual_device" and virtualData.id==id) then
      -- change main icon?
      if (mainIcon and mainIcon>=1000 and virtualData.properties.deviceIcon<1000) then
        jsonTable[1].properties.deviceIcon = mainIcon;
        changes = changes + 1;
        changeType = "mainIcon";
      end
      -- check all rows
      for rowIndex, rowData in pairs(virtualData.properties.rows) do
        -- fibaro:debug('  Row [' .. rowIndex .. '][' .. rowData.type .. ']');
        -- if row type is button
        if (rowData.type=='button') then
          -- check all buttons in row
          for buttonIndex, buttonData in pairs(rowData.elements) do
            -- check button content
            icon = (id * 100000) + buttonData.id;
            buttons[icon] = buttonData.caption;
            actions[icon] = buttonData.msg;
            -- check icon of button
            if (buttonData.buttonIcon~=icon) then
              jsonTable[1].properties.rows[rowIndex].elements[buttonIndex].buttonIcon = icon;
              changes = changes + 1;
              changeType = "icons";
            else
              ready = ready + 1;
            end
          end -- check all buttons in row
        end -- if row type is button
      end -- check all rows
      -- no property rows defined?
      if (changes<1 and ready<1) then
        -- DEFINE ALL NEW BUTTONS
        jsonTable[1].properties.rows = json.decode(BUTTONS);
        changes = count(jsonTable[1].properties.rows);
        changeType = "buttons";
      end -- no more to check
    end -- if virtual device is right?
    -- if something was changed?
    if (changes>0 and changeType) then
      -- show status on debug window
      if (changeType=="icons") then
        fibaro:debug("Icons to buttons [" .. changes .. "] assigned!");
      elseif (changeType=="buttons") then
        fibaro:debug("New buttons [" .. changes .. "] created!");
      elseif (changeType=="mainIcon") then
        fibaro:debug("Main Icon changed!");
      end
      -- encode json back to text
      toPut = json.encode(jsonTable[1]);
      -- finishing
      fibaro:debug("---");
      fibaro:debug("NEW CONFIGURATION READY TO SAVE!");
      fibaro:debug("New session should start in a moment...");
      fibaro:debug("PLEASE BE PATIENT!");
      setState(nil, "WAIT [" .. WAIT_TIME_AFTER_CHANGES .. " s.]...");
      delay(WAIT_TIME_AFTER_CHANGES * 1000);
      fibaro:debug("...");
      -- put to HC2
      response, status, errorCode = tcp:PUT("/api/virtualDevices/" .. id, toPut);
      -- result?
      fibaro:debug("REQEST [" .. status .. "][" .. errorCode .. "][" .. string.len(response) .. "]");
      -- not happend!
      fibaro:abort();
      -- finish
      return nil, nil, nil;
    else
      -- return tables
      return ready, buttons, actions;
    end
  end
  -- return empty
  return nil, nil, nil;
end


--[[
  SET DEVICE PARAMETER
--]]
function setVDeviceParam(tcp, id, key, value)
  -- grab virtual devices list from api
  response, status, errorCode = tcp:GET("/api/virtualDevices/" .. id);
  -- if answer is wrong
  if (tonumber(status)~=200) then
    fibaro:debug("Error " .. errorCode .. ".");
    return false;
  end
  -- decode text to json object
  jsonTable = json.decode("[" .. response .. "]");
  -- look at device
  virtualData = jsonTable[1];
  -- if virtual device is right?
  if (virtualData and virtualData.type=="virtual_device" and virtualData.id==id) then
    -- change param?
    jsonTable[1].properties.mainLoop = value;
    -- encode json back to text
    toPut = json.encode(jsonTable[1]);
    -- finishing
    fibaro:debug("---");
    fibaro:debug("NEW CONFIGURATION READY TO SAVE!");
    fibaro:debug("New session should start in a moment...");
    fibaro:debug("PLEASE BE PATIENT!");
    setState(nil, "WAIT [" .. WAIT_TIME_AFTER_CHANGES .. " s.]...");
    delay(WAIT_TIME_AFTER_CHANGES * 1000);
    fibaro:debug("...");
    -- put to HC2
    response, status, errorCode = tcp:PUT("/api/virtualDevices/" .. id, toPut);
    -- result?
    fibaro:debug("REQEST [" .. status .. "][" .. errorCode .. "][" .. string.len(response) .. "]");
    -- not happend!
    fibaro:abort();
    -- finish
    return true;
  end
  -- return
  return false;
end

--[[
  PREPARE GLOBAL VARIABLE
]]--
function prepareGlobal(tcp, name, enums)
  local gName = trim(name);
  local value, ts; value, ts = fibaro:getGlobal(gName);
  -- fibaro:debug("CREATE [" .. gName .. ']...');
  if (value and ts > 0) then
    fibaro:debug("Global [" .. gName .. '] = [' .. value .. '].');
  else
    local payload, response, status, errorCode;
    response, status, errorCode = tcp:POST("/api/globalVariables", "name=" .. gName .. "&value=0");
    -- fibaro:debug("Status of reqest: " .. status .. '.');
    if (errorCode==0 and tonumber(status)<400) then
      fibaro:debug("Global variable [" .. gName .. '] created OK.');
    else
      fibaro:debug("Global variable [" .. gName .. '] Error!');
      gName = nil;
    end
  end
  if (gName) then
    if (enums and type(enums)=="table") then
      -- printr(enums, 0, "DEFINE");
      payload = '{"name":"' .. gName .. '","value":"","isEnum":true,"enumValues":[';
      for k, v in pairs(enums) do
        if (k > 1) then
          payload = payload .. ',';
        end
        payload = payload .. '"' .. v .. '"';
      end
      payload = payload .. ']}';
      response, status, errorCode = tcp:PUT("/api/globalVariables", payload);
      -- fibaro:debug("Status of reqest: " .. status .. '.');
      fibaro:setGlobal(gName, enums[1]);
    else
      fibaro:setGlobal(gName, "0");
    end
  end
  return gName;
end



--[[
  PREPARE AND SETUP
]]--

-- starting setup
setState(0, "SETUP...");

-- connect to HC2
fibaro:debug("Connecting to HC2...");
if (not tcpHC2) then
  tcpHC2 = Net.FHttp("localhost", 80);
end
if (not tcpHC2) then
  setState(-1, "HC2 ERROR!");
  fibaro:abort();
end

-- authentication for HC2
tcpHC2:setBasicAuthentication(USER, PASSWORD);

-- read virtual device
fibaro:debug("Searching virtual device...");
virtualId, virtualName, virtualIP, virtualPort, virtualIcon = readVirtualDevice(tcpHC2);
if (virtualId) then
  fibaro:debug('Found ID [' .. virtualId .. ']');
  if (virtualName) then
    fibaro:debug('Name [' .. virtualName .. ']');
  end
  if (virtualIcon) then
    fibaro:debug('Default icon id [' .. virtualIcon .. ']');
    for k, v in pairs(Icons) do
      Icons[k] = virtualIcon;
    end
  end
  if (virtualIP and virtualPort) then
    fibaro:debug('IP [' .. virtualIP .. ']');
    fibaro:debug('Port [' .. virtualPort .. ']');
  else
    if (not virtualIP) then
      setState(-1, 'NO IP!');
    end
    if (not virtualPort) then
      setState(-1, 'NO PORT!');
    end
    fibaro:abort();
  end
else
  setState(-1, "ERROR!");
  fibaro:abort();
end

-- CHECK SERVER
if (SERVER_CONTACT > 0) then
  fibaro:debug("---");
  setState(nil, "LOGIN TO SERVER...");
  -- connect to server
  fibaro:debug("Connecting to [fibaro.rafikel.pl]...");
  tcpSERVER = Net.FHttp("fibaro.rafikel.pl", 80);
  if (not tcpSERVER) then
    fibaro:debug("SERVER ERROR! Skipping...");
  else
  
    if (AUTO_UPDATE==1) then
      fibaro:debug("---");
      setState(nil, "CHECK UPDATES...");
      size, content  = getFileFromServer(tcpSERVER, "/lua/tv/samsung.lua");
      if (size>0) then
        fibaro:debug("Received script [" .. size .. " bytes].");
        s_ver = string.match(content, "{(.-)}");
        l_ver = string.match(VERSION, "{(.-)}");
        if (s_ver==nil or l_ver==nil) then
          fibaro:debug("Parsing problem! Skipping...");
        else
          fibaro:debug("Server version [" .. s_ver .. "].");
          fibaro:debug("This version [" .. l_ver .. "].");
          if (s_ver and s_ver==l_ver) then
            fibaro:debug("Script is up to date!");
          else
            fibaro:debug("NEW VERSION AVAILABLE!");
            setState(nil, "UPDATE SCRIPT...");
            content = string.gsub(content, 'USER = "admin"', 'USER = "' .. USER .. '"');
            content = string.gsub(content, 'PASSWORD = "admin"', 'PASSWORD = "' .. PASSWORD .. '"');
            content = string.gsub(content, 'SERVER_CONTACT = 1', 'SERVER_CONTACT = ' .. SERVER_CONTACT);
            content = string.gsub(content, 'AUTO_UPDATE = 1', 'AUTO_UPDATE = ' .. AUTO_UPDATE);
            content = string.gsub(content, 'WAIT_TIME_AFTER_CHANGES = 10', 'WAIT_TIME_AFTER_CHANGES = ' .. WAIT_TIME_AFTER_CHANGES);
            content = string.gsub(content, 'WAIT_TIME_AFTER_DISCONNECT = 5', 'WAIT_TIME_AFTER_DISCONNECT = ' .. WAIT_TIME_AFTER_DISCONNECT);
            content = string.gsub(content, 'TV_SENDKEY_PORT = 55000', 'TV_SENDKEY_PORT = ' .. TV_SENDKEY_PORT);
            setVDeviceParam(tcpHC2, virtualId, "mainLoop", content);
            fibaro:debug("DONE!");
          end
        end
      else
        fibaro:debug("Connection problem! Skipping...");
      end
    end
    
    -- get icons from fibaro.rafikel.pl
    fibaro:debug("---");
    setState(nil, "CHECK ICONS...");
    -- all icon
    for k, v in pairs(IconsDef) do
      iconSize, iconRaw  = getFileFromServer(tcpSERVER, "/icons/" .. IconsDef[k]);
      if (iconSize and iconSize>0) then
        fibaro:debug("Icon [" .. IconsDef[k] .. "][" .. iconSize .. " bytes]...");
        id = getIconId(tcpHC2, iconRaw);
        if (id and tonumber(id) and id<1000) then
          fibaro:debug("NOT FOUND. Upload icon to HC2...");
          id = uploadIcon(user, password, iconRaw);
        end
        if (id and tonumber(id) and id>=1000) then
          fibaro:debug("FOUNDED [" .. IconsDef[k] .. "][" .. id .. "] ON HC2!");
          Icons[k] = id;
        end
      else
        fibaro:debug("Connection problem! Skipping...");
        break;
      end
    end -- all icons
    
  end
end

-- PREPARE VIRTUAL
fibaro:debug("---");
setState(nil, "CHECK HC2...");

-- Global variable
fibaro:debug("Creating global variables base on [" .. virtualName .. "]...");
globalName = prepareGlobal(tcpHC2, virtualName);
if (not globalName) then
  setState(-1, "ERROR GLOBAL!");
  fibaro:abort();
end

-- Buttons
fibaro:debug("Prepare buttons on virtual device [" .. virtualId .. "]...");
ready, buttonAtIcon, actionAtIcon = prepareVirtualDevice(tcpHC2, virtualId, Icons[0]);
if (ready and tonumber(ready)) then
  fibaro:debug("All buttons [" .. ready .. "] prepared and ready!");
else
  setState(-1, "ERROR VIRTUAL!");
  fibaro:abort();
end



--[[
  SEND KEY TO SAMSUNG TV
]]--
function SamsungSendKey(ip, port, val)
  local tcpSocket = Net.FTcpSocket(ip, port);
  if (not tcpSocket) then
    return false;
  end
  tcpSocket:setReadTimeout(100);
  if (val and val~="KEY_NULL") then
    local key = encode(val);
  local body = num2hex(#key) .. key;
    local wr, err;
    wr, err = tcpSocket:write(
      string.char(0x00)..
      string.char(0x14,0x00).."iphone..iapp.samsung"..
      string.char(0x50,0x00)..
      string.char(0x64,0x00)..
      string.char(0x18,0x00).."ZmliYXJvLnJhZmlrZWwucGw="..
      string.char(0x28,0x00).."c2Ftc3VuZy50di5maWJhcm8ucmFmaWtlbC5wbA=="..
      string.char(0x08,0x00).."RmliYXJv"..
      string.char(0x00)..
      string.char(0x13,0x00).."iphone.iapp.samsung"..
      num2hex(#body + 3)..
      string.char(0x00,0x00,0x00)..
      body
    );
    if (err==0) then
      e, r = tcpSocket:read();
      --fibaro:debug("E(" .. e .. ") R(" .. r .. ")");
      tcpSocket:disconnect();
      return true;
    end
  end
  tcpSocket:disconnect();
  return false;
end

--[[
  SEND UPNP REQEST
]]--
function UPNPReqest(ip, port, upnpUrl, upnpService, upnpFunction, upnpContent)
  local tcpSocket = Net.FTcpSocket(ip, port);
  if (not tcpSocket) then
    return nil;
  end
  tcpSocket:setReadTimeout(250);
  -- fibaro:debug("C: " .. upnpService .. " / " .. upnpFunction .. "...");
  local result = "";
  local reqest = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
  reqest = reqest .. "<s:Envelope";
  reqest = reqest .. " s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\"";
  reqest = reqest .. " xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">\n";
  reqest = reqest .. "<s:Body>\n";
  reqest = reqest .. "<u:" .. upnpFunction .. " ";
  reqest = reqest .. "xmlns:u=\"urn:schemas-upnp-org";
  reqest = reqest .. ":service:" .. upnpService .. "\">\n";
  reqest = reqest .. upnpContent;
  reqest = reqest .. "</u:" .. upnpFunction .. ">\n";
  reqest = reqest .. "</s:Body>\n";
  reqest = reqest .. "</s:Envelope>\n";
  --fibaro:debug("Q: " .. #reqest .. " bytes: " .. reqest);
  tcpSocket:write("POST " .. upnpUrl .. " HTTP/1.1\r\n");
  tcpSocket:write("SOAPACTION: \"urn:schemas-upnp-org");
  tcpSocket:write(":service:" .. upnpService .. "#" .. upnpFunction);
  tcpSocket:write("\"\r\n");
  tcpSocket:write("User-Agent: DLNADOC/1.50 SEC_HHP_FIBARO_HC2/1.0\r\n");
  tcpSocket:write("Content-Length: " .. string.len(reqest) .. "\r\n");
  tcpSocket:write("Content-Type: text/xml; charset=\"utf-8\"\r\n");
  tcpSocket:write("Host: " .. ip .. ":" .. port .. "\r\n");
  tcpSocket:write("\r\n");
  tcpSocket:write(reqest);
  local r, e, i;
  i = 0; 
  repeat X("0:upnpReqest")
    r, e = tcpSocket:read();
    if (r) then
      i = i + 1;
      result = result .. r;
      if (#r<1024) then
        break;
      end
    end
  until (not X("E:upnpReqest") or i>100 or e>0 or not tcpSocket);
  tcpSocket:disconnect();
  --fibaro:debug("R: " .. #result .. " bytes: " .. result);
  if (e==0 or #result>0) then
    local start = string.find(result, upnpService .. "\">");
    local finish = string.find(result, "</u:" .. upnpFunction);
    if (start and finish and start>0 and finish>0 and finish>start) then
      local data = string.sub(result, (start + string.len(upnpService) + 2), (finish - 1));
      --fibaro:debug("D: " .. #data .. " bytes: " .. data);
      return data, result;
    else
      return nil, result;
    end
  else
    --fibaro:debug("E: " .. e);
    return nil;
  end
end



--[[
  UPNP:
  '/dmr/SamsungMRDesc.xml',  -- all devices?
  '/pmr/PersonalMessageReceiver.xml', 
  '/rcr/RemoteControlReceiver.xml', -- D-Series & e-Series?
  '/MainTVServer2/MainTVServer2Desc.xml' -- some D-Series ?
  '/ruis/RemoteUIServerDescLevel1.xml' -- C9000 series remote control
]]--

-- xml pages
local UPNPXMLPages = {
  ["dmr"] = "/dmr/SamsungMRDesc.xml",
  ["pmr"] = "/pmr/PersonalMessageReceiver.xml",
  ["rcr"] = "/rcr/RemoteControlReceiver.xml"
};

-- params from main xml
local UPNPInfo = {
  ["dmr"] = nil,
  ["pmr"] = nil,
  ["rcr"] = nil,
  ["deviceType"] = "",
  ["pnpx:X_compatibleId"] = "",
  ["df:X_deviceCategory"] = "",
  ["friendlyName"] = "",
  ["manufacturer"] = "",
  ["manufacturerURL"] = "",
  ["modelDescription"] = "",
  ["modelName"] = "",
  ["modelNumber"] = "",
  ["modelURL"] = "",
  ["serialNumber"] = "",
  ["UDN"] = "",
  ["sec:deviceID"] = ""
};

-- is UPNP available
local UPNPAvailable = false;

-- for all services
local UPNPServices = {};

--[[
  PREPARE TV
]]--

-- wait for communication...
fibaro:debug("---");

-- waiting for tv by sending null key
local connTry = 0;
while (X("0:connectionLoop")) do
  setState(nil, "Waiting for TV [" .. connTry .. "]...");
  delay(WAIT_TIME_AFTER_DISCONNECT * 1000);
  if (SamsungSendKey(virtualIP, TV_SENDKEY_PORT, "KEY_ENTER")) then
    setState(1, "TV FOUND [" .. TV_SENDKEY_PORT .. "]!");
    break;
  end
  connTry = connTry + 1;
end X("E:connectionLoop")

-- try upnp connection
fibaro:debug("---");
setState(nil, "Getting UPNP...");
if (1) then

  setState(nil, "UPNP Port [" .. virtualPort .. "]...");

  -- try to read all UPNP pages
  for pageType, pageUrl in pairs(UPNPXMLPages) do
    UPNPInfo[pageType] = nil;
    fibaro:debug("Reading [" .. string.upper(pageType) .. "]:[" .. pageUrl .. "]...");

    -- connection to device+
    local http, result, state, err;
    http = Net.FHttp(virtualIP, virtualPort);
    result, state, err = http:GET(pageUrl);
    if (err==0 and state=="200") then
    
      -- parse content of answer
      fibaro:debug("Result [" .. state .. "][" .. #result .. " bytes].");

      -- info about tv
      UPNPInfo[pageType] = #result;
      if (result and pageType=="dmr") then
        for k, v in pairs(UPNPInfo) do
          local r = result; 
          local p = "";
          while (X("S:UPNPInfo"..k) and p) do
            p, r = XML(r, k);
            if (p) then
              -- fibaro:debug("  " .. k .. ": [" .. p .. "].");
              UPNPInfo[k] = p;
            end
          end X("E:UPNPInfo") -- while
        end
      end
      
      -- services list
      if (result) then 
        local r = XML(result, "serviceList");
        local service = "";
        while (X("S:Services") and service) do
          service, r = XML(r, "service");
          if (service) then
            local url = XML(service, "SCPDURL");
            if (url and #url) then
              local tab = {
                ["serviceType"] = XML(service, "serviceType"),
                ["serviceId"] = XML(service, "serviceId"),
                ["controlURL"] = XML(service, "controlURL"),
                ["eventSubURL"] = XML(service, "eventSubURL")
              };
              if (not UPNPServices[pageType]) then
                UPNPServices[pageType] = {};
              end
              if (not UPNPServices[pageType][url]) then
                UPNPServices[pageType][url] = tab;
              end -- if
            end -- if url
          end -- if service
        end X("E:Services") -- while
      end -- if result
      
      -- actions
      for url, service in pairs(UPNPServices[pageType]) do
        result, state, err = http:GET("/" .. pageType .. "/" .. url);
        if (err==0 and state=="200") then
          --fibaro:debug("Result [" .. state .. "][" .. #result .. " bytes].");
          local tab = {};
          local action = "";
          while (X("S:Action") and action) do
            action, result = XML(result, "action");
            if (action) then
              -- init tab
              tab[count(tab)+1] = {};
              -- name
              local name = XML(action, "name");
              tab[count(tab)]["name"] = name;
              -- all arguments
              local args = {};
              local vars = {};
              local argument = "";
              while (argument) do
                argument, action = XML(action, "argument");
                if (argument) then
                  local nm = XML(argument, "name");
                  local dir = XML(argument, "direction");
                  local var = XML(argument, "relatedStateVariable");
                  if (nm and dir and var) then
                    if (dir=="in") then
                      args[count(args)+1] = var;
                    end
                    if (dir=="out") then
                      vars[count(vars)+1] = var;
                    end -- if out
                  end -- if nm ...
                end -- if argument
              end -- while              
              -- assign
              tab[count(tab)]["arguments"] = args;
              tab[count(tab)]["values"] = vars;
            end -- if action
          end X("E:Actions") -- while action
          UPNPServices[pageType][url]["actions"] = tab;
        end -- if err==0
      end -- actions (for UPNPServices)

    else
      fibaro:debug("Page don't answer!");
    end -- if result

  end -- for every pages

  -- print all infos
  printr(UPNPInfo, 0, "UPNP Info");
  -- printr(UPNPServices, 0, "UPNPServices");
  
  -- tv worked with upnp?
  if (UPNPInfo["dmr"] and UPNPInfo["rcr"]) then
    -- pepare rest globals
    if (globalName) then
      fibaro:debug("Prepare rest global variables...");
      prepareGlobal(tcpHC2, globalName .. "CurrentTransportState", {
        "NO_MEDIA_PRESENT", 
        "STOPPED", 
        "PAUSED_PLAYBACK",
        "PLAYING",
        "TRANSITIONING"
      });
      prepareGlobal(tcpHC2, globalName .. "Duration");
      prepareGlobal(tcpHC2, globalName .. "Volume");
      prepareGlobal(tcpHC2, globalName .. "Mute");
      --[[
      prepareGlobal(tcpHC2, globalName .. "Contrast");
      prepareGlobal(tcpHC2, globalName .. "Sharpness");
      prepareGlobal(tcpHC2, globalName .. "Brightness");
      prepareGlobal(tcpHC2, globalName .. "TrackDuration");
      prepareGlobal(tcpHC2, globalName .. "TrackSize");
      prepareGlobal(tcpHC2, globalName .. "AbsTime");
      prepareGlobal(tcpHC2, globalName .. "AbsByte");
      ]]--
    end
    setState(nil, "UPNP OK!");
    UPNPAvailable = true;
  else
    setState(nil, "UPNP Not supported!");
    UPNPAvailable = false;
  end

else
  setState(nil, "UPNP NOT FOUND!");
  UPNPAvailable = false;
end -- if UPNPAvailable

-- upnp values readed
local UPNPValues = {
  ["CurrentTransportState"] = nil,
  ["TrackDuration"] = nil,
  ["AbsTime"] = nil,
  ["TrackSize"] = nil,
  ["AbsByte"] = nil,
  ["Mute"] = nil,
  ["Sharpness"] = nil,
  ["Contrast"] = nil,
  ["Brightness"] = nil,
  ["Volume"] = nil
};

-- upnp functions to run
local UPNPFunctions = {
  ["GetVolume"] = {
    ["clock"] = 0,
    ["url"] = "/upnp/control/RenderingControl1",
    ["service"] = "RenderingControl:1",
    ["content"] = "<InstanceID>0</InstanceID>\n<Channel>Master</Channel>\n",
    ["values"] = {
      ["Volume"] = "CurrentVolume"
    }
  },
  ["X_DLNA_GetBytePositionInfo"] = {
    ["clock"] = 0.0,
    ["url"] = "/upnp/control/AVTransport1",
    ["service"] = "AVTransport:1",
    ["content"] = "<InstanceID>0</InstanceID>\n",
    ["values"] = {
      ["TrackSize"] = "TrackSize",
      ["AbsByte"] = "AbsByte"
    }
  },
  ["GetPositionInfo"] = {
    ["clock"] = 0.0,
    ["url"] = "/upnp/control/AVTransport1",
    ["service"] = "AVTransport:1",
    ["content"] = "<InstanceID>0</InstanceID>\n",
    ["values"] = {
      ["TrackDuration"] = "TrackDuration",
      ["AbsTime"] = "AbsTime"
    }
  },
  ["GetTransportInfo"] = {
    ["clock"] = 0.0,
    ["url"] = "/upnp/control/AVTransport1",
    ["service"] = "AVTransport:1",
    ["content"] = "<InstanceID>0</InstanceID>\n",
    ["values"] = {
      ["CurrentTransportState"] = "CurrentTransportState"
    }
  },
  ["GetMute"] = {
    ["clock"] = 0.0,
    ["url"] = "/upnp/control/RenderingControl1",
    ["service"] = "RenderingControl:1",
    ["content"] = "<InstanceID>0</InstanceID>\n<Channel>Master</Channel>\n",
    ["values"] = {
      ["Mute"] = "CurrentMute"
    }
  },
  ["GetSharpness"] = {
    ["clock"] = 0.0,
    ["url"] = "/upnp/control/RenderingControl1",
    ["service"] = "RenderingControl:1",
    ["content"] = "<InstanceID>0</InstanceID>\n<Channel>Master</Channel>\n",
    ["values"] = {
      ["Sharpness"] = "CurrentSharpness"
    }
  },
  ["GetContrast"] = {
    ["clock"] = 0.0,
    ["url"] = "/upnp/control/RenderingControl1",
    ["service"] = "RenderingControl:1",
    ["content"] = "<InstanceID>0</InstanceID>\n<Channel>Master</Channel>\n",
    ["values"] = {
      ["Contrast"] = "CurrentContrast"
    }
  },
  ["GetBrightness"] = {
    ["clock"] = 0.0,
    ["url"] = "/upnp/control/RenderingControl1",
    ["service"] = "RenderingControl:1",
    ["content"] = "<InstanceID>0</InstanceID>\n<Channel>Master</Channel>\n",
    ["values"] = {
      ["Brightness"] = "CurrentBrightness"
    }
  }
}

--[[
  MAIN LOOP
]]--

-- start info
fibaro:debug("---");
setState(nil, "READY!");

-- loop values
local lastProperty = "";
local lastIcon = 0;
local lastChannel = 0;
local lastAVTransport = 0;
local lastDuration = 0;

-- counter for errors
local errorsLeft = ERRORS_BEFORE_RESTART;

-- main loop
while (X("S:MainLoop") and errorsLeft>0) do

  -- if has to be skipped
  local continue = false;
  
  -- UPNP available?
  if (UPNPAvailable) then
  
    -- FUNCTIONS
    for fname, fparam in pairs(UPNPFunctions) do
      -- if something was readed
      if (continue) then
        break; -- skip checking
      end
      -- time to read?
      if (os.time() > fparam["clock"]) then
        -- run function
        local var, rest;
        var, rest = UPNPReqest(
          virtualIP,
          virtualPort,
          fparam["url"],
          fparam["service"],
          fname,
          fparam["content"]
        );
        -- answer is ok
        if (var) then
          UPNPAvailable = true;
          -- search all values
          for key, current in pairs(fparam["values"]) do
            local value;
            value, rest = XML(var, current);
            -- value changed
            if (value and value ~= UPNPValues[key]) then
              if (fparam["service"]=="RenderingControl:1") then
                setState(1, key .. "[" .. value .. "]");
              else
                fibaro:debug(key .. " [" .. value .. "]");
                setState(1);
              end
              UPNPValues[key] = value;
              fibaro:setGlobal(globalName .. key, value);
              fibaro:call(virtualId, "setProperty", "ui." .. key .. ".value", value);
              -- next read in a second
              UPNPFunctions[fname]["clock"] = os.time();
            else
              -- no change, next reading after period
              UPNPFunctions[fname]["clock"] = os.time() + 1;
            end -- value changed
            continue = true;
          end -- for all values
        elseif (UPNPAvailable) then
          errorsLeft = errorsLeft - 1;
          setState(0, "No answer!");
          delay(WAIT_TIME_AFTER_DISCONNECT * 1000);
          -- next try after few sec.
          UPNPFunctions[fname]["clock"] = os.time() + WAIT_TIME_AFTER_DISCONNECT;
        end -- answer ok
      end -- if time
    end -- FUNCTIONS

  end -- if UPNPAvailable


  -- SLIDERS
  if (continue==false) then
    for key, value in pairs(UPNPValues) do
      local slider, ts;
      slider, ts = fibaro:get(virtualId, "ui." .. key .. ".value");
      -- value changed
      if (value and tonumber(value) 
        and slider and tonumber(slider) 
        and slider~=value
        and (os.time()-ts) < 2
      ) then
        setState(nil);
        -- set new value
        local var, rest;
        var, rest = UPNPReqest(virtualIP, virtualPort,
          "/upnp/control/RenderingControl1",
          "RenderingControl:1",
          "Set" .. key,
          "<InstanceID>0</InstanceID>\n<Channel>Master</Channel>\n"..
          "<Desired" .. key .. ">" .. slider .. "</Desired" .. key .. ">\n"
        );
        -- set confirmed
        if (rest) then
          UPNPAvailable = true;
          setState(1, key .. "[" .. UPNPValues[key] .. ">" .. slider .. "]");
          fibaro:setGlobal(globalName .. key, slider);
        elseif (UPNPAvailable) then
          errorsLeft = errorsLeft - 1;
          setState(0, "No answer!");
          delay(WAIT_TIME_AFTER_DISCONNECT * 1000);
        end
        UPNPValues[key] = slider;
        break; -- skip for
      end -- value changed
    end -- for SLIDERS
  end -- continue


  -- DURATION
  local duration, sliderTs;
  duration, sliderTs = fibaro:get(virtualId, "ui.Duration.value");
  if (1) then

    -- check duration
    local ts = UPNPValues["TrackDuration"];
    local tp = UPNPValues["AbsTime"];
    local bs = tonumber(UPNPValues["TrackSize"]);
    local bp = tonumber(UPNPValues["AbsByte"]);
    local st = UPNPValues["CurrentTransportState"];
    if (ts and tp) then
      local t = tp .. "/" .. ts;
      if (lastAVTransport ~= t) then
        lastAVTransport = t;
        if (bs and bp) then
          t = bp .. "/" .. bs;
          local perc = math.floor((bp/(bs/100))+0.5);
          lastDuration = perc;
          -- {"NO_MEDIA_PRESENT", "STOPPED", "PAUSED_PLAYBACK", "PLAYING", "TRANSITIONING"}
          if (st) then
            if (st=="PLAYING") then
              setState(1, "► " .. tp .. "");
            elseif (st=="STOPPED") then
              setState(1, "▇ " .. tp .. "");
            elseif (st=="PAUSED_PLAYBACK") then
              setState(1, "▮▮ " .. tp .. "");
            elseif (st=="TRANSITIONING") then
              setState(1, "Transitioning");
            elseif (st=="NO_MEDIA_PRESENT") then
              setState(1, "No media");
            else
              setState(1, st);
            end
          end
          fibaro:setGlobal(globalName .. "Duration", perc);
          fibaro:call(virtualId, "setProperty", "ui.Duration.value", "" .. perc .. "%");
          fibaro:call(virtualId, "setProperty", "ui.Media.value", lastAVTransport);
        end -- bs and bp
      end -- ~lastAVTransport
    end -- ts and tp
    
    -- set new duration
    if (duration and tonumber(duration) 
      and duration~=lastDuration
      and (os.time()-sliderTs)<2
      and bs and tonumber(bs)
    ) then
      local v = math.floor((tonumber(duration) * (bs / 100))+0.5);
      setState(nil, "Duration [" .. tonumber(duration) .. "%]");
      UPNPReqest(virtualIP, virtualPort,
        "/upnp/control/AVTransport1",
        "AVTransport:1",
        "Seek",
        "<InstanceID>0</InstanceID>\n<Unit>X_DLNA_REL_BYTE</Unit>\n<Target>" .. v .. "</Target>\n"
      );
      lastDuration = duration;
    end
    
  end -- DURATION


  -- CHANNEL
  if (1) then
    local channel, ts;
    channel, ts = fibaro:get(virtualId, "ui.Channel.value");
    if (
      channel and tonumber(channel)
      and channel~=lastChannel 
      and (os.time()-ts)<2
    ) then
      setState(nil);
      lastChannel = channel;
      setState(nil, "Channel " .. channel);
      for i = 1, #channel do
        local key = "KEY_" .. channel:sub(i,i);
        local ok = SamsungSendKey(virtualIP, TV_SENDKEY_PORT, key);
        if (ok) then
          setState(1);
          errorsLeft = ERRORS_BEFORE_RESTART;
        else
          setState(0, "Connection error!");
          errorsLeft = errorsLeft - 1;
        end
      end
    end
  end



  -- BUTTONS
  if (1) then

    -- check icon select - button click
    local icon, ts;
    icon, ts = fibaro:get(virtualId, "currentIcon");
    if (icon and tonumber(icon) and tonumber(icon) > 100000
      -- icon mathing to this virtual device
      and math.floor(tonumber(icon)/100000)==virtualId
      -- be sure to receive new press
      and icon ~= lastIcon
    ) then
    
      -- prepare
      setState(nil);
      lastIcon = 0;
      icon = tonumber(icon);
      local name = buttonAtIcon[icon];
      local action = actionAtIcon[icon];
      
      -- channel to send
      if (string.find(action, "CHANNEL_")==1) then
        local channel = string.sub(action, string.find(action, "_") + 1);
        if (channel) then
          setState(nil, "Channel [".. channel .. "]...");
          fibaro:call(virtualId, "setProperty", "ui.Channel.value", channel);
          for i = 1, #channel do
            local key = "KEY_" .. channel:sub(i,i);
            local ok = SamsungSendKey(virtualIP, TV_SENDKEY_PORT, key);
            if (ok) then
              setState(1);
              errorsLeft = ERRORS_BEFORE_RESTART;
            else
              setState(0, "Connection error!");
              errorsLeft = errorsLeft - 1;
              break; -- skip for
            end
            delay(100);
          end
        end
      
      -- key to send
      elseif (string.find(string.upper(action),"KEY")==1) then
        while (X("S:ActionKey#"..#action) and #action > 0) do
          local key = "";
          local r = string.find(action, "\r");
          local n = string.find(action, "\n");
          if ((r and r>0) or (n and n>0)) then
            if (not r or r<1) then r = n; end
            if (not n or n<1) then n = r; end
            key = action:sub(1, r-1);
            action = action:sub(n+1);
          else
            key = action;
            action = "";
          end
          if (#key > 0) then
            if (key=="WAIT") then
              local ac = "";
              fibaro:debug("Waiting [Power=Exit | Source=Next]...");
              repeat X("0:Wait")
                delay(100);
                local ic = fibaro:get(virtualId, "currentIcon");
                if (ic) then
                  ic = tonumber(ic);
                  if (ic and ic > 100000) then
                    ac = actionAtIcon[ic];
                  end
                end
              until (not X("1:Wait") or ac=="KEY_POWEROFF" or ac=="KEY_SOURCE");
              if (ac=="KEY_POWEROFF") then
                action = "";
              end
            else
              setState(nil, key);
              local ok = SamsungSendKey(virtualIP, TV_SENDKEY_PORT, key);
              if (ok) then
                setState(1);
                errorsLeft = ERRORS_BEFORE_RESTART;
              else
                setState(0, "Connection error!");
                errorsLeft = errorsLeft - 1;
              end
            end
          else
            fibaro:debug("Delay [250]");
            delay(250);
          end
        end X("E:ActionKey") -- while action

      -- play file
      elseif (string.find(string.upper(action),"HTTP")==1 and UPNPAvailable) then
        setState(nil, "Play [" .. name .. "]...");        
        local d, r, e;
        d, r = UPNPReqest(virtualIP, virtualPort,
          "/upnp/control/AVTransport1",
          "AVTransport:1",
          "GetTransportInfo",
          "<InstanceID>0</InstanceID>\n"
        );
        if (d) then
          local state = XML(r, "CurrentTransportState");
          local status = XML(r, "CurrentTransportStatus");
          local speed = XML(r, "CurrentSpeed");
          if (state and status and speed) then
            fibaro:debug("Transport [" .. status .. "][" .. state .. "][Speed " .. speed .. "].");
          end
          if (state and state~="NO_MEDIA_PRESENT") then
            d, r = UPNPReqest(virtualIP, virtualPort,
              "/upnp/control/AVTransport1",
              "AVTransport:1",
              "Stop",
              "<InstanceID>0</InstanceID>\n"
            );
            if (d) then
              setState(1, "Current stopped.");
            elseif (r) then
              e = XML(r, "errorDescription");
              if (e) then
                setState(nil, e .. "!");
              end
            end
          end
          d, r = UPNPReqest(virtualIP, virtualPort,
            "/upnp/control/AVTransport1",
            "AVTransport:1",
            "SetAVTransportURI",
            "<InstanceID>0</InstanceID>\n<CurrentURI>" .. action .. "</CurrentURI>\n<CurrentURIMetaData></CurrentURIMetaData>\n"
          );
          if (d) then
            setState(1, "Transport ready.");
            d, r = UPNPReqest(virtualIP, virtualPort,
              "/upnp/control/AVTransport1",
              "AVTransport:1",
              "Play",
              "<InstanceID>0</InstanceID>\n<Speed>1</Speed>\n"
            );
          end
        end
        if (d) then
          UPNPAvailable = true;
          setState(nil, "Play [" .. name .. "]!");
          break;
        elseif (r) then
          e = XML(r, "errorDescription");
          if (e) then
            setState(nil, e .. "!");
          end
        else
          setState(nil, "No response!");
          delay(WAIT_TIME_AFTER_DISCONNECT * 1000);
        end
      
      -- if no action
      else
        setState(nil, "Skipping!");
      end -- if action

    end -- if icon
    
  end -- BUTTONS
  

end X("E:MainLoop")
-- END MAIN LOOP  

-- SET ERROR STATE
setState(-1, "RESTARTING...");

-- WAIT BEFORE NEXT RUN
delay(WAIT_TIME_AFTER_CHANGES * 1000);

--[[TV_SAMSUNG
  pl.rafikel.fibaro.tv.samsung
]]