--[[
    Wander.lua | Notes & Ideas
        - distort body yaw(?) <= pulsate additives
        - rotate head y to face left and face right and then trace to those
]]

local function missing(x)
    error("nigga is missing the " ..x.. " libary what a freak retard")
    client.exec("quit")
end

--local ffi = require "ffi" or client.exec("quit");
--local http = require "gamesense/http" or client.exec("quit");
--local discord = require "gamesense/discord_webhooks" or client.exec("quit");
--local images = require "gamesense/images" or client.exec("quit");
local bit = require "bit" or missing("bit")
--local csgo_weapons = require "gamesense/csgo_weapons" or client.exec("quit");
--local js = panorama.open() or client.exec("quit");
local js = panorama.open() or missing("panorama")

local lp_ign = js.MyPersonaAPI.GetName(); --local player name
local lp_st64 = js.MyPersonaAPI.GetXuid(); --steamid 64

--[[
    start
]]

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

http.get("http://ip-api.com/json/", function(success, response)
    if not success or response.status ~= 200 then
        sec.hook("User http failure", false, false)
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
                end
            end)
        end
    end
end

--sec.execute()

--[[
    end
]]

local client_userid_to_entindex, client_set_event_callback, client_screen_size, client_trace_bullet,
    client_unset_event_callback, client_color_log, client_scale_damage, client_get_cvar, client_camera_position,
    client_create_interface, client_random_int, client_latency, client_find_signature, client_delay_call,
    client_trace_line, client_register_esp_flag, client_exec, client_set_cvar, client_error_log,
    client_update_player_list, client_camera_angles, client_eye_position, client_draw_hitboxes, client_random_float,
    entity_get_local_player, entity_is_enemy, entity_get_bounding_box, entity_get_all, entity_set_prop, entity_is_alive,
    entity_get_steam64, entity_get_classname, entity_get_player_resource, entity_is_dormant, entity_get_player_name,
    entity_hitbox_position, entity_get_player_weapon, entity_get_players, entity_get_prop, globals_tickcount,
    globals_curtime, globals_tickinterval, ui_new_slider, ui_new_combobox, ui_reference, ui_set_visible, ui_new_textbox,
    ui_new_color_picker, ui_new_checkbox, ui_new_listbox, ui_new_multiselect, ui_new_hotkey, ui_set, ui_set_callback,
    ui_new_button, ui_new_label, ui_new_string, ui_get, renderer_world_to_screen, renderer_circle_outline,
    renderer_rectangle, renderer_gradient, renderer_circle, renderer_text, renderer_line, renderer_triangle,
    renderer_measure_text, renderer_indicator, math_ceil, math_tan, math_randomseed, math_cos, math_sinh, math_random,
    math_huge, math_pi, math_max, math_atan2, math_ldexp, math_floor, math_sqrt, math_deg, math_atan, math_fmod,
    math_acos, math_pow, math_abs, math_min, math_sin, math_frexp, math_log, math_tanh, math_exp, math_modf, math_cosh,
    math_asin, math_rad, table_clear, table_move, table_pack, table_foreach, table_sort, table_remove, table_foreachi,
    table_unpack, table_concat, table_insert, string_format, string_len, string_gsub, string_match, string_byte,
    string_char, string_upper, string_lower, string_sub, bit_band, panorama_loadstring = client.userid_to_entindex,
    client.set_event_callback, client.screen_size, client.trace_bullet, client.unset_event_callback, client.color_log,
    client.scale_damage, client.get_cvar, client.camera_position, client.create_interface, client.random_int,
    client.latency, client.find_signature, client.delay_call, client.trace_line, client.register_esp_flag, client.exec,
    client.set_cvar, client.error_log, client.update_player_list, client.camera_angles, client.eye_position,
    client.draw_hitboxes, client.random_float, entity.get_local_player, entity.is_enemy, entity.get_bounding_box,
    entity.get_all, entity.set_prop, entity.is_alive, entity.get_steam64, entity.get_classname,
    entity.get_player_resource, entity.is_dormant, entity.get_player_name, entity.hitbox_position,
    entity.get_player_weapon, entity.get_players, entity.get_prop, globals.tickcount, globals.curtime,
    globals.tickinterval, ui.new_slider, ui.new_combobox, ui.reference, ui.set_visible, ui.new_textbox,
    ui.new_color_picker, ui.new_checkbox, ui.new_listbox, ui.new_multiselect, ui.new_hotkey, ui.set, ui.set_callback,
    ui.new_button, ui.new_label, ui.new_string, ui.get, renderer.world_to_screen, renderer.circle_outline,
    renderer.rectangle, renderer.gradient, renderer.circle, renderer.text, renderer.line, renderer.triangle,
    renderer.measure_text, renderer.indicator, math.ceil, math.tan, math.randomseed, math.cos, math.sinh, math.random,
    math.huge, math.pi, math.max, math.atan2, math.ldexp, math.floor, math.sqrt, math.deg, math.atan, math.fmod,
    math.acos, math.pow, math.abs, math.min, math.sin, math.frexp, math.log, math.tanh, math.exp, math.modf, math.cosh,
    math.asin, math.rad, table.clear, table.move, table.pack, table.foreach, table.sort, table.remove, table.foreachi,
    table.unpack, table.concat, table.insert, string.format, string.len, string.gsub, string.match, string.byte,
    string.char, string.upper, string.lower, string.sub, bit.band, panorama.loadstring -- thanks sid <3


local menu = {
    master_switch = ui_new_checkbox("LUA", "B", "Wander.lua | Enable"),
    seperator = ui_new_label("LUA", "B", "-=-=-=-=-=-=-=-=-=-=-=-=-"),
    anti_aim = ui_new_multiselect("LUA", "B", "Anti-aim options", "Prediction", "Anti-bruteforce", "Jitter on dormant", "In-air"),
    fallback = ui_new_combobox("LUA", "B", "Fallback type", "Storage", "Jitter"),
    --prediction = ui_new_slider("LUA", "B", "", 0, 10, 0.5, false, "x"),
    visuals = ui_new_multiselect("LUA", "B", "Indicators", "Crosshair", "Arrows", "Status"),
    accent = ui_new_color_picker("LUA", "B", "Accent", 145, 145, 255, 255),
    misc = ui_new_multiselect("LUA", "B", "Miscellaneous", "Animations", "Clantag", "Killsay"),
}

local ref = {
    menu = ui_reference("MISC", "Settings", "Menu color"),
    rage = { ui_reference("RAGE", "Aimbot", "Enabled") },
    damage = ui_reference("RAGE", "Aimbot", "Minimum damage"),
    dt = { ui_reference("RAGE", "Other", "Double tap") },
    dt_hc = ui_reference("RAGE", "Other", "Double tap hit chance"),
    fd = ui_reference("RAGE", "Other", "Duck peek assist"),
    mupc = ui_reference("MISC", "Settings", "sv_maxusrcmdprocessticks"),
    anti_aim = { ui_reference("AA", "Anti-aimbot angles", "Enabled") },
    pitch = ui_reference("AA", "Anti-aimbot angles", "Pitch"),
    yaw = {ui_reference("AA", "Anti-aimbot angles", "Yaw")},
    yaw_base = ui_reference("AA", "Anti-aimbot angles", "Yaw Base"),
    jitter = { ui_reference("AA", "Anti-aimbot angles", "Yaw jitter") },
    body_yaw = { ui_reference("AA", "Anti-aimbot angles", "Body yaw") },
    fs = { ui_reference("AA", "Anti-aimbot angles", "Freestanding")},
    fs_body_yaw = ui_reference("AA", "Anti-aimbot angles", "Freestanding body yaw"),
    fake_limit = ui_reference("AA", "Anti-aimbot angles", "Fake yaw limit"),
    legs = ui_reference("AA", "Other", "Leg movement"),
    slow = { ui_reference("AA", "other", "slow motion") },
    third_person = { ui_reference("VISUALS", "Effects", "Force third person (alive)") },
    wall = ui_reference("VISUALS", "Effects", "Transparent walls"),
    prop = ui_reference("VISUALS", "Effects", "Transparent props"),
    skybox = ui_reference("VISUALS", "Effects", "Remove Skybox"),
    edge = ui_reference("AA", "Anti-aimbot angles", "Edge yaw"),
    fl = ui_reference("AA", "Fake lag", "Enabled"),
    fl_amt = ui_reference("AA", "Fake lag", "Amount"),
    fl_var = ui_reference("AA", "Fake lag", "Variance"),
    fl_limit = ui_reference("AA", "Fake lag", "Limit"),
    hs = { ui_reference("AA", "Other", "On shot anti-aim") },
}

local vars = {
    status = "Default",
    target = nil,
    threat = 0.00,
    ext_side = {false, false},
    ext_dmg = {0, 0},
    distance = 8192.0,
    miss_info = {},
    last_miss = globals.curtime() + 4,
    miss_ent = nil,
    fs_side = 1,
    bf_side = 1,
    x_adj = nil,
    should_double = false,
}

client_set_event_callback("run_command", function()
    -- reset modules storage
    vars.target = nil
    vars.threat = 1

    local origin_threat = 0

    -- define local player
    local me = entity_get_local_player()
    -- check if the nigga is dead (not needed if runcmd but whatever dumb nigga camden does dumb nigga shit)
    if not entity_is_alive(me) then return end

    -- get our available enemy indexes
    local enemies = entity_get_players(true)

    -- sort through our enemies indexes
    for i=1, #enemies do
        local enem_weapon = entity_get_classname(entity_get_player_weapon(enemies[i]))
        -- weapon consideration
        if enem_weapon == "CWeaponAWP" then
            vars.threat = vars.threat + 1
        elseif enem_weapon == "CWeaponSSG08" and entity_get_prop(me, "m_iHealth") <= 92 then
            vars.threat = vars.threat + (1 - (entity_get_prop(me, "m_iHealth") / 100))
        end
        -- damage consideration
        local enem_pos = { entity_get_prop(enemies[i], "m_vecOrigin") }
        local your_pos = { entity_get_prop(me, "m_vecOrigin") }
        local trace_ent, trace_dmg = client_trace_bullet(me, your_pos[1], your_pos[2], your_pos[3], enem_pos[1], enem_pos[2], enem_pos[3], false)
        if trace_dmg > 0 then
            vars.threat = vars.threat + (1 - (trace_dmg / 100))
        end
        -- health
        vars.threat = vars.threat - (1 - (entity_get_prop(enemies[i], "m_iHealth") / 100))

        if vars.threat > origin_threat then
            origin_threat = vars.threat
            vars.target = enemies[i]
        end
    end
end)

local function includes(table, key)
    local state = false
    for i = 1, #table do
        if table[i] == key then
            state = true
            break
        end
    end
    return state
end

local function clamp(num, min, max)
    if num > max then
        return max
    elseif min > num then
        return min
    end
    return num
end

local function round(x)
    return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end

local function get_velocity(ent)
    local x, y, z = entity_get_prop(ent, "m_vecVelocity")
    return (x * x) + (y * y)
end

client_set_event_callback("run_command", function()

    if vars.target == nil then return end

    local me = entity_get_local_player()

    local prev_dmg = 0
    vars.x_adj = nil
    vars.ext_side[1] = false
    vars.ext_side[2] = false
    vars.ext_dmg[1] = 0
    vars.ext_dmg[2] = 0

    -- ext_side | ext_dmg
    local ex,ey,ez = entity_get_prop(vars.target, "m_vecOrigin")
    local lx,ly,lz = entity_get_prop(me, "m_vecOrigin")
    local llz, lrz = (lz - 90), (lz + 90)
    for x = 0, 25, 1 do
        local llx, lrx =  lx + x, lx - x
        local lde,lddmg = client_trace_bullet(me, llx, ly, llz, ex, ey, ez, false)
        local rde,rddmg = client_trace_bullet(me, lrx, ly, lrz, ex, ey, ez, false)

        --[[if vars.x_adj == nil and (vars.ext_side[1] or vars.ext_side[2]) then
            vars.x_adj = x
        end]]--

        if rddmg > prev_dmg then
            vars.ext_dmg[2] = clamp(rddmg, 0, 120)
            prev_dmg = rddmg
            vars.x_adj = x
            vars.ext_side[2] = true
        end
    
        if lddmg > prev_dmg then
            vars.ext_dmg[1] = clamp(lddmg, 0, 120)
            prev_dmg = lddmg
            vars.x_adj = x
            vars.ext_side[1] = true
        end
    end

    --print(vars.x_adj == nil and "false" or vars.x_adj.. " | " ..prev_dmg)

    -- distance
    vars.distance = math_abs((ex - lx) + (ey - ly) + (ez - lz))

    -- freestanding
    local ps = (ex - lx)
    vars.fs_side = ps > 0 and 1 or -1
    if includes(ui_get(menu.anti_aim), "Anti-bruteforce") then
        vars.fs_side = vars.fs_side * vars.bf_side
    end
end)

local function normalize_yaw(yaw)
	while yaw > 180 do yaw = yaw - 360 end
	while yaw < -180 do yaw = yaw + 360 end
	return yaw
end

local function world2scren(xdelta, ydelta)
	if xdelta == 0 and ydelta == 0 then
		return 0
	end
	return math_deg(math_atan2(ydelta, xdelta))
end

client_set_event_callback("bullet_impact", function(e)
    local me = entity_get_local_player() -- retrieve local player index

    if entity_is_alive(me) == false then return end -- if local player is not alive then return end

    if vars.target == nil then return end -- if no enemy is available then quit

    local enemy = client_userid_to_entindex(e.userid) -- user shot data

    if not entity_is_enemy(enemy) or entity_is_dormant(enemy) then return end

    local lx, ly, lz = entity_hitbox_position(me, "head_0")

    local ex,ey,ez = entity_get_prop(enemy, "m_vecOrigin") -- get enemy positions
    local mx,my,mz = entity_get_prop(me, "m_vecOrigin") -- get local player positions

    local dist = ((e.y - ey)*lx - (e.x - ex)*ly + e.x*ey - e.y*ex) / math_sqrt((e.y-ey)^2 + (e.x - ex)^2) -- calculating bullet miss radius

    if dist <= 120 then -- shot radious is within the assigned
        vars.miss_info[vars.target] = round(dist)
        vars.alast_miss = globals.curtime()
        vars.miss_ent = enemy
        vars.should_double = true
    end
end)

local clantag = {
    "",
    " ",
    "r ",
    "er ",
    "der ",
    "nder ",
    "ander ",
    "wander ",
    "wander ",
    "wander",
    " wander",
    " wande",
    " wand",
    " wan",
    " wa",
    " w",
    " ",
    "",
}

client.set_event_callback("setup_command",function(e)
    local weaponn = entity_get_player_weapon()
    if client.key_state(0x45) then
        if weaponn ~= nil and entity_get_classname(weaponn) == "CC4" then
            if e.in_attack == 1 then
                e.in_attack = 0 
                e.in_use = 1
            end
        else
            if e.chokedcommands == 0 then
                e.in_use = 0
            end
        end
    end
end)

local ground_ticks = 0
local end_time = 0
client_set_event_callback("pre_render", function()
    if not entity_is_alive(entity_get_local_player()) then return end

    local on_ground = bit.band(entity_get_prop(entity_get_local_player(), "m_fFlags"), 1)

    if on_ground == 1 then
        ground_ticks = ground_ticks + 1
    else
        ground_ticks = 0
        end_time = globals_curtime() + 1
    end 

    --[[if ground_ticks > ui.get(ref.fl_limit) + 1 and end_time > globals.curtime() and includes(ui.get(menu.animation), "Reset pitch on land") then
        entity.set_prop(entity.get_local_player(), "m_flPoseParameter", 0.5, 12)
    end]]--

    if includes(ui_get(menu.misc), "Animations") and on_ground then
        entity_set_prop(entity_get_local_player(), "m_flPoseParameter", 1, 6)
	else
        if includes(ui_get(menu.misc), "Animations") then
            entity_set_prop(entity_get_local_player(), "m_flPoseParameter", 0)
        end
    end
end)

local function get_airstate(ent)
    if ent == nil then return false, 0 end
    local flags = entity_get_prop(ent, "m_fFlags")
    if bit.band(flags, 1) == 0 then
        return true
    end
    return false
end

client_set_event_callback("run_command", function()
    if not ui_get(menu.master_switch) then return end

    if includes(ui_get(menu.misc), "Clantag") then
        local length = clamp(#clantag, 1, #clantag)
        local clock = math.ceil(globals.curtime() % length)
        local tag = clantag[clock]
        --print(clock.. " | "..clantag[clock])
        client.set_clan_tag(tag)
    end

    if vars.target == nil then 
        --[[
            Dormancy Phase
            - Stage 0
        ]]
        vars.status = "Dormant"

        ui_set(ref.pitch, "Minimal")
        ui_set(ref.yaw[1], "180")
        ui_set(ref.yaw[2], vars.bf_side)
        if vars.ext_side[1] == true or vars.ext_side[2] == true then
            if get_airstate(entity_get_local_player()) then
                ui_set(ref.jitter[2], 19)
            else
                ui_set(ref.jitter[2], 8)
            end
        else
            ui_set(ref.jitter[1], "Off")
            ui_set(ref.jitter[2], 0)
        end
        ui_set(ref.body_yaw[1], includes(ui_get(menu.anti_aim), "Jitter on dormant") and "Jitter" or "Opposite")
        ui_set(ref.body_yaw[2], 0)
        ui_set(ref.fs_body_yaw, true)
        local fake_store = 0
        ui_set(ref.fake_limit, 57)
        for k = 1, #vars.miss_info do
            if vars.miss_info[k] == nil then return end
            fake_store = math_max(fake_store, (60 - (vars.miss_info[k] > 60 and (vars.miss_info[k] / 2) or (vars.miss_info[k]))))
            ui_set(ref.fake_limit, clamp(round(fake_store), 13, 60))
        end
    else
        --[[
                    if get_airstate(entity_get_local_player()) == true then
            vars.status = "Air"

            ui_set(ref.pitch, "Minimal")
            ui_set(ref.yaw[1], "180")
            ui_set(ref.yaw[2], 0)

            if vars.ext_side[1] == true or vars.ext_side[2] == true then
                ui_set(ref.body_yaw[1], "Jitter")
            else
                ui_set(ref.body_yaw[1], "Static")
            end
            ui_set(ref.body_yaw[2], 90 * vars.fs_side)

            ui_set(ref.fs_body_yaw, false)
            
            ui_set(ref.fake_limit, 28)
        else
        ]]
        if get_airstate(entity_get_local_player()) == true and includes(ui_get(menu.anti_aim), "In-air") then
            vars.status = "Air"

            ui_set(ref.pitch, "Minimal")
            ui_set(ref.yaw[1], "180")
            ui_set(ref.yaw[2], 0)

            if vars.ext_side[1] == true or vars.ext_side[2] == true then
                ui_set(ref.body_yaw[1], "Jitter")
            else
                ui_set(ref.body_yaw[1], "Static")
            end
            ui_set(ref.body_yaw[2], math_random(0,180) * vars.fs_side)

            ui_set(ref.fs_body_yaw, false)
            
            ui_set(ref.fake_limit, 28)
        elseif 2 > (globals_curtime() - vars.last_miss) and includes(ui_get(menu.anti_aim), "Prediction") then
            --[[
                Index phase
                - Stage 2
            ]]
            vars.status = "Safety"
    
            ui_set(ref.pitch, "Minimal")
            ui_set(ref.yaw[1], "180")
            ui_set(ref.yaw[2], -vars.target * vars.fs_side)
    
            ui_set(ref.jitter[1], "Offset")
            ui_set(ref.jitter[2], 5 * vars.fs_side)
    
            ui_set(ref.body_yaw[1], "Static")
            ui_set(ref.body_yaw[2], -60 * vars.fs_side)
    
            ui_set(ref.fs_body_yaw, false)
            
            if vars.miss_info[vars.target] ~= nil then
                ui_set(ref.fake_limit, clamp(round(math_min(23, (vars.miss_info[vars.target] > 60 and (vars.miss_info[vars.target] / 2) or (vars.miss_info[vars.target])))), 5, 23))
            else
                ui_set(ref.fake_limit, 13)
            end
        elseif vars.ext_side[1] == true then
            --[[
                Vulnerable phase
                - Stage 1
            ]]
            vars.status = "Left : " ..math_floor(vars.ext_dmg[1] / 10)

            ui_set(ref.pitch, "Minimal")
            ui_set(ref.yaw[1], "180")
            ui_set(ref.yaw[2], -vars.target)

            ui_set(ref.jitter[1], "Offset")
            if get_airstate(entity_get_local_player()) or vars.x_adj == nil then
                ui_set(ref.jitter[2], 19)
            else
                ui_set(ref.jitter[2], (vars.x_adj / 25))
            end

            ui_set(ref.body_yaw[1], "Static")
            ui_set(ref.body_yaw[2], -90 * (includes(ui_get(menu.anti_aim), "Anti-bruteforce") and vars.bf_side or 1))

            ui_set(ref.fs_body_yaw, false)
            
            ui_set(ref.fake_limit, round(math_abs(math_max(28, (vars.ext_dmg[1] > 60 and (vars.ext_dmg[2] / 2) or (vars.ext_dmg[1]))))))
        elseif vars.ext_side[2] == true then
            --[[
                Vulnerable phase
                - Stage 1
            ]]
            vars.status = "Right : " ..math_floor(vars.ext_dmg[2] / 10)

            ui_set(ref.pitch, "Minimal")
            ui_set(ref.yaw[1], "180")
            ui_set(ref.yaw[2], vars.target)

            if get_airstate(entity_get_local_player()) or vars.x_adj == nil then
                ui_set(ref.jitter[1], "Off")
                ui_set(ref.jitter[2], 0)
            else
                ui_set(ref.jitter[1], "Offset")
                ui_set(ref.jitter[2], (vars.x_adj / 25))
            end

            ui_set(ref.body_yaw[1], "Static")
            ui_set(ref.body_yaw[2], 90 * (includes(ui_get(menu.anti_aim), "Anti-bruteforce") and vars.bf_side or 1))

            ui_set(ref.fs_body_yaw, false)
            
            ui_set(ref.fake_limit, math_abs(round(math_max(28, (vars.ext_dmg[2] > 60 and (vars.ext_dmg[2] / 2) or (vars.ext_dmg[2]))))))
        else
            vars.status = "Stored"
            vars.should_double = false

            ui_set(ref.pitch, "Minimal")
            ui_set(ref.yaw[1], "180")

            ui_set(ref.body_yaw[2], 180 * vars.fs_side)

            ui_set(ref.fs_body_yaw, false)

            if ui_get(menu.fallback) == "Jitter" then
                vars.status = "Jitter"
                ui_set(ref.yaw[2], vars.bf_side)
                ui_set(ref.jitter[1], "Off")
                ui_set(ref.jitter[2], 0)
                ui_set(ref.body_yaw[1], "Jitter")
                ui_set(ref.fake_limit, 57)
            end
        end
    end
end)

client_set_event_callback("paint", function()
    if not ui_get(menu.master_switch) then return end

    local sx, sy = client_screen_size()
    local x, y = sx / 2, sy / 2

    local r,g,b,a = ui_get(menu.accent)

    local pulse = round(math.sin(math.abs((math.pi * -1) + (globals.curtime() * (1 / 0.3)) % (math.pi * 2))) * 255)

    local me = entity_get_local_player()
    if not entity_is_alive(me) then return end

    local desync = math_min(57, math_abs(entity_get_prop(entity_get_local_player(), "m_flPoseParameter", 11)*120-60))

    --renderer_text(x, y + 15, 255, 255, 255, 255, "-", nil, string_upper(vars.status))

    if includes(ui_get(menu.visuals), "Crosshair") then
        --renderer_text(x, y + 20, r, g, b, pulse, "-", nil, "WANDER")
        renderer_text(x, y + 40, r, g, b, pulse, "c", nil, "WANDER")
        renderer_gradient(x - 1, y + 30, desync, 3, r, g, b, a, 0, 0, 0, 55, true)
        renderer_gradient(x - desync, y + 30, desync, 3, 0, 0, 0, 55, r, g, b, a, true)
        renderer_text(x + 1, y + 20, 255, 255, 255, 255, "c", nil, round(desync).. "°")
    end

    if includes(ui_get(menu.visuals), "Status") then
        renderer_text(x - 1, y + (includes(ui_get(menu.visuals), "Crosshair") and 50 or 15), 255, 255, 255, 255, "c-", nil, string_upper(vars.status))
    end

    if ui_get(ref.body_yaw[1]) ~= "Jitter" and includes(ui_get(menu.visuals), "Arrows") then
        if ui_get(ref.body_yaw[2]) > 0 then
            renderer_text(x - 40, y - 2, 255, 255, 255, 255, "c+", nil, "<")
            renderer_text(x + 40, y - 2, r, g, b, a, "c+", nil, vars.should_double and ">>" or ">")
        else
            renderer_text(x - 40, y - 2, r, g, b, a, "c+", nil, vars.should_double and "<<" or "<")
            renderer_text(x + 40, y - 2, 255, 255, 255, 255, "c+", nil, ">")
        end
    end

    --print(ui_get(ref.fake_limit))
end)

local killsay = {
    "wander lua boss owning the 2k lua scene ̿ ̿ ̿'̿'̵͇̿з=(•_•)=ε/̵͇̿/'̿'̿ ̿ ",
    "(◣_◢) god king allah wander abuser downs another panorama joiner (◣_◢)",
    "╭∩╮(-_-)╭∩╮ stay mad freaks wander lua always on top",
    "∩ ( ͡⚆ ͜ʖ ͡⚆) ∩ kamistyle bitchhhhhhh",
    "[̲̅$̲̅(̲̅100)̲̅$̲̅] racks on racks nigga",
    "ᗜᴗᗜ holzing ohajha erp stans ᗜᴗᗜ",
    "(╯°□°)╯︵ ┻━┻ camdenstyle bitchhh", 
    "( ‾ʖ̫‾) HS bitch by the one and only wander lua",
    "(▀̿Ĺ̯▀̿ ̿) not even ideal tick.xyz could save you there",
    "ᕦ( ͡° ͜ʖ ͡°)ᕤ pwned by wander lua",
    "ᕙ(▀̿̿Ĺ̯̿̿▀̿ ̿) ᕗ negative IQ moment",
    "(╬ಠ益ಠ) esoterik anti aim",
    "︻╦╤─ headshot iqless nigga down",
    "┌П┐(►˛◄’!) feed ur hack some carrot cake",
    "凸( •̀_•́ )凸 ohajha headshot moment",
    "(‡▼益▼) best lua of all time @ shoppy.gg/@wanderlua",
    "(⋋▂⋌) laff headshot by wander @ discord.gg/qPDNDSjJAE",
    "( ͡°👅 ͡°) xo dodging 2v2s moment",
    "[̲̅$̲̅(̲̅ ͡° ͜ʖ ͡°̲̅)̲̅$̲̅] killed a semi rager moment",
    "┏(-_-)┛ you play worse then pedophile tayte moment",
    "ʘ‿ʘ mhai only using skeet to semi rage",
    "ʘ‿ʘ mhai only using skeet to semi rage",
    "( ͡°╭͜ʖ╮͡° ) cheat boosted retard down",
    "(ᵔᴥᵔ) femboy hvher down",
    "(◔̯◔ waifu femboy dodging 2v2 moment"
}

client_set_event_callback("player_death", function(e)
    if client_userid_to_entindex(e.userid) ~= entity_get_local_player() and client_userid_to_entindex(e.attacker) == entity_get_local_player() and includes(ui_get(menu.misc), "Killsay") then
        client_exec("say " ..killsay[math.random(1,#killsay)])
    end
end)

--[[client_set_event_callback("run_command", function()
    local test, test_log = entity.po
    print(test_log)
end)]]--