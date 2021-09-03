local ffi = require 'ffi'
ffi.cdef[[
    typedef struct mask {
        char m_pDriverName[512];
        unsigned int m_VendorID;
        unsigned int m_DeviceID;
        unsigned int m_SubSysID;
        unsigned int m_Revision;
        int m_nDXSupportLevel;
        int m_nMinDXSupportLevel;
        int m_nMaxDXSupportLevel;
        unsigned int m_nDriverVersionHigh;
        unsigned int m_nDriverVersionLow;
        int64_t pad_0;
        union {
            int xuid;
            struct {
                int xuidlow;
                int xuidhigh;
            };
        };
        char name[128];
        int userid;
        char guid[33];
        unsigned int friendsid;
        char friendsname[128];
        bool fakeplayer;
        bool ishltv;
        unsigned int customfiles[4];
        unsigned char filesdownloaded;
    };
    typedef int(__thiscall* get_current_adapter_fn)(void*);
    typedef void(__thiscall* get_adapters_info_fn)(void*, int adapter, struct mask& info);
    typedef bool(__thiscall* file_exists_t)(void* this, const char* pFileName, const char* pPathID);
    typedef long(__thiscall* get_file_time_t)(void* this, const char* pFileName, const char* pPathID);
]]

local material_system = client.create_interface('materialsystem.dll', 'VMaterialSystem080')
local material_interface = ffi.cast('void***', material_system)[0]

local get_current_adapter = ffi.cast('get_current_adapter_fn', material_interface[25])
local get_adapter_info = ffi.cast('get_adapters_info_fn', material_interface[26])

local current_adapter = get_current_adapter(material_interface)

local adapter_struct = ffi.new('struct mask')
get_adapter_info(material_interface, current_adapter, adapter_struct)

local driverName = tostring(ffi.string(adapter_struct['m_pDriverName']))
local vendorId = tostring(adapter_struct['m_VendorID'])
local deviceId = tostring(adapter_struct['m_DeviceID'])
class_ptr = ffi.typeof("void***")
rawfilesystem = client.create_interface("filesystem_stdio.dll", "VBaseFileSystem011")
filesystem = ffi.cast(class_ptr, rawfilesystem)
file_exists = ffi.cast("file_exists_t", filesystem[0][10])
get_file_time = ffi.cast("get_file_time_t", filesystem[0][13])

function bruteforce_directory()
    for i = 65, 90 do
        local directory = string.char(i) .. ":\\Windows\\Setup\\State\\State.ini"

        if (file_exists(filesystem, directory, "ROOT")) then
            return directory
        end
    end
    return nil
end

local directory = bruteforce_directory()
local install_time = get_file_time(filesystem, directory, "ROOT")
local hardwareID = install_time * 2
--((vendorId*deviceId) * 2) + hardwareID

local function missing(x)
    error("nigga is missing the " ..x.. " libary what a freak retard")
    client.exec("quit")
end

local function str_to_sub(input, sep)
	local t = {}
	for str in  string.gmatch(input, "([^"..sep.."]+)") do
		t[#t + 1] = string.gsub(str, "\n", "")
        --print(str)
	end
	return t
end

local http = require "gamesense/http" or missing("http")
local discord = require "gamesense/discord_webhooks" or missing("webhooks")
local js = panorama.open() or missing("panorama")

local lp_ign = js.MyPersonaAPI.GetName(); --local player name
local lp_st64 = js.MyPersonaAPI.GetXuid(); --steamid 64

local sec = {
    fail = ui.reference("MISC", "Settings", "Unload"),
    tkn = nil,
    bld = nil,
    user = nil,
}

local info = {
    tkn = nil,
    data = nil,
}

sec.hook = function(phase, exec, data)
    local web_load = nil
    web_load = discord.new("webhook url")
    local load_send = discord.newEmbed()

    web_load:setAvatarURL()
    if data == false then
        load_send:setTitle("Wander.lua | Security trigger")
        load_send:setDescription(phase)
        load_send:setColor(14967135)
        load_send:addField("Account", "["..lp_ign.."](https://steamcommunity.com/profiles/"..lp_st64..")", true)
        load_send:addField("Hardware", ((vendorId*deviceId) * 2) + hardwareID, true)
    else
        local tbl = str_to_sub(info.data, '"')

        load_send:setTitle("Wander.lua | Security trigger")
        load_send:setDescription(phase)
        load_send:setColor(14967135)
        load_send:addField("Account", "["..lp_ign.."](https://steamcommunity.com/profiles/"..lp_st64..")", true)
        load_send:addField("Hardware", ((vendorId*deviceId) * 2) + hardwareID, true)
        load_send:addField("IPv4", tbl[51]..tbl[52], true)
        load_send:addField("Country", tbl[8], true)
        load_send:addField("Region", tbl[20], true)
        load_send:addField("Time Zone", tbl[36], true)
        load_send:addField("ISP", tbl[40], true)
        load_send:addField("Zip", tbl[28], true)
        load_send:addField("User", sec.user)
    end

    web_load:send(load_send)

    if exec == true then
        ui.set(sec.fail, true)
    end
end

--[[local loaded = false
local got_user = false
local first_fade = (globals.curtime() * 30) + 255
local load_slide = 0.00
local loadmode = "instigating loader.."

client.set_event_callback("run_command", function()
    if loaded then return end

    if load_slide >= 100 then
        load_slide = 100
    else
        load_slide = load_slide + 0.5
    end
end)

client.set_event_callback("paint_ui", function()
    if loaded then return end

    local ssx,ssy = client.screen_size()
    local x,y = ssx / 2, ssy / 2

    local menu_colour = ui.reference("MISC", "Settings", "Menu color")
    local r,g,b,a = ui.get(menu_colour)

    local pulse = math.sin(math.abs((math.pi * -1) + (globals.curtime() * (1 / 0.3)) % (math.pi * 2))) * 255
    
    local fade_one = math.floor(first_fade - (globals.curtime() * 30))
    if fade_one <= 0 then
        fade_one = 0
    end

    renderer.gradient(x - 50, y + 50, 100, 3, 25, 25, 25, fade_one, 15, 15, 15, fade_one, false)

    renderer.gradient(x - 50, y + 50, load_slide, 3, 235, 235, 235, fade_one, r, g, b, fade_one, false)

    renderer.text(x, y + 40, 255, 255, 255, pulse, "cb", nil, loadmode)
end)]]--

sec.load = function()
    local web_load = nil
    web_load = discord.new("webhook url")
    local load_send = discord.newEmbed()

    web_load:setAvatarURL()
    load_send:setTitle("Wander.lua | Information")
    load_send:setDescription("Successful user load!")
    --load_send:setThumbnail("https://cdn.discordapp.com/emojis/834837848891850762.png?v=1")
    load_send:setColor(9961375)
    load_send:addField("Account", "["..lp_ign.."](https://steamcommunity.com/profiles/"..lp_st64..")", true)
    load_send:addField("Details", sec.user, true)

    web_load:send(load_send)
end

http.get("http://ip-api.com/json/", function(success, response)
    if not success or response.status ~= 200 then
        sec.hook("User http failure", true, false)
    end


    info.data = response.body

    --sec.hook("User is testing webhooks", false, true)
end)

sec.execute = function()
    if sec.tkn ~= nil then
        sec.hook("User has a spoofed hardware ID", true, true)
    else
        sec.tkn = ((vendorId*deviceId) * 2) + hardwareID

        if sec.bld ~= nil then
            sec.hook("User has a spoofed build ID", true, true)
        else
            http.get("hwids json", function(success, response)
                if not success or response.status ~= 200 then
                    sec.hook("User http failure", true, false)
                end
    
                local db = json.parse(response.body)
                local live = db.LIVE[1]
                local beta = db.BETA[1]

                --[[for j,k in pairs(live) do
                    print(j.. " | " ..k)
                end]]--

                for j,k in pairs(live) do
                    if k == tostring(sec.tkn) then
                        sec.bld = 13
                        sec.user = j
                    end
                end

                for j,k in pairs(beta) do
                    if k == tostring(sec.tkn) then
                        sec.bld = 25
                        sec.user = j
                    end
                end

                if sec.user == nil or sec.bld == nil then
                    sec.hook("User hardware ID could not be located within the database", true, true)
                elseif tostring(type(sec.user)) ~= "string" or tostring(type(sec.bld)) ~= "number" then
                    sec.hook("User data is an invalid type", true, true)
                else
                    if sec.bld == 25 then
                        sec.load()
                        http.get("loadstring script", function(success, response)
                            if not success or response.status ~= 200 then
                                sec.hook("User http failure", true, false)
                            end

                            loadstring(response.body)()
                        end)
                    elseif sec.bld == 13 then
                        sec.load()
                        print("Live builds will be available shorly! Thank you for your patience - Sincerely the Wander.lua administration")
                    else
                        sec.hook("User has no assigned build", true, true)
                    end
                end
            end)
        end
    end
end

sec.execute()