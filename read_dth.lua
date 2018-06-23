host = "http://noki.s1.natapp.cc/devices/post_data"
head = "content-length: 0\r\nContent-Type: text/plain\r\n"
ssid = "flyang"
pass = "123456qaz"
-- Configure Wireless Internet
function board_info()
print("\r\nMAC Address: "..wifi.sta.getmac().."\r")
print("Chip ID: "..node.chipid().."\r")
print("Heap Size: "..node.heap().."\r")
end

function init_wifi()
    board_info()
    for i = 1 , 3 , 1 do  
        wifi.setmode(wifi.STATION)
        wifi.sta.config{ssid=ssid,pwd=pass}
        wifi.sta.connect()
        if wifi.sta.getip() ~= nil then
            print("IP unavaiable, Waiting...wifi_connect_tried=",i)
            ip_address = wifi.sta.getip()
            print("The module MAC address is: " .. wifi.ap.getmac().."\r")
            print("Config Wifi done, IP is "..wifi.sta.getip().."\r")
            return ip_address
        end 
        tmr.delay(10000)
    end
    print("connect wi-fi failed!\r\n")
    return nil
end

function http_get(url)
 tmr.alarm(2, 10000, 1, function()
    http.post(url,head,"\r\n"
      function(code, data)
      if (code < 0) then
        print("HTTP request failed")
      else
        --change interva to 500 seconds to register
        
        tmr.interval(2,5000)
        print(code,data)
        t = cjson.decode(data)
        print("code=%s, response=%s",code,t["response"])
        print(t["csrf"])
        _G["csrf"] = t["csrf"] 
        rtctime.set(t["time"],0)
        tmr.stop(2)
      end     
  end)
 
 end)
end

function read_dht()
    local read_succ = 0
    tmr.alarm(3, 1000, 0, function()
    status, temp, humi, temp_dec, humi_dec = dht.read(4)
    --sec_time,msec_time = rtctime.get()
    sec_time,msec_time = tmr.time()
    if status == dht.OK  then
        --print(rtctime.get())
        print(string.format("DHT Temperature:%d.%03d;Humidity:%d.%03d\r\n",
              math.floor(temp),
              temp_dec,
              math.floor(humi),
              humi_dec))
        post_temperature_data(sec_time,temp, humi, temp_dec, humi_dec)
    elseif status == dht.ERROR_CHECKSUM then
        print( "DHT Checksum error." )
        
    elseif status == dht.ERROR_TIMEOUT then
        print( "DHT timed out." )
    elseif sec_time  == 0 then
       print "we could not got rtc time from server"
    end
  end)
  return
end

function post_temperature_data(sec_time,temp, humi, temp_dec, humi_dec)
     chipid = node.chipid()
     --temp_string = string.format('{"chipid:%s,time":%s,"temp":%s,"humi":%s}',chipid,sec_time,temp,humi)
     temp_string = string.format("/%s/%d.%03d/%d.%03d\r\n",
              chipid,
              math.floor(temp),
              temp_dec,
              math.floor(humi),
              humi_dec)
     web_url = host..temp_string;
     print(web_url)
     http_get(web_url)
end
init_wifi()
tmr.alarm(1, 1000, 0, function()
read_dht()
end)
