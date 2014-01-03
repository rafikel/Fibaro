-- FIBARO HC2 + DEKODER TELEWIZJI NC PLUS
-- http://fibaro.rafikel.pl (2013-2014)

-- Skrypt LUA urządzenia wirtualnego Fibaro oraz centralki 
-- HC2, który całkowicie automatycznie utworzy i skonfiguruje 
-- urządzenie wirtualne w centralce do obsługi dekodera 
-- telewizji NC Plus (dekodery MediaBox)!

-- Potrzebne: 
-- 1. Twoja nazwa urządzenia (np. Dekoder NC+). 
-- 2. Adres IP oraz port (najpewniej 8080) dekodera. 
-- 3. Hasło i login do centralki podane na początku skryptu. 

-- Co skrypt zrobi: 
-- 1. Znajdzie dekoder pod podanym adresem i pobierze z niego 
--    wszelkie potrzebne dane.
-- 2. Przygotuje pełen zestaw przycisków, które będa dostępne
--    w interfejsie użytkownika oraz scenach blokowych.
-- 3. Pobierze z serwera fibaro.rafikel.pl oraz wgra do 
--    centralki zestaw ikonek graficznych dla urządzenia.
-- 4. Utworzy zmienna globalną, która odzwierciedlać będzie 
--    stan dekodera (nazwa zmiennej na podstawie podanej nazwy 
--    urządzenia wirtualnego).
-- 5. W pełni umożliwi na sterowanie i odczytywanie stanu 
--    dekodera z poziomu scen blokowych. 

-- Instrukcja: 
-- 1. Utwórz nowe urządzenie wirtualne. 
-- 2. Podaj swoją nazwę (np. "Dekoder NC+") oraz adres IP 
--    i port TCP dekodera (najpewniej 8080).
-- 3. Wklej zawartość skryptu do głównej pętli.
-- 4. Zapisz urządzenie wirtualne i poczekaj około minuty, 
--    możesz obserwować postęp w "debugu".
-- 5. Jeśli wszystko poszło ok, odświeżając stronę zobaczysz 
--    gotowe urządzenie do sterowania!

-- Możesz potem definiować własną listę ulubionych kanałów 
-- poprzez dodawanie kolejnych przycisków (za przykładowym
-- Discovery na końcu).

-- DANE LOGOWANIA DO CENTRALKI
-- Te dane są obowiązkowe! Zapewniają poprawną pracę skryptu!
-- Skrypt tworzy i dostosowuje zawartość urządzenia wirtualnego
-- dla swoich potrzeb - przyciski, zmienne globalne, ikonki...
-- Aby mieć taką możliwość, potrzebuje pełnego dostępu do HC2!
USER = "admin" 
PASSWORD = "admin"

-- AUTO_UPDATE = 0 | 1 [Domyślnie = 0]
-- Ustawienia automatycznej aktualizacji skryptu - zezwala na 
-- automatyczne pobieranie nowych wersji skryptu z serwera
-- fibaro.rafikel.pl. Skrypt nie wysyła żadnych danych, jedynie
-- odczytuje plik na serwerze i w razie potrzeby podmienia swoją
-- zawartość na nową. Konfiguracja użytkownika nie jest nadpisywana. 
AUTO_UPDATE = 1

-- PROBE_AT_START = 0 | 1 [Domyślnie = 1]
-- Sprawdzanie stanu włączenia dekodera przy uruchomieniu
-- skryptu. Jest to zrealizowane poprzez wybranie przycisków
-- Prog+ i Prog-, co pozwola na odebranie stanu z dekodera.
PROBE_AT_START = 1

-- WAIT_TIME_AFTER_CHANGES = 0..60 [Domyślnie = 30]
-- Czas w sekundach zanim skrypt wystartuje ponownie po każdym 
-- etapie autokonfiguracji lub inicjalizacji. Do normalnej 
-- pracy wystarczy 5 sekund, lub mniej. Na początku pozostaw
-- jednak 30 sekund i upewnij się, że wszystko działa!
WAIT_TIME_AFTER_CHANGES = 30

-- KONIEC KONFIGURACJI UŻYTKOWNIKA!
-- Poniżej znajduje się już tylko kod, który wykonuje wszystko
-- automatycznie, bez potrzeby wgłębiania się w jego strukturę.
-- Jeśli jednak czujesz się na siłach i chciałbyś go wykorzystać,
-- zmienić lub dostosować do własnych potrzeb, bardzo Cię proszę
-- o udostępnienie tych zmian dla innych użytkowników!

--[[START 
  NC_PLUS_1_0 
  pl.rafikel.fibaro.ncplus
]]
      
--[[
  EXTRA FUNCTIONS
]]--
-- counting elements in array (table)
function count(tab) i = 0; for k, v in pairs(tab) do i = i + 1; end return i; end
-- xor bits operation
function bxor(a, b) r = 0; for i = 0, 31 do x = a / 2 + b / 2; if (x~=math.floor(x)) then r = r + 2^i; end a = math.floor(a / 2); b = math.floor(b / 2); end return r; end
-- calculate checksum
function checkSum(t) c = 0; for i = 1, #t do b = string.byte(t, i); if (c==0) then c = b; else c = bxor(c, b); end if (i>100) then break; end end return c; end
-- encoding to base64 
function encode(data) local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' return((data:gsub('.',function(x) local r,b='',x:byte() for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0')end return r end)..'0000'):gsub('%d%d%d?%d?%d?%d?',function(x) if(#x<6) then return('') end local c=0 for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end return b:sub(c+1,c+1) end)..({'','==','='})[#data%3+1]) end 
-- random string
function random(nums) r=""; for i=1,nums do r=r..tostring(math.random(0,9)); end; return r; end

--[[
  READ THIS VIRTUAL DEVICE (id, ip, port)
--]]
function readVirtualDevice(tcp)
  -- generate random string
  rnd = random(32);
  -- send random string
  fibaro:log(rnd);
  -- grab virtual devices list from api
  response, status, errorCode = tcp:GET("/api/virtualDevices");
  -- show status on debug window
  --fibaro:debug("Status of reqest: " .. status .. '.');
  -- if answer is wrong
  if (tonumber(status)~=200) then
    fibaro:log("");
    --fibaro:debug("Error " .. errorCode .. ".");
    return nil, nil, nil, nil;
  -- if answer is ok?
  else
    -- decode text to json object
    jsonTable = json.decode(response);
    -- roll over all virtual devices
    --fibaro:debug("Checking configuration...");
    for virtualIndex, virtualData in pairs(jsonTable) do
      -- fibaro:debug('Virtual Device Id [' .. virtualData.id .. ']');
      -- if virtual device type and name is right?
      if (virtualData.type=="virtual_device") then
        check = string.find(fibaro:get(virtualData.id, "log"), rnd);
        if (check and check>0) then
		  fibaro:log("");
          id = virtualData.id;
          ip = virtualData.properties.ip;
          port = virtualData.properties.port;
          name = virtualData.name;
          icon = virtualData.properties.deviceIcon;
          return id, name, ip, port, icon;
        end
      end
    end
  end
  fibaro:log("");
  return nil;
end

--[[
  GRAB FILE FROM SERVER
--]]
function getIconFromServer(tcp, path)
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
  -- declare key codes for icons
  keys = {};
  -- channel numbers for icons
  channels = {};
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
        --fibaro:debug('  Row [' .. rowIndex .. '][' .. rowData.type .. ']');
        -- if row type is button
        if (rowData.type=='button') then
          -- check all buttons in row
          for buttonIndex, buttonData in pairs(rowData.elements) do
            -- check button content
            if (string.find(buttonData.msg, "KEY_")==1 
                or string.find(buttonData.msg, "CHANNEL_")==1
              ) then
              -- check button icon
              pos = string.find(buttonData.msg, "_");
              icon = (id * 1000) + buttonData.id;
              buttons[icon] = buttonData.caption;
              if (string.find(buttonData.msg, "KEY_")==1) then
                key = string.sub(buttonData.msg, pos + 1);
                if (key and tonumber(key)) then
                  keys[icon] = tonumber(key);
                end
              elseif (string.find(buttonData.msg, "CHANNEL_")==1) then
                channel = string.sub(buttonData.msg, pos + 1);
                if (channel and tonumber(channel)) then
                  channels[icon] = tonumber(channel);
                end
              end
              -- check icon of button
              if (buttonData.buttonIcon~=icon) then
                jsonTable[1].properties.rows[rowIndex].elements[buttonIndex].buttonIcon = icon;
                changes = changes + 1;
                changeType = "icons";
              else
                -- increment ready buttons
                ready = ready + 1;
              end
            end
          end -- check all buttons in row
        end -- if row type is button
      end -- check all rows
      -- no property rows defined?
      if (changes<1 and ready<1) then
        -- DEFINE ALL NEW BUTTONS
        jsonTable[1].properties.rows = json.decode('[{"type":"label","elements":[{"id":1,"lua":false,"waitForResponse":false,"caption":"State","name":"State","favourite":false,"main":true}]},{"type":"button","elements":[{"id":2,"lua":false,"waitForResponse":false,"caption":"⎋ Power","name":"Power","empty":false,"msg":"KEY_116","buttonIcon":0,"favourite":false,"main":true},{"id":3,"lua":false,"waitForResponse":false,"caption":"Home ⏏","name":"Home","empty":false,"msg":"KEY_174","buttonIcon":0,"favourite":false,"main":false}]},{"type":"button","elements":[{"id":4,"lua":false,"waitForResponse":false,"caption":"⇡ Vol","name":"VolUp","empty":false,"msg":"KEY_115","buttonIcon":0,"favourite":false,"main":false},{"id":5,"lua":false,"waitForResponse":false,"caption":"♬","name":"Mute","empty":false,"msg":"KEY_113","buttonIcon":0,"favourite":false,"main":false},{"id":6,"lua":false,"waitForResponse":false,"caption":"Vol ⇣","name":"VolDown","empty":false,"msg":"KEY_114","buttonIcon":0,"favourite":false,"main":false}]},{"type":"button","elements":[{"id":7,"lua":false,"waitForResponse":false,"caption":"⇡ Prog","name":"ProgUp","empty":false,"msg":"KEY_402","buttonIcon":0,"favourite":false,"main":false},{"id":8,"lua":false,"waitForResponse":false,"caption":"Prog ⇣","name":"ProgDown","empty":false,"msg":"KEY_403","buttonIcon":0,"favourite":false,"main":false}]},{"type":"label","elements":[{"id":9,"lua":false,"waitForResponse":false,"caption":"Recorder","name":"Recorder","favourite":false,"main":false}]},{"type":"button","elements":[{"id":10,"lua":false,"waitForResponse":false,"caption":"⋘","name":"Backward","empty":false,"msg":"KEY_168","buttonIcon":0,"favourite":false,"main":false},{"id":11,"lua":false,"waitForResponse":false,"caption":"►","name":"Play","empty":false,"msg":"KEY_207","buttonIcon":0,"favourite":false,"main":false},{"id":12,"lua":false,"waitForResponse":false,"caption":"⋙","name":"Forward","empty":false,"msg":"KEY_159","buttonIcon":0,"favourite":false,"main":false}]},{"type":"button","elements":[{"id":13,"lua":false,"waitForResponse":false,"caption":"◉","name":"Rec","empty":false,"msg":"KEY_167","buttonIcon":0,"favourite":false,"main":false},{"id":14,"lua":false,"waitForResponse":false,"caption":"▮▮","name":"Pause","empty":false,"msg":"KEY_119","buttonIcon":0,"favourite":false,"main":false},{"id":15,"lua":false,"waitForResponse":false,"caption":"▇","name":"Stop","empty":false,"msg":"KEY_128","buttonIcon":0,"favourite":false,"main":false}]},{"type":"label","elements":[{"id":16,"lua":false,"waitForResponse":false,"caption":"Cursors","name":"Cursors","favourite":false,"main":false}]},{"type":"button","elements":[{"id":17,"lua":false,"waitForResponse":false,"caption":"ⓘ Info","name":"Info","empty":false,"msg":"KEY_358","buttonIcon":0,"favourite":false,"main":false},{"id":18,"lua":false,"waitForResponse":false,"caption":"△","name":"Up","empty":false,"msg":"KEY_103","buttonIcon":0,"favourite":false,"main":false},{"id":19,"lua":false,"waitForResponse":false,"caption":"Opt ⓟ","name":"Opt","empty":false,"msg":"KEY_357","buttonIcon":0,"favourite":false,"main":false}]},{"type":"button","elements":[{"id":20,"lua":false,"waitForResponse":false,"caption":"◁","name":"Left","empty":false,"msg":"KEY_105","buttonIcon":0,"favourite":false,"main":false},{"id":21,"lua":false,"waitForResponse":false,"caption":"OK","name":"OK","empty":false,"msg":"KEY_352","buttonIcon":0,"favourite":false,"main":false},{"id":22,"lua":false,"waitForResponse":false,"caption":"▷","name":"Right","empty":false,"msg":"KEY_106","buttonIcon":0,"favourite":false,"main":false}]},{"type":"button","elements":[{"id":23,"lua":false,"waitForResponse":false,"caption":"↺ Back","name":"Back","empty":false,"msg":"KEY_158","buttonIcon":0,"favourite":false,"main":false},{"id":24,"lua":false,"waitForResponse":false,"caption":"▽","name":"Down","empty":false,"msg":"KEY_108","buttonIcon":0,"favourite":false,"main":false},{"id":25,"lua":false,"waitForResponse":false,"caption":"Text ☷","name":"Text","empty":false,"msg":"KEY_388","buttonIcon":0,"favourite":false,"main":false}]},{"type":"label","elements":[{"id":26,"lua":false,"waitForResponse":false,"caption":"Numeric","name":"Numeric","favourite":false,"main":false}]},{"type":"button","elements":[{"id":27,"lua":false,"waitForResponse":false,"caption":"1 [.,-]","name":"Num1","empty":false,"msg":"KEY_2","buttonIcon":0,"favourite":false,"main":false},{"id":28,"lua":false,"waitForResponse":false,"caption":"2 [abc]","name":"Num2","empty":false,"msg":"KEY_3","buttonIcon":0,"favourite":false,"main":false},{"id":29,"lua":false,"waitForResponse":false,"caption":"3 [def]","name":"Num3","empty":false,"msg":"KEY_4","buttonIcon":0,"favourite":false,"main":false}]},{"type":"button","elements":[{"id":30,"lua":false,"waitForResponse":false,"caption":"4 [ghi]","name":"Num4","empty":false,"msg":"KEY_5","buttonIcon":0,"favourite":false,"main":false},{"id":31,"lua":false,"waitForResponse":false,"caption":"5 [jkl]","name":"Num5","empty":false,"msg":"KEY_6","buttonIcon":0,"favourite":false,"main":false},{"id":32,"lua":false,"waitForResponse":false,"caption":"6 [mno]","name":"Num6","empty":false,"msg":"KEY_7","buttonIcon":0,"favourite":false,"main":false}]},{"type":"button","elements":[{"id":33,"lua":false,"waitForResponse":false,"caption":"7 [pqrs]","name":"Num7","empty":false,"msg":"KEY_8","buttonIcon":0,"favourite":false,"main":false},{"id":34,"lua":false,"waitForResponse":false,"caption":"8 [tuv]","name":"Num8","empty":false,"msg":"KEY_9","buttonIcon":0,"favourite":false,"main":false},{"id":35,"lua":false,"waitForResponse":false,"caption":"9 [wxyz]","name":"Num9","empty":false,"msg":"KEY_10","buttonIcon":0,"favourite":false,"main":false}]},{"type":"button","elements":[{"id":36,"lua":false,"waitForResponse":false,"caption":"[#]","name":"NumHash","empty":false,"msg":"KEY_1","buttonIcon":0,"favourite":false,"main":false},{"id":37,"lua":false,"waitForResponse":false,"caption":"0 [ ]","name":"Num0","empty":false,"msg":"KEY_11","buttonIcon":0,"favourite":false,"main":false},{"id":38,"lua":false,"waitForResponse":false,"caption":"[*]","name":"NumStar","empty":false,"msg":"KEY_12","buttonIcon":0,"favourite":false,"main":false}]},{"type":"label","elements":[{"id":39,"lua":false,"waitForResponse":false,"caption":"Functions","name":"Functions","favourite":false,"main":false}]},{"type":"button","elements":[{"id":40,"lua":false,"waitForResponse":false,"caption":"EPG","name":"EPG","empty":false,"msg":"KEY_365","buttonIcon":0,"favourite":false,"main":false},{"id":41,"lua":false,"waitForResponse":false,"caption":"VOD","name":"VOD","empty":false,"msg":"KEY_361","buttonIcon":0,"favourite":false,"main":false},{"id":42,"lua":false,"waitForResponse":false,"caption":"APP","name":"APP","empty":false,"msg":"KEY_367","buttonIcon":0,"favourite":false,"main":false},{"id":43,"lua":false,"waitForResponse":false,"caption":"LIST","name":"LIST","empty":false,"msg":"KEY_395","buttonIcon":0,"favourite":false,"main":false}]},{"type":"label","elements":[{"id":44,"lua":false,"waitForResponse":false,"caption":"Channels","name":"Channels","favourite":false,"main":false}]},{"type":"slider","elements":[{"id":45,"lua":true,"waitForResponse":false,"caption":"Channel","name":"Channel","msg":"","buttonIcon":0,"value":0,"favourite":false,"main":true}]},{"type":"button","elements":[{"id":46,"lua":false,"waitForResponse":false,"caption":"TVN 24","name":"TVN24","empty":false,"msg":"CHANNEL_6","buttonIcon":0,"favourite":false,"main":false}]},{"type":"button","elements":[{"id":47,"lua":false,"waitForResponse":false,"caption":"Eska TV","name":"EskaTV","empty":false,"msg":"CHANNEL_143","buttonIcon":0,"favourite":false,"main":false}]},{"type":"button","elements":[{"id":48,"lua":false,"waitForResponse":false,"caption":"Discovery HD","name":"Discovery","empty":false,"msg":"CHANNEL_73","buttonIcon":0,"favourite":false,"main":false}]}]');
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
      fibaro:debug("PLEASE BE PATIENT!...");
      fibaro:sleep(WAIT_TIME_AFTER_CHANGES * 1000);
      fibaro:debug("...");
      -- put to HC2
      response, status, errorCode = tcp:PUT("/api/virtualDevices", toPut);
      -- result?
      fibaro:debug("REQEST [" .. status .. "][" .. errorCode .. "][" .. string.len(response) .. "]");
      fibaro:abort();
      -- finish
      return nil, nil, nil, nil;
    else
      -- return tables
      return ready, buttons, keys, channels;
    end
  end
  -- return empty
  return nil, nil, nil, nil;
end

--[[
  PREPARE GLOBAL VARIABLE
]]--
function prepareGlobal(tcp, name)
  -- prepare gName
  gName = "";
  for v in string.gmatch(name, "%w") do
    if (gName=="") then
      for sv in string.gmatch(v, "%a") do
        gName = gName .. sv;
      end
    else
      gName = gName .. v;
    end
  end  
  value = fibaro:getGlobalValue(gName);
  if (value and tonumber(value)) then
    return gName;
  else
    response, status, errorCode = tcp:POST("/api/globalVariables", "name=" .. gName .. "&value=0");
    --fibaro:debug("Status of reqest: " .. status .. '.');
    if (errorCode==0 and status~="400") then
      fibaro:setGlobal(gName, "0");
      return gName;
    else
      return nil;
    end
  end
end

--[[
	FIND DECODER UUID
]]--
function getUID(tcpSocket, ip, port)
  tcpSocket:write("GET /upnpdev/ HTTP/1.1\n");
  tcpSocket:write("HOST: " .. ip .. ":" .. port .. "\n");
  tcpSocket:write("\n");
  fibaro:sleep(100);
  result, err = tcpSocket:read();
  --fibaro:debug("E: " .. err);
  if (err==0) then
    --fibaro:debug("R: " .. string.sub(result, 10, 13));
    start = string.find(result,  "li>uuid:");
    --fibaro:debug("S: " .. start);
    finish = string.find(result, "li>urn:");
    --fibaro:debug("F: " .. finish);
    if (start and finish and start>0 and finish>0 and finish>start) then
      data = string.sub(result, (start + 8), (finish - 6));
      return data;
    else
      return nil;
    end
  else
    return nil;
  end
end

--[[
	SEND UPNP REQEST
]]--
function upnpReqest(tcpSocket, ip, port, upnpUrl, upnpDomain, upnpService, upnpFunction, upnpContent)
  --fibaro:debug("POST " .. upnpUrl);
  reqest = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
  reqest = reqest .. "<s:Envelope";
  reqest = reqest .. " s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\"";
  reqest = reqest .. " xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">\n";
  reqest = reqest .. "<s:Body>\n";
  reqest = reqest .. "<u:" .. upnpFunction .. " ";
  reqest = reqest .. "xmlns:u=\"urn:" .. upnpDomain;
  reqest = reqest .. ":service:" .. upnpService .. "\">";
  reqest = reqest .. upnpContent;
  reqest = reqest .. "</u:" .. upnpFunction .. ">\n";
  reqest = reqest .. "</s:Body>\n";
  reqest = reqest .. "</s:Envelope>";
  --fibaro:debug("S: " .. string.len(reqest) .. "\n");
  tcpSocket:write("POST " .. upnpUrl .. " HTTP/1.1\n");
  tcpSocket:write("SOAPACTION: \"urn:" .. upnpDomain);
  tcpSocket:write(":service:" .. upnpService .. "#" .. upnpFunction);
  tcpSocket:write("\"\n");
  tcpSocket:write("Content-Length: " .. string.len(reqest) .. "\n");
  tcpSocket:write("CONTENT-TYPE: text/xml; charset=\"utf-8\"\n");
  tcpSocket:write("HOST: " .. ip .. ":" .. port .. "\n");
  tcpSocket:write("\n");
  tcpSocket:write(reqest);
  fibaro:sleep(100);
  result, err = tcpSocket:read();
  --fibaro:debug("R: " .. string.len(result));
  if (err==0) then
    start = string.find(result, upnpService .. "\">");
    finish = string.find(result, "</u:" .. upnpFunction);
    if (start and finish and start>0 and finish>0 and finish>start) then
      data = string.sub(result, (start + string.len(upnpService) + 2), (finish - 1));
      --fibaro:debug("D: " .. data);
      return data;
    else
      return 0;
    end
  else
    return nil;
  end
end


--[[
	SETUP PROGRAM
]]--

-- ip address of NC+
local virtualIP = nil;
-- port for tcp reqests
local virtualPort = nil;
-- id of virtual device
local virtualId = nil;
-- nc+ box uuid
local boxId = nil;

-- starting
fibaro:debug("RUNING...");

-- connect to HC2
fibaro:debug("Connecting to HC2...");
local tcpHC2 = Net.FHttp("localhost", 80);
if (not tcpHC2) then
  fibaro:debug("HC2 ERROR!");
  fibaro:abort();
end

-- authentication for HC2
tcpHC2:setBasicAuthentication(USER, PASSWORD);

-- ICONS
local iconON = 0;
local iconOFF = 0;
local iconERR = 0;

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
    iconON = virtualIcon;
    iconOFF = virtualIcon;
    iconERR = virtualIcon;
  end
  if (virtualIP and virtualPort) then
    fibaro:debug('IP [' .. virtualIP .. ']');
    fibaro:debug('Port [' .. virtualPort .. ']');
    fibaro:debug('---');
  else
    if (not virtualIP) then
      fibaro:debug('NO IP!');
    end
    if (not virtualPort) then
      fibaro:debug('NO PORT!');
    end
    fibaro:abort();
  end
else
  fibaro:debug("BROKEN SCRIPT OR WRONG LOGIN/PASSWORD!");
  fibaro:abort();
end

-- connection to NC+
fibaro:debug("CONNECTING TO NC+ [" .. virtualIP .. ":" .. virtualPort .. "]...");
local tcpNC = Net.FTcpSocket(virtualIP, virtualPort);
if (not tcpNC) then
  fibaro:debug("CONNECTING ERROR!");
  fibaro:abort();
end

-- getting UUID of NC+
fibaro:debug("Looking for device at this address...");
uuid = getUID(tcpNC, virtualIP, virtualPort);
if (uuid) then
  boxId = "uuid_" .. uuid;
  fibaro:debug("Found UUID: " .. boxId);
  fibaro:debug("---");
else
  fibaro:debug("NOT FOUND! CHECK YOUR IP AND PORT!");
  fibaro:abort();
end

-- declare button captions for icons
local buttonAtIcon = {};
-- declare key codes for icons
local keyAtIcon = {};
-- declare channels for icons
local channelAtIcon = {};

-- prepare global value
fibaro:debug("PREPARE VARIABLES...");
fibaro:debug("Creating global variable base on [" .. virtualName .. "]...");
local globalName = prepareGlobal(tcpHC2, virtualName);
if (globalName) then
  fibaro:debug("Global variable [" .. globalName .. "] is OK.");
  fibaro:debug("---");
else  
  fibaro:debug("Can't create global from name [" .. virtualName .. "]!");
  fibaro:abort();
end
-- prepare virtual device
fibaro:debug("PREPARING VIRTUAL DEVICE [" .. virtualId .. "]...");
ready, buttonAtIcon, keyAtIcon, channelAtIcon = prepareVirtualDevice(tcpHC2, virtualId, iconON);
if (ready and tonumber(ready)) then
  fibaro:debug("All buttons [" .. ready .. "] prepared and ready!");
  fibaro:debug("---");
else
  fibaro:debug("ERROR IN VIRTUAL DEVICE!");
  fibaro:abort();
end

-- CHECK ICONS
if (true) then
  -- prepare icons
  fibaro:debug("PREPARING ICONS...");
  -- get icons from fibaro.rafikel.pl
  fibaro:debug("Getting icons from server...");
  -- connect to server
  fibaro:debug("Connecting to [fibaro.rafikel.pl]...");
  local tcpSERVER = Net.FHttp("fibaro.rafikel.pl", 80);
  if (not tcpSERVER) then
    fibaro:debug("SERVER ERROR! Using default icons...");
  else
    -- ON icon
    iconOnSize, iconOnRaw  = getIconFromServer(tcpSERVER, "/icons/nc_on.png");
    if (iconOnSize and iconOnSize>0) then
      fibaro:debug("Received [ON] icon [" .. iconOnSize .. " bytes]. Searching in HC2...");
      id = getIconId(tcpHC2, iconOnRaw);
      if (id and tonumber(id) and id<1000) then
        fibaro:debug("NOT FOUND. Trying to upload icon to HC2...");
        id = uploadIcon(user, password, iconOnRaw);
      end
      if (id and tonumber(id) and id>=1000) then
        fibaro:debug("FOUNDED [" .. id .. "] ON HC2!");
        iconON = id;
      end
    end
    -- OFF icon
    iconOffSize, iconOffRaw  = getIconFromServer(tcpSERVER, "/icons/nc_off.png");
    if (iconOffSize>0) then
      fibaro:debug("Received [OFF] icon [" .. iconOnSize .. " bytes]. Searching in HC2...");
      id = getIconId(tcpHC2, iconOffRaw);
      if (id and tonumber(id) and id<1000) then
        fibaro:debug("NOT FOUND. Trying to upload icon to HC2...");
        id = uploadIcon(user, password, iconOffRaw);
      end
      if (id and tonumber(id) and id>=1000) then
        fibaro:debug("FOUNDED [" .. id .. "] ON HC2!");
        iconOFF = id;
      end
    end
    -- ERROR icon
    iconErrSize, iconErrRaw  = getIconFromServer(tcpSERVER, "/icons/nc_err.png");
    if (iconOnSize>0) then
      fibaro:debug("Received [ERROR] icon [" .. iconOnSize .. " bytes]. Searchin in HC2...");
      id = getIconId(tcpHC2, iconErrRaw);
      if (id and tonumber(id) and id<1000) then
        fibaro:debug("NOT FOUND. Trying to upload icon to HC2...");
        id = uploadIcon(user, password, iconErrRaw);
      end
      if (id and tonumber(id) and id>=1000) then
        fibaro:debug("FOUNDED [" .. id .. "] ON HC2!");
        iconERR = id;
      end
    end
  end
  -- finish
  fibaro:debug("---");
end



--[[
  MAIN LOOP 
  IF EVERYTHING 
  IS OK
]]--

-- variables for main loop
local counter = 0;
local prevState = 0;
local prevValue = 0;
local lastContact = 0;

-- key to send
local keyToSend = nil;

-- channel to send (4 digits)
local channelToSend = nil;

-- witch digit from channel next to send
local digitToSend = 0;

-- key code for digits
local digitCode = {[0]=11, [1]=2, [2]=3, [3]=4, [4]=5, [5]=6, [6]=7, [7]=8, [8]=9, [9]=10};

--[[
  SEND KEY DOWN AND UP
]]--
function sendKey(key)
  fibaro:log("Key down... " .. key);
  upnpReqest(tcpNC, virtualIP, virtualPort,
    "/upnpfun/ctrl/" .. boxId .. "/04",
    "adbglobal.com",
    "X_ADB_RemoteControl:1",
    "ProcessInputEvent",
    "<InputEvent>ev=keydn,code=" .. key .. "</InputEvent>"
  );
  fibaro:sleep(100);
  fibaro:log("Key up... " .. key);
  upnpReqest(tcpNC, virtualIP, virtualPort,
    "/upnpfun/ctrl/" .. boxId .. "/04",
    "adbglobal.com",
    "X_ADB_RemoteControl:1",
    "ProcessInputEvent",
    "<InputEvent>ev=keyup,code=" .. key .. "</InputEvent>"
  );
  fibaro:sleep(100);
end

--[[
  SET STATUS OF NC
]]--
function setState(state, description)
  -- print description
  if (description) then
    -- debug
    fibaro:debug("NC+ " .. description);
    -- log on home screen
    fibaro:log("NC+ " .. description);
    -- state label
    fibaro:call(virtualId, "setProperty", "ui.State.value",  description);
  end
  -- change state?
  if (state and tonumber(state)) then
    state = tonumber(state);
  else
    state = fibaro:getGlobalValue(globalName);
    if (state and tonumber(state)) then
      state = tonumber(state);
    else
      state = 0;
    end
  end
  -- what icon number?
  if (state==1) then 
    icon = iconON;
  elseif (state==0) then 
    icon = iconOFF;
  else
    icon = iconERR;
    state = 0;
  end
  -- set global variable
  if (fibaro:getGlobalValue(globalName)~=tostring(state)) then
    fibaro:setGlobal(globalName, tostring(state));
  end
  -- set icon
  fibaro:call(virtualId, "setProperty", "currentIcon",  icon);
  -- clear channel
  fibaro:call(virtualId, "setProperty", "ui.Channel.value",  0);
end

--[[
  MAIN LOOP
]]--

-- starting
fibaro:debug("STARTING MAIN LOOP...");

-- off state at start
setState(0, "START...");

-- if connection, send Prog+ and Prog-
if (tcpNC and PROBE_AT_START==1) then
  fibaro:debug("CHECK STATE...");
  sendKey(402);
  fibaro:sleep(600);
  sendKey(403);
end

-- start info
fibaro:debug("SYSTEM READY!");

-- main loop while connection is good
while (tcpNC) do
    
  -- if key was sended
  if (keyToSend and tonumber(keyToSend) and tonumber(keyToSend)>=0) then
    fibaro:debug("Key " .. keyToSend .. " OK");
    keyToSend = nil;
  end
    
  -- as for state id
  response = upnpReqest(tcpNC, virtualIP, virtualPort,
    "/upnpfun/ctrl/" .. boxId .. "/01",
    "schemas-upnp-org",
    "ContentDirectory:2",
    "GetSystemUpdateID",
    ""
  );
  
  -- if communication lost
  if (response==nil) then
    setState(-1, "Disconnected!");
    break;
  end
  
  -- search state id in response
  state = string.match(response, "<Id>(.*)</Id>");
  
  -- check what to send in 1 sec. loop
  i = 100; while (i>0) do

    -- decrese mini counter
    i = i - 1;
    
    -- check icon select - button click
    icon, ts = fibaro:get(virtualId, "currentIcon");
    if (icon and tonumber(icon) and tonumber(icon)>0 
        and math.floor(tonumber(icon)/1000)==virtualId
        and ts==os.time() 
    ) then
      action = "";
      icon = tonumber(icon);
      key = keyAtIcon[icon];
      channel = channelAtIcon[icon];
      buttonCaption = buttonAtIcon[icon];
      setState(nil, buttonCaption);      
      if (key and tonumber(key)) then 
        keyToSend = tonumber(key);
        action = "KEY_" .. keyToSend;
      elseif (channel and tonumber(channel)) then 
        digitToSend = 4;
        channelToSend = tonumber(channel);
        action = "CHANNEL_" .. channelToSend;
        fibaro:call(virtualId, "setProperty", "ui.Channel.value", channelToSend);
      else
        action = "---";
      end
      fibaro:debug("Action [" .. action .. "] from button.");
    end
    
    -- check slider select
    channel, ts = fibaro:get(virtualId, "ui.Channel.value");
    if (channel and tonumber(channel)) then
      channel = tonumber(channel);
      if (ts==os.time() and digitToSend==0 and channel>0) then
        setState(nil, "Channel " .. channel);
        fibaro:debug("Channel [" .. channel .. "] from slider.");
        channelToSend = channel;
        digitToSend = 4;
      end
    end

    -- check slider select with KEY
    key, ts = fibaro:get(virtualId, "ui.Key.value");
    if (key and tonumber(key)) then
      key = tonumber(key);
      if (ts==os.time() and key>0) then
        fibaro:debug("Key [" .. key .. "] from slider.");
        keyToSend = key;
      end
    end

    -- if channel to send?
    if (digitToSend>0) then
      key = 0;
      if (channelToSend and tonumber(channelToSend)) then
        channel = tonumber(channelToSend);
        number = math.floor(channel / 1000);
        channel = channel - (number * 1000);
        if (digitToSend==4) then key = number; end
        number = math.floor(channel / 100);
        channel = channel - (number * 100);
        if (digitToSend==3) then key = number; end
        number = math.floor(channel / 10);
        channel = channel - (number * 10);
        if (digitToSend==2) then key = number; end
        number = math.floor(channel / 1);
        if (digitToSend==1) then key = number; end
        digitToSend = digitToSend - 1;
      end
      if (digitCode[key] and tonumber(digitCode[key])) then
        keyToSend = tonumber(digitCode[key]);
      end
    end
      
    -- if key to send?
    if (keyToSend and tonumber(keyToSend)) then
      keyToSend = tonumber(keyToSend);
      sendKey(keyToSend);
      if (keyToSend==402 or keyToSend==403 or keyToSend==116) then
        lastContact = os.time();
      end
      break;
    end
      
    -- wait for next step
    fibaro:sleep(10);
  end
    
  -- CHECKING STATE OF NC+
  counter = counter + 1000;
  if (state and tonumber(state)~=prevState) then

    -- if first reading
    if (prevState==0) then
      prevState = tonumber(state);
    else

      -- after 6 sec
      if (counter>5000) then
        -- clear remebered prev value
        prevValue = 0;
        fibaro:debug("[" .. counter/1000 .. "]: Clear state!");
      end

      -- state nil (unknown)
      if (tonumber(state)==0) then
        fibaro:debug("[" .. counter/1000 .. "]: Null state!");

      -- after 5 sec
      elseif (counter>4000) then
        value = tonumber(state) - prevState;
        fibaro:debug("[" .. prevValue .. "]->[" .. counter/1000 .. " s.]->[" .. value .. "]");
        prevState = tonumber(state);
        if (counter<20000) then

          -- OFF - 8->6--->8->6->6
          if (false
            or (prevValue==8 and value==6)
            or (prevValue==6 and value==6)
          ) then setState(0, "OFF [" .. value .. "]");
          
          -- ON
          elseif (false
            or (value~=8 and value~=6 and prevValue~=8 and prevValue~=6)
          ) then setState(1, "ON [" .. value .. "]");
          
          -- OTHER
          else
            setState(nil, "State [" .. value .. "]");
          end
          
        end
        counter = 0;
        prevValue = value;
      end
    end
    -- last contact clear
    lastContact = 0;
  end

  -- if last contact (prog change) is without answer in 10 sec.
  if (lastContact>0 and (os.time()-lastContact)>10) then
    setState(-1, "No answer!");
    lastContact = 0;
  end

end 
-- END MAIN LOOP

-- RESTARTING
fibaro:debug("RESTARTING...");
  
-- DISCONNECT ALL SOCKETS
tcpHC2:disconnect();
tcpNC:disconnect();

-- SET ERROR STATE
setState(-1, "ERROR!");

-- WAIT BEFORE NEXT RUN
fibaro:sleep(WAIT_TIME_AFTER_CHANGES * 1000);

--[[END
  NC_PLUS_1_0 
  pl.rafikel.fibaro.ncplus
]]
