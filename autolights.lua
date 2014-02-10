-- LIGHTS AUTOMATION
-- LUA script by fibaro.rafikel.pl
-- version 1.3, 2014-02-10, license GPL

-- Documentations available on Fibaro forum at this topics:
-- http://forum.fibaro.com/viewtopic.php?t=2693 (EN)
-- http://forum.fibaro.com/viewtopic.php?t=2686 (PL)

-- Access to HC2 admin account is neccessary for control 
-- virtual device in non standard way. Enter user/password:
USER = "admin"
PASSWORD = "admin"

-- FUTURES:
-- Automatic switching off lights after counting time.
-- Extension of light time based on events (eg move, doors, etc.). 
-- Without interfering with the manual control.
-- Each light has its own timer. 
-- Dimming light for a defined time. 
-- Easy access to functions from the scenes. 
-- Everything is based on one single virtual device, 
-- For presentation timer and counting using slider - one for each device. 
-- Switching the light in the scenes you can make in the traditional way, or... 
-- ... simply by setting the slider value (setting the timer) - nothing more! 
-- You can adjust the slider (timer) in many scenes together.
-- If you want to set timer (slider) from scene to any value...
-- ... even if it is lower than actual, use minused value (eg. -600).

-- TODO:
-- Possibilites to separate setting dimm level in manual steering.

-- Donate this project: http://goo.gl/GVi94D
-- Any qestions? Need help? Go to forum.fibaro.com.


--[[AUTOLIGHTS
  pl.rafikel.fibaro.autolights
]]--

-- show status on debug window 
fibaro:debug("Getting list of virtual devices..."); 
-- connect to HC2 
HC2 = Net.FHttp("localhost", 80); 
-- with authentication 
HC2:setBasicAuthentication(USER, PASSWORD);
-- grab virtual devices list from api 
response, status, errorCode = HC2:GET("/api/virtualDevices"); 
-- show status on debug window 
fibaro:debug("Status of reqest: " .. status .. '.');

-- if answer is wrong 
if (tonumber(status)~=200) then
  fibaro:debug("Error " .. errorCode .. ".");
end

-- prepare places for previous values 
oldValues = {};
oldTimers = {};
lastWakeTime = {};

-- icons 
iconOn = 0; 
iconOff = 0; 
iconVId = 0; 

-- variables for summary 
globalValue = 0; 
globalSliderId = 0; 
globalSliderVId = 0; 
globalLabelId = 0; 
globalLabelVId = 0;

-- function to prepare value for sliders
function clockValue(val)
  clock = "";
  if (not tonumber(val)) then val = 0 end
  if (val<0) then val = 0 end
  m = math.floor( val/60 );
  s = math.floor( val - (m*60) );
  if (m<10) then clock = clock .. "0" end
  if (m) then clock = clock .. m .. "." end
  if (s<10) then clock = clock .. "0" end
  if (s) then clock = clock .. s end
  return clock;
end

-- main loop if answer is ok 
while (tonumber(status)==200) do 
  -- reset data of fastest device to switch off 
  fastestDevice = ""; 
  fastestTimer = 0; 
  fastestDeviceId = 0; 
  fastestSlider = 0;
  iconOn = 0;
  iconOff = 0;
  iconVId = 0; 
  -- decode text to json object 
  jsonTable = json.decode(response); 
  -- roll over all virtual devices 
  for virtualIndex, virtualData in pairs(jsonTable) do 
    -- fibaro:debug('Virtual Device Id [' .. virtualData.id .. ']'); 
    -- roll over all rows in virtual device 
    for rowIndex, rowData in pairs(virtualData.properties.rows) do 
      -- fibaro:debug('  Row [' .. rowIndex .. '][' .. rowData.type .. ']'); 
      -- if row type is label 
      if (rowData.type=='label') then 
        -- rool over all buttons in row 
        for labelIndex, labelData in pairs(rowData.elements) do 
          -- check if that is main label 
          if (globalLabelId==0 and labelData.name=='globalLabel') then 
            globalLabelVId = tonumber(virtualData.id); 
            globalLabelId = tonumber(labelData.id); 
            fibaro:debug('Label ' .. globalLabelId .. ' / ' .. globalLabelVId .. '.'); 
          end 
        end 
      end 
      -- if row type is slider 
      if (rowData.type=='slider') then 
        -- rool over all buttons in row 
        for sliderIndex, sliderData in pairs(rowData.elements) do 
          -- check if that is main slider 
          if (sliderData.name=='globalSlider') then 
            -- if not defined yet? 
            if (globalSliderId==0) then 
              globalSliderVId = virtualData.id; 
              globalSliderId = sliderData.id; 
              fibaro:debug('Global slider ' .. globalSliderId .. ' / ' .. globalSliderVId .. '.'); 
            end 
          end 
          -- check if button (slider) has right defined code? 
          if (string.find(sliderData.msg, "{")==1) then 
            -- decode defined code for button (slider) 
            sliderParams = json.decode(sliderData.msg); 
            -- if autoOff parameter is present? 
            if (sliderParams.action=="autoOff") then 
              
              -- grab device information from definition 
              deviceId = sliderParams.deviceId; 
              deviceType = fibaro:getType(deviceId); 
              deviceName = fibaro:getName(deviceId); 
              deviceValue, deviceTS = fibaro:get(deviceId, 'value'); 
              deviceSeconds = os.time() - deviceTS; 
              deviceValue = tonumber(deviceValue); 
              deviceDead =  tonumber(fibaro:getValue(deviceId, "dead")); 
              
              -- grab slider information 
              sliderId = sliderData.id;
              sliderName = "ui." .. sliderData.name .. ".value";
              sliderValue, sliderTS = fibaro:get(virtualData.id, sliderName);
              sliderSeconds = os.time() - sliderTS;
              sliderValue = tonumber(sliderValue);
              
              -- make old values if necessary 
              if (not oldValues[deviceId]) then 
                --fibaro:log('New device [' .. deviceName .. '][' .. deviceId .. ']!'); 
                fibaro:debug('New device [' .. deviceName .. '][' .. deviceId .. '] Type [' .. deviceType .. '] Value [' .. deviceValue .. '].'); 
                oldValues[deviceId] = 0; 
                oldTimers[deviceId] = 0; 
              end
              
              -- value from slider is not number?
              if (not sliderValue or (sliderValue % 1)>0 ) then
                --fibaro:debug(sliderData.caption .. " Set... [" .. sliderValue .. "]");
                sliderValue = oldTimers[deviceId];
              end

              -- set timer to lower value if slider below zero
              if (sliderValue<0) then 
                sliderValue = math.abs(sliderValue);
                fibaro:debug(sliderData.caption .. " Without checking... [" .. sliderValue .. "]");

              -- slider value is smaller than prev value
              elseif ( (oldTimers[deviceId]-sliderValue) > 2 ) then
                sliderValue = oldTimers[deviceId];
              end

              -- slider value to number
              sliderValue = tonumber(sliderValue);
              
              -- checking if its dead?
              if (deviceDead>0) then
                wakePeriod = sliderParams.wakeTime;
                if (wakePeriod) then wakePeriod = tonumber(wakePeriod) end
                if (not wakePeriod) then wakePeriod = 3600 end
                if (not lastWakeTime[deviceId] or lastWakeTime[deviceId]>wakePeriod) then
                  lastWakeTime[deviceId] = 0;
                  fibaro:wakeUpDeadDevice(deviceId);
                  fibaro:debug('WAKE UP [' .. deviceId .. ']...');
                else
                  --fibaro:debug('Device [' .. deviceId .. '] dead  [' .. lastWakeTime[deviceId] .. ']!');
                  lastWakeTime[deviceId] = lastWakeTime[deviceId] + 1;
                end
                sliderValue = 0;
              --end 

              -- turn on by slider 
              -- detecting if device has to be switched on 
              -- if slider changes eg. from scenes 
              elseif (sliderValue>0 and ((deviceValue==0 and deviceSeconds>2) or sliderValue>oldTimers[deviceId])) then 
                -- if device type is dimmer 
                if (deviceType=="dimmable_light") then 
                  -- if default value for dimmer is defined 
                  if (sliderParams.defaultValue) then 
                    -- set dimmer value to that 
                    fibaro:call(deviceId, 'setValue', tonumber(sliderParams.defaultValue)); 
                    -- remember new value as actual 
                    deviceValue = tonumber(sliderParams.defaultValue); 
                  -- if dimmer has not defined starting value 
                  else 
                    -- set maximum 
                    fibaro:call(deviceId, 'setValue', 100);
                    -- and remember as actual
                    deviceValue = 100;
                  end
                  -- log to home screen 
                  fibaro:log(sliderData.caption .. ' ON [' .. deviceValue .. '] by Slider [' .. sliderValue .. ']!'); 
                -- if device is binary switch or another 
                else 
                  -- remember as actual 
                  deviceValue = 1; 
                  -- basic switch on 
                  fibaro:call(deviceId, 'turnOn'); 
                  -- log to home screen 
                  fibaro:log(sliderData.caption .. ' ON by Slider [' .. sliderValue .. ']!'); 
                end 
              -- end 

              -- manualy on          
              -- if default value for timer is defined 
              -- and device was manualy switched on 
              -- and new status (value) is biggest than previously 
              -- and sliderValue==0? 
              elseif (sliderParams.defaultTime and deviceValue>oldValues[deviceId]) then 
                -- set slider value to defined time 
                sliderValue = sliderParams.defaultTime;
                -- if default starting value for dimmer device is defined? 
                if (sliderParams.defaultValue) then 
                  -- use maximum of defined dimmer value
                  deviceValue = tonumber(sliderParams.defaultValue);
                  fibaro:call(deviceId, 'setValue', deviceValue);
                end 
                -- log to home screen 
                fibaro:log(sliderData.caption .. ' Manual ON [' .. deviceValue .. ']!');
              -- end 
              
              -- manual off 
              elseif (sliderValue>0 and deviceValue==0 and deviceSeconds<2) then 
                sliderValue = 0; 
                -- show log on home screen 
                fibaro:log(sliderData.caption .. ' Aborting!'); 
                -- update slider value to show left time - zero 
                -- fibaro:call(virtualData.id, "setSlider", sliderData.id, sliderValue);
                fibaro:call(virtualData.id, "setProperty", sliderName,  sliderValue); 
              --end 
              
              -- switch off by slider 
              elseif (sliderValue==0 and oldTimers[deviceId]>0) then 
                -- log on home screen 
                fibaro:log(sliderData.caption .. ' OFF by slider!'); 
                -- switch off device 
                fibaro:call(deviceId, 'turnOff'); 
              --end 
                  
              -- counting to down 
              elseif (sliderValue>0) then 

                -- decresing slider value 
                sliderValue = sliderValue - 1; 

                -- debug on window
                fibaro:debug('Device [' .. deviceId .. ']: Value [' .. deviceValue .. '][' .. deviceSeconds .. ' s.]; Slider [' .. sliderValue .. '][' .. sliderSeconds .. ' s.];'); 

                -- time to switch off 
                if (sliderValue==0) then 
                  -- log on home screen 
                  fibaro:log(sliderData.caption .. ' Auto OFF!'); 
                  -- switch off device 
                  fibaro:call(deviceId, 'turnOff'); 
                --end 
              
                -- update dimmer level 
                -- if defined "dimming time" parameter? 
                elseif (sliderParams.dimmTime and deviceType=="dimmable_light") then 
                  dimmTime = tonumber(sliderParams.dimmTime); 
                  -- if default starting value for dimmer device is defined? 
                  if (sliderParams.defaultValue) then 
                    -- calculate dimmer step for one second 
                    -- use starting default value for dimmer device 
                    dimmStep = tonumber(sliderParams.defaultValue) / dimmTime; 
                    --dimmStep = deviceValue / dimmTime; 
                  else 
                    -- calculate dimmer step for one second 
                    -- use 100% value for dimmer device 
                    dimmStep = 100 / dimmTime; 
                  end 
                  -- if time to start dimming 
                  if (sliderValue<dimmTime) then 
                    -- calculate dimmer value 
                    newVal = sliderValue * dimmStep; 
                    -- in other case use maximum value 
                  else 
                    -- if default starting value for dimmer device is defined? 
                    if (sliderParams.defaultValue) then 
                      -- use maximum of defined dimmer value 
                      newVal = tonumber(sliderParams.defaultValue); 
                    else 
                      -- use 100% 
                      newVal = 100; 
                    end 
                  end 
                  -- if calculated value is lower then 1 
                  if (newVal<1) then 
                    newVal = 1; 
                  end 
                  -- if calculated value is grater then 100 
                  if (newVal>100) then 
                    newVal = 100; 
                  end 
                  -- set the new dimmer value if calculated value is lower then actual 
                  -- or new value is bigger but depending of slider (time) changes 
                  if (newVal<deviceValue or sliderValue>oldTimers[deviceId]) then 
                    fibaro:call(deviceId, 'setValue', newVal+1); 
                  end 
                end 
              
              end 

              -- update fastest timer and device name and icons 
              if ((sliderValue>0 or oldValues[deviceId]>1)
              and (sliderValue<fastestTimer or fastestTimer==0))
              then
                fastestTimer = sliderValue;
                fastestDevice = sliderData.caption;
                fastestDeviceId = deviceId; 
                fastestSlider = sliderData.id; 
                iconVId = virtualData.id; 
                iconOff = virtualData.properties.deviceIcon; 
                iconOn = sliderData.buttonIcon; 
              end 

              -- remeber old values and timers (sliders) 
              oldValues[deviceId] = deviceValue; 
              oldTimers[deviceId] = sliderValue; 
              
              -- select new value on the slider
              new = clockValue(sliderValue);
              old = fibaro:getValue(virtualData.id, sliderName);
              if (new ~= old) then
                fibaro:call(virtualData.id, "setProperty", sliderName, new);
              end
              
            end 
          end 
        end 
      end 
    end 
  end 

  --fibaro:debug(fastestDevice .. '... [' .. fastestTimer .. ']...');
  
  -- update main slider
  if (globalSliderId and globalSliderVId) then
    old = fibaro:getValue(globalSliderVId, "ui.globalSlider.value");
    new = clockValue(fastestTimer);
    if (new ~= old) then
      fibaro:call(globalSliderVId, "setProperty", "ui.globalSlider.value", new);
    end
  end
  
  -- update main label 
  if (globalLabelId and globalLabelVId) then 
    new = "---";
    if (fastestTimer>0) then
      new = "";
      h = math.floor( fastestTimer/3600 );
      m = math.floor( ( fastestTimer - (h*3600) )/60 );
      s = math.floor( fastestTimer - (h*3600) - (m*60) );
      if (h>0) then new = new .. h .. ":" end
      if (m<10) then new = new .. "0" end
      new = new .. m .. ":";
      if (s<10) then new = new .. "0" end
      new = new .. s;
      new = new .. " " .. fastestDevice;
    end
    old = fibaro:getValue(globalSliderVId, "ui.globalLabel.value");
    if (new ~= old) then
      fibaro:call(globalLabelVId, "setProperty", "ui.globalLabel.value", new);
    end
  end 
    
  -- update icon to ON
  if (iconVId and iconOn) then 
    fibaro:call(iconVId, "setProperty", "currentIcon", iconOn); 
  end 

  -- WAIT
  fibaro:sleep(500); 

  -- update icon to OFF 
  if (iconVId and iconOff) then 
    fibaro:call(iconVId, "setProperty", "currentIcon", iconOff); 
  end 
  
  -- WAIT
  fibaro:sleep(500);
  
end 
-- if everything is ok, the main loop will never end 

-- wait after API error 
fibaro:sleep(10000); 
