-- OPEN WEATHER
-- LUA script by fibaro.rafikel.pl
-- version 1.0, 2014-06-23

-- Access to HC2 admin account is neccessary for control 
-- virtual device in non standard way. Enter user/password:
USER = "admin"
PASSWORD = "admin"

--[[WEATHER
  pl.rafikel.fibaro.weather
]]--

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
  READ THIS VIRTUAL DEVICE (id, ip, port)
--]]
function readVirtualDevice(tcp)
  rnd = random(32);
  fibaro:log(rnd);
  response, status, errorCode = tcp:GET("/api/virtualDevices");
  if (tonumber(status)~=200) then
    fibaro:log("");
    return nil;
  else
    jsonTable = json.decode(response);
    for virtualIndex, virtualData in pairs(jsonTable) do
      if (virtualData.type=="virtual_device") then
        check = string.find(fibaro:get(virtualData.id, "log"), rnd);
        if (check and check>0) then
		  fibaro:log("");
          return virtualData;
        end
      end
    end
  end
  fibaro:log("");
  return nil;
end

--[[
  PREPARE GLOBAL VARIABLE
]]--
function prepareGlobal(tcp, name, enums)
  local gName = trim(name);
  local value, ts; value, ts = fibaro:getGlobal(gName);
  -- fibaro:debug("CREATE [" .. gName .. ']...');
  if (value and ts > 0) then
    --fibaro:debug("Global [" .. gName .. '] = [' .. value .. '].');
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

-- Global names
local Name = "";

-- City
local City = "";

-- Period
local Period = 600;

-- HC2
local tcpHC2 = Net.FHttp("localhost", 80); 
tcpHC2:setBasicAuthentication(USER, PASSWORD);

-- This virtual device
fibaro:debug("Searching virtual device...");
virtual = readVirtualDevice(tcpHC2);
if (virtual == nil) then
  fibaro:debug("HC2 ERROR!");
  fibaro:abort();
else
  fibaro:debug('Found ID [' .. virtual.id .. ']');
  if (virtual.name) then
    Name = virtual.name;
    fibaro:debug('Name [' .. Name .. ']');
  end
  if (virtual.properties.ip) then
    City = virtual.properties.ip;
    fibaro:debug('City [' .. City .. ']');
  end
  if (virtual.properties.port) then
    Period = tonumber(virtual.properties.port);
    fibaro:debug('Period [' .. Period .. ']');
  end
  for rowIndex, rowData in pairs(virtual.properties.rows) do 
    fibaro:debug('  Row [' .. rowIndex .. '][' .. rowData.type .. ']');
  end
end

-- hours index before and after
local hours = {
  ["3"] = {
    ["seconds"] = 10800
  },
  ["6"] = {
    ["seconds"] = 21600
  }
}

-- prepare globals
fibaro:debug("Creating global [" .. Name .. "]...");
local globalName = prepareGlobal(tcpHC2, Name);
if (not globalName) then
  fibaro:debug("ERROR GLOBAL!");
  fibaro:abort();
end

-- connect to service
fibaro:debug("Connecting to service...");
tcp = Net.FHttp("api.openweathermap.org", 80);
if (not tcp) then
  fibaro:debug("SERVICE ERROR!");
else while tcp do
  -- actual timestamp
  local ts = os.time();
  -- array for forecast
  local forecast = {};
  -- getting forecast
  r, s, e = tcp:GET("/data/2.5/forecast?q=" .. City .. "&mode=json&units=metric&lang=pl");
  if (s == "200") then
    -- everything ok?
    local ok = true;
    -- change data.rain.3h to data.rain.mm
    r = string.gsub(r, "\"3h\":", "\"mm\":");
    -- decode json result
    local jsonTable = json.decode("[" .. r .. "]");
    -- grab first element of json array
    local js = jsonTable[1];
    -- print info
    fibaro:debug(
      "Weather for: " .. js.city.name .. " " ..
      "[" .. js.city.country .. "] " ..
      "[" .. js.cnt .. " records]..."
    );
    -- refresh timestamp
    ts = os.time();
    -- clear indexes
    for h, f in pairs(hours) do
      hours[h]["before"] = 0;
      hours[h]["after"] = f["seconds"] * 2;
    end
    -- all records
    for i, data in pairs(js.list) do
      -- number of seconds betwen data and actual timestamps
      local dif = tonumber(data.dt) - tonumber(ts);
      -- searching before and after data for all hours
      for h, f in pairs(hours) do
  	    forecast[f["seconds"]] = {};
        if (dif >= f["before"] and dif <= f["seconds"]) then hours[h]["before"] = dif; end
        if (dif <= f["after"] and dif >= f["seconds"]) then hours[h]["after"] = dif; end
      end
      -- check all values
      if (
        data.main == nil
        or 
        data.weather == nil
        or
        data.clouds == nil
        or
        data.wind == nil
        or
        data.rain == nil
      ) then
        -- problem?
        printr(data, 0, "Data error");
        ok = false;
        break;
      end
      -- grab forecast from data
      forecast[dif] = {
        -- temperature in st. C.
        ["temp"] = data.main.temp,
        -- pressure in hPa
        ["pressure"] = data.main.pressure,
        -- code from http://openweathermap.org/weather-conditions
        ["weather"] = data.weather.id,
        -- humidity in %
        ["humidity"] = data.main.humidity,
        -- clouds cover in %
        ["clouds"] = data.clouds.all,
        -- wind direction in degrees
        ["windDeg"] = data.wind.deg,
        -- wind speed in km/h
        ["windSpeed"] = data.wind.speed,
        -- rain in milimeters/m2
        ["rain"] = data.rain.mm
      };
    end -- for all records
    -- if everything ok?
    if (ok) then
      -- all hours
      for h, f in pairs(hours) do
        -- take indexes
        local b = f["before"];
        local s = f["seconds"];
        local a = f["after"];
        -- calculate percent
        local p = (s - b) / (a - b);
        -- print data indexes for hour
        fibaro:debug(h .. ": " .. b .. " -> " .. s .. " [" .. math.floor(p * 100) .. " %]" .. " -> " .. a .. ".");
        -- all values
        for k, v1 in pairs(forecast[b]) do
          -- take after value
          local v2 = forecast[a][k];
          -- calculate weather for hour
          forecast[s][k] = math.floor((v1 + (p * (v2 - v1))) * 100) / 100;
          -- test global
          local n = globalName .. h .. k;
          local v, ts; v, ts = fibaro:getGlobal(n);
          -- if not setted
          if (v and ts > 0) then else
            v = 0;
            prepareGlobal(tcpHC2, n);
          end
          -- if diffrent
          if (v ~= forecast[s][k]) then
            -- set global
            fibaro:setGlobal(n, forecast[s][k]);
            -- print data indexes for hour
            local t = k .. ": " .. v1 .. " -> " .. forecast[s][k] .. " -> " .. v2;
            fibaro:debug(string.rep(string.char(0xC2, 0xA0), 3) .. t .. ".");
            fibaro:log(t);
          end
        end
        -- printr(forecast[b], 0, b);
        -- printr(forecast[s], 0, s);
        -- printr(forecast[a], 0, a);
      end -- for all hours
	-- something not ok
    else
      printr(hours, 0, "Hours");
      printr(forecast, 0, "Forecast");
    end -- processing end
  else -- answer ok
    -- error in debug
    fibaro:debug(s .. " : " .. e .. " : " .. #r);
    -- error in log
    fibaro:log("Error " .. s .. " : " .. e .. " : " .. #r);
  end
  -- next check timestamp
  nextCheck = ts + Period;
  -- print next check as text
  fibaro:debug("Next check: " .. os.date("%X", nextCheck) .. " [" .. Period .. " seconds]...");
  -- wait defined time in seconds
  fibaro:sleep(Period * 1000);
end end
-- sleep ten minutes before restart
fibaro:sleep(60000);
-- print info about restart
fibaro:debug('Restart...');
