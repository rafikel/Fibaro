-- FIBARO HC2 + VLC
-- http://fibaro.rafikel.pl (2013-2014)
-- Lincense: GPL. Donate: http://goo.gl/a0WNXE

-- LUA script for remote controling VLC.
-- Completely and in automatic way creates and configures
-- virtual device in HC2 for that purpose.

-- Needed:
-- 1. Your name of device (eg. VLC).
-- 2. IP address and port (eg. 8080) for communication.
-- 3. Login and password for HC2, entered in config section (below).
-- 4. Login and password for VLC Remote access (in script).

-- What script will do: 
-- 1. Find VLC Remote on defined IP and grab all necessary data.
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
-- 2. Enter name for device (eg. "VLC"), IP address and 
--    port (eg. 8080).
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

-- VLC Credentials 
-- Access for VLC Remotely. You can pepare your VLC by setting http
-- remote. The most popular way is using special software for that:
-- http://hobbyistsoftware.com/vlcsetup.php
VLC_USER = ""
VLC_PASSWORD = "vlcremote"

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

-- END OF CONFIGURATION SECTION!
-- Below is only code, working standalone without changes.
-- If you have good knowledge about programming and want to use
-- or change something, feel free! Remember to share yours
-- solution with others users. That's all!



--[[VLC
  pl.rafikel.fibaro.vlc
]]--

VERSION = "{0_1_0}"

--[[
  HISTORY
  
  0.1.0 (2014-03-20)
  - First beta version.
  
]]--



--[[
  ERRORS NUMS BEFORE SCRIPT WILL RESTART
]]--
ERRORS_BEFORE_RESTART = 1000

--[[
  BUTTONS DEFINITION
]]--
local BUTTONS = '['..
  '{"type":"label","elements":[{"id":1,"lua":false,"waitForResponse":false,"caption":"State","name":"State","favourite":true,"main":true}]},'..
  '{"type":"button","elements":[{"id":2,"lua":false,"waitForResponse":false,"caption":"Fullscreen","name":"Fulscreen","empty":false,"msg":"fullscreen","buttonIcon":0,"favourite":false,"main":true}]},'..
  '{"type":"slider","elements":[{"id":3,"lua":false,"waitForResponse":false,"caption":"Volume","name":"Volume","msg":"","buttonIcon":0,"value":0,"favourite":false,"main":true}]},'..
  '{"type":"button","elements":[{"id":4,"lua":false,"waitForResponse":false,"caption":"⊲ 10 s.","name":"Back10s","empty":false,"msg":"seek&val=-10s","buttonIcon":0,"favourite":false,"main":false},{"id":5,"lua":false,"waitForResponse":false,"caption":"►","name":"Play","empty":false,"msg":"pl_play","buttonIcon":0,"favourite":false,"main":false},{"id":6,"lua":false,"waitForResponse":false,"caption":"10 s. ⊳","name":"Forward10s","empty":false,"msg":"seek&val=+10s","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":7,"lua":false,"waitForResponse":false,"caption":"⋘ 1 m.","name":"Back1m","empty":false,"msg":"seek&val=-1m","buttonIcon":0,"favourite":false,"main":false},{"id":8,"lua":false,"waitForResponse":false,"caption":"▮▮","name":"Pause","empty":false,"msg":"pl_pause","buttonIcon":0,"favourite":false,"main":false},{"id":9,"lua":false,"waitForResponse":false,"caption":"1 m. ⋙","name":"Forward1m","empty":false,"msg":"seek&val=+1m","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":10,"lua":false,"waitForResponse":false,"caption":"⇤ Prev","name":"Previous","empty":false,"msg":"pl_previous","buttonIcon":0,"favourite":false,"main":false},{"id":11,"lua":false,"waitForResponse":false,"caption":"▇","name":"Stop","empty":false,"msg":"pl_stop","buttonIcon":0,"favourite":false,"main":false},{"id":12,"lua":false,"waitForResponse":false,"caption":"Next ⇥","name":"Next","empty":false,"msg":"pl_next","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"label","elements":[{"id":13,"lua":false,"waitForResponse":false,"caption":"File","name":"Filename","favourite":false,"main":false}]},'..
  '{"type":"slider","elements":[{"id":14,"lua":false,"waitForResponse":false,"caption":"Position","name":"Position","msg":"","buttonIcon":0,"value":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":15,"lua":false,"waitForResponse":false,"caption":"Empty Playlist","name":"Empty","empty":false,"msg":"pl_empty","buttonIcon":0,"favourite":false,"main":true}]},'..
  '{"type":"button","elements":[{"id":16,"lua":false,"waitForResponse":false,"caption":"File demo","name":"FileDemo","empty":false,"msg":"file://c:/demo.avi","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":17,"lua":false,"waitForResponse":false,"caption":"Http demo","name":"HttpDemo","empty":false,"msg":"http://www.fibaro.com/sites/default/files/headers/top_01_0_0.jpg","buttonIcon":0,"favourite":false,"main":false}]},'..
  '{"type":"button","elements":[{"id":18,"lua":false,"waitForResponse":false,"caption":"Rtsp demo","name":"RtspDemo","empty":false,"msg":"rtsp://184.72.239.149/vod/mp4:BigBuckBunny_115k.mov","buttonIcon":0,"favourite":false,"main":false}]}'..
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
  [-1] = "vlc_err.png",
  [0] = "vlc_off.png",
  [1] = "vlc_on.png"
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
  -- action for icons
  actions = {};
  -- value to count ready buttons
  ready = 0;
  -- value to count changes in buttons
  changes = 0;
  -- type of change to made (icons, buttons)
  changeType = nil;
  -- grab virtual devices list from api
  response, status, errorCode = tcp:GET("/api/virtualDevices?id=" .. id);
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
      response, status, errorCode = tcp:PUT("/api/virtualDevices", toPut);
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
  response, status, errorCode = tcp:GET("/api/virtualDevices?id=" .. id);
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
    response, status, errorCode = tcp:PUT("/api/virtualDevices", toPut);
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
      size, content  = getFileFromServer(tcpSERVER, "/lua/vlc.lua");
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
            content = string.gsub(content, 'VLC_USER = ""', 'VLC_USER = "' .. VLC_USER .. '"');
            content = string.gsub(content, 'VLC_PASSWORD = "vlcremote"', 'VLC_PASSWORD = "' .. VLC_PASSWORD .. '"');
            content = string.gsub(content, 'SERVER_CONTACT = 1', 'SERVER_CONTACT = ' .. SERVER_CONTACT);
            content = string.gsub(content, 'AUTO_UPDATE = 1', 'AUTO_UPDATE = ' .. AUTO_UPDATE);
            content = string.gsub(content, 'WAIT_TIME_AFTER_CHANGES = 10', 'WAIT_TIME_AFTER_CHANGES = ' .. WAIT_TIME_AFTER_CHANGES);
            content = string.gsub(content, 'WAIT_TIME_AFTER_DISCONNECT = 5', 'WAIT_TIME_AFTER_DISCONNECT = ' .. WAIT_TIME_AFTER_DISCONNECT);
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
  VLC REQEST

  https://wiki.videolan.org/VLC_HTTP_requests/
  /requests/status.xml
  
]]--
function VLCReqest(tcp, url)
  r, s, e = tcp:GET(url);
  -- fibaro:debug("R: " .. #r .. " bytes: " .. r);
  if (s=="200") then
    return r;
  else
    fibaro:debug("E: " .. e);
    return nil;
  end
end



--[[
  PREPARE VLC Remote
]]--

-- communication
local tcpVLC = Net.FHttp(virtualIP, virtualPort);
if (not tcpVLC) then
  setState(-1, "ERROR!");
  fibaro:abort();
end
tcpVLC:setBasicAuthentication(VLC_USER, VLC_PASSWORD);

-- wait for communication...
fibaro:debug("---");
local connTry = 0;
while (X("0:connectionLoop")) do
  setState(nil, "Waiting for VLC [" .. connTry .. "]...");
  delay(WAIT_TIME_AFTER_DISCONNECT * 1000);
  if (VLCReqest(tcpVLC, "/requests/status.xml")) then
    setState(1, "VLC FOUND!");
    break;
  end
  connTry = connTry + 1;
end X("E:connectionLoop")

-- rest globals
if (globalName) then
  fibaro:debug("Prepare rest global variables...");
  prepareGlobal(tcpHC2, globalName .. "Filename");
  prepareGlobal(tcpHC2, globalName .. "Position");
  prepareGlobal(tcpHC2, globalName .. "Volume");
  prepareGlobal(tcpHC2, globalName .. "State", {
    "playing",
    "paused",
    "stopped"
  });
end



--[[
  MAIN LOOP
]]--

--[[
  ["Hue"] = "",
  ["Saturation"] = "",
  ["Contrast"] = "",
  ["Brightness"] = "",
  ["Gamma"] = "",
  ["Length"] = 1,
  ["Time"] = 1,
]]--
-- what to read
local VLCValues = {
  ["State"] = "",
  ["Volume"] = 2.56,
  ["Position"] = 0.01,
  ["Filename"] = ""
};
local Values = {};

-- start info
fibaro:debug("---");
setState(nil, "READY!");

-- loop values
local lastIcon = 0;

-- last read timestamp
local lastRead = 0;

-- counter for errors
local errorsLeft = ERRORS_BEFORE_RESTART;

-- main loop
while (X("S:MainLoop") and errorsLeft>0) do
  
  -- VARS
  local reqest = "";
  
  -- TIME
  if (os.time() ~= lastRead) then
    reqest = "?";
    lastRead = os.time();
  end

  -- SLIDERS
  for key, value in pairs(VLCValues) do
    local slider, ts;
    slider, ts = fibaro:get(virtualId, "ui." .. key .. ".value");
    -- value changed
    if (
        slider and tonumber(slider)
        and slider ~= Values[key]
        and (os.time()-ts) < 2
    ) then
      setState(nil, key .. "[" .. Values[key] .. ">" .. slider .. "]");
      if (key=="Position") then
        reqest = "?command=seek&val=" .. slider .. "%25";
      else
        reqest = "?command=" .. string.lower(key) .. "&val=" .. slider * value;
      end
      Values[key] = slider;
      -- skip rest
      break;
    end -- value changed
  end -- for
  
  -- BUTTONS
  if (#reqest==0) then
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
      -- play file
      if (string.find(string.upper(action), "FILE://")==1) then
        setState(nil, "File [" .. name .. "]");
        reqest = "?command=in_play&input=" .. action;
      -- play rtsp
      elseif (string.find(string.upper(action), "RTSP://")==1) then
        setState(nil, "Rtsp [" .. name .. "]");
        reqest = "?command=in_play&input=" .. action;
      -- play http
      elseif (string.find(string.upper(action), "HTTP://")==1) then
        setState(nil, "Http [" .. name .. "]");
        reqest = "?command=in_play&input=" .. action;
      -- play https
      elseif (string.find(string.upper(action), "HTTPS://")==1) then
        setState(nil, "Https [" .. name .. "]");
        reqest = "?command=in_play&input=" .. action;
      -- command
      else
        setState(nil, name);
        reqest = "?command=" .. action;
      end -- if action
    end -- if icon
  end -- BUTTONS

  -- READ
  if (#reqest > 0) then
    local response = VLCReqest(tcpVLC, "/requests/status.xml" .. reqest);
    if (response==nil) then
      setState(0);
      errorsLeft = errorsLeft - 1;
      delay(WAIT_TIME_AFTER_DISCONNECT * 1000);
    -- parse xml
    else
      for key, value in pairs(VLCValues) do
        local newVal = string.match(response, '<info name=\'' .. string.lower(key) .. '\'>(.-)</info>');
        if (not newVal) then
          newVal = XML(response, string.lower(key));
        end
        if (tonumber(value)) then
          newVal = tostring(math.ceil( tonumber(newVal) / tonumber(value) ));
        end
        if (not newVal) then
          newVal = "";
        end
        if (newVal ~= Values[key]) then
          Values[key] = newVal;
          fibaro:setGlobal(globalName .. key, newVal);
          fibaro:debug("" .. key .. " [" .. newVal .. "]");
          fibaro:call(virtualId, "setProperty", "ui." .. key .. ".value", newVal);
        else
          --setState(1, key .. " [" .. value .. "]");
        end
      end -- for
    end -- parse xml
  end -- READ

  -- TIMEOUT
  if (errorsLeft <= 0) then
    setState(nil, "Disconnected!");
    break;
  end

end X("E:MainLoop")
-- END MAIN LOOP  

-- SET ERROR STATE
setState(-1, "RESTARTING...");

-- WAIT BEFORE NEXT RUN
delay(WAIT_TIME_AFTER_CHANGES * 1000);
  
--[[VLC
  pl.rafikel.fibaro.vlc
]]
