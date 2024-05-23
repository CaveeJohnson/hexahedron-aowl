do
	print("aowl.lua: disabled since superseded by tetra")
	return
end

-- Check enums to see if easylua and luadata loaded.
-- We need both of these, so abort loading if they didn't.
assert(FAST_ADDON_EASYLUA, "aowl requires easylua!")
assert(FAST_ADDON_LUADATA, "aowl requires luadata!")
--pcall(include, "autorun/translation.lua") local L = translation and translation.L or function(s) return s end

-- Create the function for getting localised versions of strings.
-- We don't have translation.lua so for now it does nothing.
local function L(s) return s end

-- Create the table if it doesn't exist.
aowl = aowl or {}

-- The link opened with !faq/!rules/!motd.
aowl.MOTDURL	= 	"http://hexahedron.pw/forums"
aowl.RulesURL 	=	"http://hexahedron.pw/forums/showthread.php?tid=16&pid=33#pid33"
aowl.ReportURL	= 	"http://hexahedron.pw/forums/forumdisplay.php?fid=6"
aowl.ApplyURL	=	"http://hexahedron.pw/forums/forumdisplay.php?fid=13"

-- These are the locations that you can teleport to using
-- !goto and such, they can also be a function, as seen below.
aowl.GotoLocations = aowl.GotoLocations or {}

aowl.GotoLocations["spawn"] = function(p) p:Spawn() end

-- Basewars_Evocity_v2

aowl.GotoLocations["nexus@Basewars_Evocity_v2"]      = Vector(-6879.2250976563, -9000.919921875, 72.03125)
aowl.GotoLocations["bank@Basewars_Evocity_v2"]       = Vector(-6326.525390625, -7694.244140625, 72.03125)
aowl.GotoLocations["waterplant@Basewars_Evocity_v2"] = Vector(-11040.340820313, 9272.5478515625, 64.03125)
aowl.GotoLocations["industrial@Basewars_Evocity_v2"] = Vector(2483.7912597656, 4982.7670898438, 64.03125)
aowl.GotoLocations["pool@Basewars_Evocity_v2"]       = Vector(3101.5810546875, -7062.9052734375, 154.72442626953)
aowl.GotoLocations["bar@Basewars_Evocity_v2"]        = Vector(11062.176757813, 307.13858032227, 58.255279541016)
aowl.GotoLocations["forest@Basewars_Evocity_v2"]     = Vector(5144.3510742188, 13035.440429688, 64.031265258789)
aowl.GotoLocations["cave@Basewars_Evocity_v2"]       = Vector(-8925.6181640625, 13292.494140625, 186.03125)
aowl.GotoLocations["adminhouse@Basewars_Evocity_v2"] = Vector(-8570.0595703125, -7623.0029296875, 456.03125)
aowl.GotoLocations["adminroom@Basewars_Evocity_v2"]  = Vector(67.129699707031, 4334.9604492188, -916.90979003906)
aowl.GotoLocations["garage@Basewars_Evocity_v2"]     = Vector(-7022.8232421875, -9320.2109375, -127.96967315674)

-- rp_downtown_v4c_v2

aowl.GotoLocations["hlf@rp_downtown_v4c_v2"]         = Vector(-910,-1100, 340)
aowl.GotoLocations["admin@rp_downtown_v4c_v2"]       = Vector(1305, -6278, -199)

-- Call a hook to tell any other files that we are done
-- loading. This is used for plugins and adding commands.
local function aowl_initialised()
	hook.Run("AowlInitialized")
end
timer.Simple(1, aowl_initialised)

-- Create the convar (seems unused?), ctrl+f doesn't find any other occurences. Look into this.
aowl.HideRanks = CreateConVar("aowl_hide_ranks", "1", FCVAR_REPLICATED)

-- These patterns are used to detect the format of chat commands.
aowl.Prefix			= "[!|/|%.]" 	-- a pattern
aowl.StringPattern	= "[\"|']" 		-- another pattern
aowl.ArgSepPattern	= "[,]" 		-- would you imagine that yet another one
aowl.EscapePattern	= "[\\]" 		-- holy shit another one! holy shit again they are all teh same length! Unintentional! I promise!!1

-- Cache the color we used to print messages.
local colCyan = Color(51, 255, 204, 255)

-- This should really be inside of aowl, but may be used outside of this file.
function aowlMsg(cmd, line)
	-- Call a hook to see if we should hide the message.
	local ok = hook.Run("AowlMessage", cmd, line)

	if (ok != false) then
		MsgC(colCyan, "[aowl]" .. (cmd and ' ' .. tostring(cmd) or "") .. ' ')
		MsgN(line)
	end
end

-- This is never used either. This seems to be quite useful, maybe we should move it
-- to aowl.Compare and replace some more basic checks in the commands,
local function compare(a, b)
	if (a == b) 									then return true end
	if (a:find(b, nil, true)) 						then return true end
	if (a:lower() == b:lower()) 					then return true end
	if (a:lower():find(b:lower(), nil, true)) 		then return true end

	return false
end

-- DarkRP causes a really stupid double hooking issue.
-- This removes it's 'double hook' and stops the issues
if (SERVER and GAMEMODE and GAMEMODE.OldChatHooks and GAMEMODE.OldChatHooks.aowl_say_cmd) then
	GAMEMODE.OldChatHooks.aowl_say_cmd = nil
end

-- This function is used to turn a string, usually from a player speaking,
-- into a parsed table of arguments, see the patterns above for what it uses.
function aowl.ParseArgs(str)
	local ret 		= {}
	local InString 	= false
	local strchar 	= ""
	local chr 		= ""
	local escaped 	= false

	-- Iterate for each character
	for i=1, #str do
		local char = str[i]

		if (escaped) then
			chr = chr..char
			escaped = false

			continue
		end

		if (char:find(aowl.StringPattern) and not InString and not escaped) then
			InString 	= true
			strchar 	= char

		elseif (char:find(aowl.EscapePattern)) then
			escaped 	= true

			continue

		elseif (InString and char == strchar) then
			ret[#ret+1] = chr:Trim()
			chr 		= ""
			InString 	= false

		elseif (char:find(aowl.ArgSepPattern) and not InString and chr != "") then
			ret[#ret+1] = chr
			chr 		= ""

		else
			chr = chr .. char

		end
	end

	if (chr:Trim():len() != 0) then
		ret[#ret+1] = chr
	end

	return ret
end

-- This function allows you to convert a SID64, or CommunityID into a conventional
-- 32 bit SID.
function aowl.CommunityIDToSteamID(id)
	local s = "76561197960"

	if (id:sub(1, #s) != s) then
		return "UNKNOWN"
	end

	local c = tonumber(id)
	local a = id % 2 == 0 and 0 or 1
	local b = (c - 76561197960265728 - a) / 2

	if (not a or not b) then
		return "UNKNOWN"
	end

	return "STEAM_0:" .. a .. ":" .. (b + 2)
end

-- This function does the inverse of the one above. It takes a 32 bit SID and
-- returns a 64 bit SID.
function aowl.SteamIDToCommunityID(id)
	if (id == "BOT" or id == "NULL" or id == "STEAM_ID_PENDING" or id == "UNKNOWN") then
		return 0
	end

	local parts = id:Split(":")
	local a, b 	= parts[2], parts[3]

	if (not a or not b) then
		return 0
	end

	return tostring("7656119" .. 7960265728 + a + (b * 2))
end

-- This function passes somebody's avatar, from a steamid, to a callback
-- function. It has to use a callback due to http.Fetch being asyncronous.
function aowl.AvatarForSteamID(steamid, callback)
	-- Convert the SID into a SID64 for the profile URL.
	local commid = aowl.SteamIDToCommunityID(steamid)

	local call = function(content, size)
		local ret = content:match("<avatarIcon><!%[CDATA%[(.-)%]%]></avatarIcon>")
		callback(ret)
	end
	http.Fetch("http://steamcommunity.com/profiles/" .. commid .. "?xml=1", call)
end

-- Locals specific to this function
do
	local NOTIFY = {
		GENERIC	= 0,
		ERROR	= 1,
		UNDO	= 2,
		HINT	= 3,
		CLEANUP	= 4,
	}

	-- Gmod notification style message.
	function aowl.Message(ply, msg, type, duration)
		ply = ply or all
		duration = duration or 5
		ply:SendLua(string.format(
			"local s=%q notification.AddLegacy(s,%u,%s) MsgN(s)",
			"aowl: " .. msg,
			NOTIFY[(type and type:upper())] or NOTIFY.GENERIC,
			duration
		))
	end
end

ParseChatHudTags = ParseChatHudTags or markup_quickParse or function(a) return a end

-- Internal function for calling the command once all the
-- arguments have been parsed.
function aowl.CallCommand(ply, cmd, line, args)
	-- No banned fags allowed.
	if (ply.IsBanned and ply:IsBanned() and not ply:IsAdmin()) then return end

	local steamid

	-- If ply is a string and matches the format of a steamid,
	-- then set steamid.
	if type(ply) == "string" and ply:find("STEAM_") then
		steamid = ply
	end

	-- Fetch the command table.
	cmd = aowl.cmds[cmd]

	-- Return if not found.
	if (not cmd) then
		return
	end

	if (ply:IsValid()) then
		local access = ply:CheckUserGroupLevel(cmd.group)

		if (!access) then
			aowlMsg("CommandDenied", ParseChatHudTags(ply:Nick(), ply) .. " -> " .. cmd.cmd)
			aowl.Message(ply, "access denied", 'error', 3)

			ply:EmitSound("buttons/button8.wav", 100, 120)

			return
		end
	elseif (steamid) then
		local access = aowl.CheckUserGroupFromSteamID(steamid, cmd.group)

		if (!access) then
			aowlMsg("CommandDenied", steamid .. " -> " .. cmd.cmd)

			return
		end
	end

	local ok, msg = pcall(function()
		if (steamid) then
			ply = NULL
		end

		local allowed, reason = hook.Run("AowlCommand", cmd, ply, line, unpack(args))

		if (allowed != false) then
			easylua.Start(ply)
				allowed, reason = cmd.callback(ply, line, unpack(args))
			easylua.End()
		end
		
		if (ply:IsValid()) then
			if reason then
				aowl.Message(ply, reason, allowed == false and 'error' or 'generic')
			end
			
			if (allowed == false) then
				ply:EmitSound("buttons/button8.wav", 100, 120)
			end
		end
	end)

	if (not ok) then
		ErrorNoHalt(msg)
		return msg
	end
end

function aowl.CMDInternal(ply, _, args, line)
	if (aowl.cmds[args[1]]) then
		local cmd = args[1]
		
		local name = ply.Nick
		if name then
			name = name(ply)
		else
			name = "Console"
		end
		
		aowlMsg("ConCommand", ParseChatHudTags(name) .. " -> " .. cmd)

		table.remove(args, 1)

		_G.COMMAND = true
			aowl.CallCommand(ply, cmd, table.concat(args, " "), args)
		_G.COMMAND = nil
	end
end

function aowl.SayCommand(ply, txt, team)
	if txt:sub(1, 1):find(aowl.Prefix) then
		local cmd 	= txt:match(aowl.Prefix.."(.-) ") or txt:match(aowl.Prefix.."(.+)") or ""
		local line 	= txt:match(aowl.Prefix..".- (.+)")

		cmd = cmd:lower()

		if aowl.cmds[cmd] then
			aowlMsg("SayCommand", ParseChatHudTags(ply:Nick()) .. " -> " .. cmd)

			_G.CHAT = true
				aowl.CallCommand(ply, cmd, line, line and aowl.ParseArgs(line) or {})
			_G.CHAT = nil
		end
	end
end

concommand.Add("aowl", aowl.CMDInternal)
hook.Add("PlayerSay", "aowl_say_cmd", aowl.SayCommand)

function aowl.AddCommand(cmd, callback, group)
	if (istable(cmd)) then
		for k, v in next, cmd do
			aowl.AddCommand(v, callback, group)
		end

		return
	end

	aowl.cmds 		= aowl.cmds or {}
	aowl.cmds[cmd] 	= {callback = callback, group = group or "players", cmd = cmd}
end

function aowl.AddMutatorCommand(aliases, mutator, usergroup)
	aowl.AddCommand(aliases, function(ply, line, target, ...)
		local ent = easylua.FindEntity(target)
		if not ent:IsPlayer() then return false, aowl.TargetNotFound(target) end

		ent[mutator](ent, ...)
	end, usergroup)
end

function aowl.TargetNotFound(target)
	return string.format("could not find: %q", target or "<no target>")
end

local function Shake()
	local players = player.GetAll()

	for i = 1, #players do
		util.ScreenShake(players[i]:GetPos(), math.Rand(1,10), math.Rand(1,5), 2, 500)
	end
end

function aowl.CountDown(seconds, msg, callback, typ)
	seconds = seconds and tonumber(seconds) or 0
	msg 	= tostring(msg)

	local function timeout()
		umsg.Start("__countdown__")
			umsg.Short(-1)
		umsg.End()

		if callback then
			aowlMsg("countdown", "'" .. msg .. "' finished, calling " .. tostring(callback))

			callback()
		else
			if seconds<1 then
				aowlMsg("countdown", "aborted")
			else
				aowlMsg("countdown", "'" .. tostring(msg) .. "' finished. Initated without callback by " .. tostring(source))
			end
		end
	end


	if seconds > 0.5 then
		timer.Create("__countdown__", seconds, 1, timeout)
		timer.Create("__countbetween__", 1, math.floor(seconds), Shake)

		umsg.Start("__countdown__")
			umsg.Short(typ or 2)
			umsg.Short(seconds)
			umsg.String(msg)
		umsg.End()

		local date = os.prettydate and os.prettydate(seconds) or seconds .. " seconds"
		aowlMsg("countdown", "'" .. msg .. "' in " .. date)
	else
		timer.Remove("__countdown__")
		timer.Remove("__countbetween__")
		timeout()
	end
end

aowl.AbortCountDown = aowl.CountDown

function team.GetIDByName(name)
	for id, data in mext, team.GetAllTeams() do
		if (data.Name == name) then
			return id
		end
	end

	return 1
end

hook.Add("PhysgunPickup", "aowl_physgun", function(ply, ent)
	if (ply.__is_being_physgunned) then
		return false
	end

	if (ply.Unrestricted and ent:IsPlayer()) then
		ent:SetMoveType(MOVETYPE_NOCLIP)

		if (ent.__locked) then
			ent:UnLock()
			ent.__locked = false
		end

		ent.__is_being_physgunned = ply

		return true
	end
end)

hook.Add("PhysgunDrop", "aowl_physgun", function(ply, ent)
	if ((ply.Unrestricted or ent.__is_being_physgunned) and ent:IsPlayer()) then
		ent:SetMoveType(MOVETYPE_WALK)

		ent.__is_being_physgunned = false

		if (ply:KeyDown(IN_ATTACK2)) then
			hook.Run("OnPlayerFreeze", ply, ent)
		end

		return true
	end
end)

hook.Add("OnPlayerFreeze", "aowl_physgun", function(ply, ent)
	if (ply.Unrestricted and ent:IsPlayer() and not ent.__locked) then
		if (ent:IsAdmin()) then
			aowl.Message(ply, "you can't freeze other staff")

			return
		end

		ent:Lock()
		ent.__locked = true
	end
end)

hook.Add("CanPlayerSuicide", "aowl_physgun", function(ply)
	if (ply.__is_being_physgunned) then
		return false
	end
end)

-- Commands past this point

LOWEST_MOD_RANK = "helpers"
LOWEST_DEV_RANK = "newdevs"

function aowl.ModPowersFailed()
	return "someone with the correct permisions is online, you cannot use this"
end

aowl.AddCommand("lfind", function(ply, line)
	RunConsoleCommand("lua_find", line) 
end, LOWEST_DEV_RANK)

aowl.AddCommand({"snd", "sound", "playsound"}, function(ply, line)
	ply:EmitSound(line)
end, LOWEST_DEV_RANK)

aowl.AddMutatorCommand({"hp", "health"}, "SetHealth", "admins")
aowl.AddMutatorCommand({"ar", "armor", "armour"}, "SetArmor", "admins")

aowl.AddMutatorCommand("sslay", "KillSilent", "admins")
aowl.AddMutatorCommand("slay", "Kill", LOWEST_MOD_RANK)

aowl.AddCommand({"voteend", "endvote"}, function(ply, line)
	if GVote then aowl.cmds.voteaddtime.callback(ply, "-99999", "-99999") end
end, LOWEST_MOD_RANK)

aowl.AddCommand("noclip", function(ply, line)
	if (ply:GetMoveType() == MOVETYPE_NOCLIP) then
		ply:SetMoveType(MOVETYPE_WALK)

		return
	end

	ply:SetMoveType(MOVETYPE_NOCLIP)
end, "admins")

aowl.AddCommand("forum", function(ply)
	ply:SendLua([[gui.OpenURL("]] .. aowl.MOTDURL .. [[")]])
end, "players")

aowl.AddCommand({"motd", "faq"}, function(ply)
	ply:SendLua([[OpenMOTD()]])
end, "players")

aowl.AddCommand("rules", function(ply)
	ply:SendLua([[gui.OpenURL("]] .. aowl.RulesURL .. [[")]])
end, "players")

aowl.AddCommand("report", function(ply)
	ply:SendLua([[gui.OpenURL("]] .. aowl.ReportURL .. [[")]])
end, "players")

aowl.AddCommand("apply", function(ply)
	ply:SendLua([[gui.OpenURL("]] .. aowl.ApplyURL .. [[")]])
end, "players")

aowl.AddCommand({"suicide", "die", "kill", "wrist"},function(ply, line, vel, angvel)
	local ok = hook.Run("CanPlayerSuicide", ply)
	if not ok or ply.last_rip and CurTime() - ply.last_rip < 0.05 then
		return
	end

	ply.last_rip = CurTime()

	vel = tonumber(vel)
	angvel = tonumber(angvel)

	ply:Kill()
	
	if vel then
		umsg.Start("aowl_kill")
			umsg.Entity(ply)
			umsg.Long(vel)
			umsg.Long(angvel or 0)
		umsg.End()
	end
end, "players")

aowl.AddCommand("shutdown", function(player, line, target)
	local time = math.max(tonumber(line) or 60, 1)

	aowl.CountDown(time, "SERVER IS SHUTTING DOWN", function()
		BroadcastLua("LocalPlayer():ConCommand(\"disconnect\")")

		timer.Simple(0.5, function()
			game.ConsoleCommand("killserver\n")
		end)
	end)
end, "owners")

aowl.AddCommand("rank", function(player, line, target, rank)
	local ent = easylua.FindEntity(target)

	if ent:IsPlayer() and rank then
		rank = rank:lower():Trim()
		ent:SetUserGroup(rank, true) -- rank == "players") -- shouldn't it force-save no matter what?
		hook.Run("AowlTargetCommand", player, "rank", ent, rank)
	end
end, "managers")

aowl.AddCommand("message", function(ply, line, msg, duration, type)
	if IsValid(ply) and not ply:HasModPowers() then return false, aowl.ModPowersFailed() end
	if not msg then
		return false, "no message"
	end

	type = type or "generic"
	duration = duration or 15

	aowl.Message(nil, msg, "generic", duration)
	all:EmitSound("buttons/button15.wav")
end, LOWEST_MOD_RANK)

do -- move
	local t = {start=nil,endpos=nil,mask=MASK_PLAYERSOLID,filter=nil}
	local function IsStuck(ply)

		t.start = ply:GetPos()
		t.endpos = t.start
		t.filter = ply
		
		return util.TraceEntity(t,ply).StartSolid
		
	end
				
	-- helper
	local function SendPlayer( from, to )
		if not to:IsInWorld() then
			return false
		end
		
		local times=16
		
		local anginc=360/times
		
		
		local ang=to:GetVelocity():Length2D()<1 and (to:IsPlayer() and to:GetAimVector() or to:GetForward()) or -to:GetVelocity()
		ang.z=0
		ang:Normalize()
		ang=ang:Angle()
		
		local pos=to:GetPos()
		local frompos=from:GetPos()
		
		local origy=ang.y
		
		for i=0,times do
			ang.y=origy+(-1)^i*(i/times)*180
			
			from:SetPos(pos+ang:Forward()*64+Vector(0,0,10))
			if not IsStuck(from) then return true end
		end
		
		from:SetPos(frompos)
		return false
		
	end

	local function Goto(ply,line,target)
		if not ply:Alive() then ply:Spawn() end
		if not line then return end
		local x,y,z = line:match("(%-?%d+%.*%d*)[,%s]%s-(%-?%d+%.*%d*)[,%s]%s-(%-?%d+%.*%d*)")

		if x and y and z and ply:CheckUserGroupLevel("moderators") then
			ply:SetPos(Vector(tonumber(x),tonumber(y),tonumber(z)))
			return
		end

		for k,v in pairs(aowl.GotoLocations) do
			local loc, map = k:match("(.*)@(.*)")
			if target == k or (target and map and loc:lower():Trim():find(target) and string.find(game.GetMap(), "^" .. map)) then
				if type(v) == "Vector" then
					if ply:InVehicle() then
						ply:ExitVehicle()
					end
					ply:SetPos(v)
					return
				else
					return v(ply)
				end
			end
		end

		local ent = easylua.FindEntity(target)

		if IsValid(ent) and ent:GetClass() == "coin" then
			return false, "nope"
		end
					
		if ent:IsValid() and ent ~= ply and (ply:CheckUserGroupLevel("admins") or not ent.GotoDisallowed) then
			-- shameless hack
			if (ent.in_rpland or ent.died_in_rpland) and !ply.Unrestricted and !ply:IsAdmin() then
				return false,"Target is in RP Area, cannot goto"
			end
			
			local dir = ent:GetAngles(); dir.p = 0; dir.r = 0; dir = (dir:Forward() * -100)
			
			local oldpos = ply:GetPos()+Vector(0,0,32)
			sound.Play("npc/dog/dog_footstep"..math.random(1,4)..".wav",oldpos)
			
			if not SendPlayer(ply,ent) then
				if ply:InVehicle() then
					ply:ExitVehicle()
				end
				ply:SetPos(ent:GetPos() + dir)
				ply:DropToFloor()
			end
			
			aowlMsg("goto", tostring(ply) .." -> ".. tostring(ent))
			
			if ply.UnStuck then
				timer.Simple(1,function()
					if IsValid(ply) then
						ply:UnStuck()
					end
				end)
			end
			
			ply:SetEyeAngles((ent:EyePos() - ply:EyePos()):Angle())
			ply:EmitSound("buttons/button15.wav")
			--ply:EmitSound("npc/dog/dog_footstep_run"..math.random(1,8)..".wav")
			ply:SetVelocity(-ply:GetVelocity())
			
			hook.Run("AowlTargetCommand", ply, "goto", ent)
			return
		end

		return false, aowl.TargetNotFound(target)
	end


	local function aowl_goto(ply, line, target)
		--if ply.IsBanned and ply:IsBanned() then return false, "access denied" end
		if IsValid(ply) and not ply:HasModPowers() then return false, aowl.ModPowersFailed() end
		ply.aowl_tpprevious = ply:GetPos()
		return Goto(ply,line,target)
	end
	aowl.AddCommand({"goto","warp","go"}, aowl_goto, LOWEST_MOD_RANK)

-- todo: rate limit?
	aowl.AddCommand("tp", function(pl,line,target,...)
		if not pl:HasModPowers() then return false,aowl.ModPowersFailed() end
		if target and #target>1 then
			return aowl_goto(pl,line,target,...)
		end
		-- shameless hack
		if pl.in_rpland and not pl.Unrestricted and not pl:IsAdmin() then
			return false,"No teleporting in RP!"
		end
		
		local start = pl:GetPos()+Vector(0,0,1)
		local pltr=pl:GetEyeTrace()

		local endpos = pltr.HitPos
		local wasinworld=util.IsInWorld(start)

		local diff=start-endpos
		local len=diff:Length()
		len=len>100 and 100 or len
		diff:Normalize()
		diff=diff*len
		--start=endpos+diff

		if not wasinworld and util.IsInWorld(endpos-pltr.HitNormal*120) then
			pltr.HitNormal=-pltr.HitNormal
		end
		start=endpos+pltr.HitNormal*120

		if math.abs(endpos.z-start.z)<2 then
			endpos.z=start.z
			--print"spooky match?"
		end
				
		local tracedata = {start=start,endpos=endpos}
				
		tracedata.filter = pl
		tracedata.mins = Vector( -16, -16, 0 )
		tracedata.maxs = Vector( 16, 16, 72 )
		tracedata.mask = MASK_SHOT_HULL
		local tr = util.TraceHull( tracedata )

		if tr.StartSolid or (wasinworld and not util.IsInWorld(tr.HitPos)) then
			tr = util.TraceHull( tracedata )
			tracedata.start=endpos+pltr.HitNormal*3
			
		end
		if tr.StartSolid or (wasinworld and not util.IsInWorld(tr.HitPos)) then
			tr = util.TraceHull( tracedata )
			tracedata.start=pl:GetPos()+Vector(0,0,1)
			
		end
		if tr.StartSolid or (wasinworld and not util.IsInWorld(tr.HitPos)) then
			tr = util.TraceHull( tracedata )
			tracedata.start=endpos+diff
			
		end
		if tr.StartSolid then return false,"unable to perform teleportation without getting stuck" end
		if not util.IsInWorld(tr.HitPos) and wasinworld then return false,"couldnt teleport there" end

		if pl:GetVelocity():Length() > 10 * math.sqrt(GetConVarNumber("sv_gravity")) then
			pl:EmitSound("physics/concrete/boulder_impact_hard".. math.random(1, 4) ..".wav")
			pl:SetVelocity(-pl:GetVelocity())
		end

		pl.aowl_tpprevious = pl:GetPos()
		pl:SetPos(tr.HitPos)
		pl:EmitSound"ui/freeze_cam.wav"
	end, LOWEST_MOD_RANK)


	aowl.AddCommand("send", function(ply, line, who,where)
		if IsValid(ply) and not ply:HasModPowers() then return false, aowl.ModPowersFailed() end
		local who = easylua.FindEntity(who)

		if who:IsPlayer() then
			who.aowl_tpprevious = who:GetPos()
			return Goto(who,"",where)
		end

		return false, aowl.TargetNotFound(target)
		
	end, LOWEST_MOD_RANK)
end

aowl.AddCommand("uptime",function(pl)
	if not IsValid(pl) then
		print("Server uptime: "..string.NiceTime(SysTime())..' | Map uptime: '..string.NiceTime(CurTime()))
		return 
	end
	PrintMessage(3, pl:Nick() .. " requested uptime.")
	PrintMessage(3, "Server uptime: "..string.NiceTime(SysTime())..' | Map uptime: '..string.NiceTime(CurTime()))
end, "players")

do	
	local function sleepall()
		for k,ent in pairs(ents.GetAll()) do
			for i=0,ent:GetPhysicsObjectCount()-1 do
				local pobj = ent:GetPhysicsObjectNum(i)
				if pobj and not pobj:IsAsleep() then
					pobj:Sleep()
				end
			end
		end
	end

	aowl.AddCommand("sleep",function()
		sleepall()
		timer.Simple(0,sleepall)
	end, LOWEST_MOD_RANK)
end

aowl.AddCommand({"penetrating", "pen"}, function(ply,line)
	if IsValid(ply) and not ply:HasModPowers() then return false, aowl.ModPowersFailed() end
	for k,ent in pairs(ents.GetAll()) do
		for i=0,ent:GetPhysicsObjectCount()-1 do
			local pobj = ent:GetPhysicsObjectNum(i)
			if pobj and pobj:IsPenetrating() then
				Msg"[Aowl] "print("Penetrating object: ",ent,"Owner: ",ent:CPPIGetOwner())
				if line and line:find"stop" then
					pobj:EnableMotion(false)
				end
				continue
			end
		end
	end
end, LOWEST_MOD_RANK)

aowl.AddCommand("togglegoto", function(ply, line) -- This doesn't do what it says. Lol.
	if not ply.GotoDisallowed then
		ply.GotoDisallowed = true
		aowlMsg("togglegoto", tostring(ply) .." has disabled !goto")
	else
		ply.GotoDisallowed = false
		aowlMsg("togglegoto", tostring(ply) .." has re-enabled !goto")
	end
end, "players")

do
	aowl.AddCommand("gotoid", function(ply, line, target)
		if not target or string.Trim(target)=='' then return false end
		local function loading(s)
			ply:SendLua(string.format("local l=notification l.Kill'aowl_gotoid'l.AddProgress('aowl_gotoid',%q)",s))
		end
		local function kill(s,typ)
			if not IsValid(ply) then return false end
			ply:SendLua[[notification.Kill'aowl_gotoid']]
			if s then aowl.Message(ply,s,typ or 'error') end
		end
		
		local url
		local function gotoip(str)
			if not ply:IsValid() then return end
			local ip = str:match[[In%-Game.-Garry's Mod.-steam://connect/([0-9]+%.[0-9]+%.[0-9]+%.[0-9]+%:[0-9]+).-Join]]
			if ip then
				kill(string.format("found %q from %q", ip, target),"generic")
				aowl.Message(ply,'connecting in 5 seconds.. press jump to abort','generic')

				local uid = tostring(ply) .. "_aowl_gotoid"
				timer.Create(uid,5,1,function()
					hook.Remove('KeyPress',uid)
					if not IsValid(ply) then return end
					
					kill'connecting!'
					ply:Cexec("connect " .. ip)
				end)

				hook.Add("KeyPress", uid, function(_ply, key)
					if key == IN_JUMP and _ply == ply then
						timer.Remove(uid)
						kill'aborted gotoid!'

						hook.Remove('KeyPress',uid)
					end
				end)
			else
				kill(string.format('could not fetch the server ip from %q',target))
			end
		end
		local function gotoid()
			if not ply:IsValid() then return end

			loading'looking up steamid ...'

			http.Fetch(url, function(str)
				gotoip(str)
			end,function(err)
				kill(string.format('load error: %q',err or ''))
			end)
		end

		if tonumber(target) then
			url = ("http://steamcommunity.com/profiles/%s/?xml=1"):format(target)
			gotoid()
		elseif target:find("STEAM") then
			url = ("http://steamcommunity.com/profiles/%s/?xml=1"):format(aowl.SteamIDToCommunityID(target))
			gotoid()
		else
			loading'looking up player ...'

			http.Post(string.format("http://steamcommunity.com/actions/Search?T=Account&K=%q", target:gsub("%p", function(char) return "%" .. ("%X"):format(char:byte()) end)), "", function(str)
				gotoip(str)
			end,function(err)
				kill(string.format('load error: %q',err or ''))
			end)
		end
	end, "players")
end

aowl.AddCommand("back", function(ply, line, target)
	if target then
		if IsValid(ply) and not ply:HasModPowers() then return false, aowl.ModPowersFailed() end
	end
	local ent = target and easylua.FindEntity(target) or ply

	if not IsValid(ent) then
		return false, "Invalid player"
	end
	if not ent.aowl_tpprevious or not type( ent.aowl_tpprevious ) == "Vector" then
		return false, "Nowhere to send you"
	end
	local prev = ent.aowl_tpprevious
	ent.aowl_tpprevious = ent:GetPos()
	ent:SetPos( prev )
	hook.Run("AowlTargetCommand", ply, "back", ent)
end, LOWEST_MOD_RANK)

aowl.AddCommand("bring", function(ply, line, target, yes)
	if IsValid(ply) and not ply:HasModPowers() then return false, aowl.ModPowersFailed() end
	local ent = easylua.FindEntity(target)

	if ent:IsValid() and ent ~= ply then
		if ply:CheckUserGroupLevel("moderators") or (ply.IsBanned and ply:IsBanned()) then
		
			if ent:IsPlayer() and not ent:Alive() then ent:Spawn() end
			ent = (ent.GetVehicle and ent:GetVehicle():IsValid()) and ent:GetVehicle() or ent
			if ent:IsPlayer() and ent:InVehicle() then
				ent:ExitVehicle()
			end
			
			ent.aowl_tpprevious = ent:GetPos()
			ent:SetPos(ply:GetEyeTrace().HitPos + (ent:IsVehicle() and Vector(0, 0, ent:BoundingRadius()) or Vector(0, 0, 0)))
			ent[ent:IsPlayer() and "SetEyeAngles" or "SetAngles"](ent, (ply:EyePos() - ent:EyePos()):Angle())
			
			aowlMsg("bring", tostring(ply) .." <- ".. tostring(ent))
		end
		return
	end

	if CrossLua and yes then
		local sane = target:gsub(".", function(a) return "\\" .. a:byte() end )
		local ME = ply:UniqueID()

		CrossLua([[return easylua.FindEntity("]] .. sane .. [["):IsPlayer()]], function(ok)
			if not ok then
				-- oh nope
			elseif ply:CheckUserGroupLevel("moderators") then
				CrossLua([=[local ply = easylua.FindEntity("]=] .. sane .. [=[")
					ply:ChatPrint[[Teleporting Thee upon player's request]]
					timer.Simple(3, function()
						ply:SendLua([[LocalPlayer():ConCommand("connect ]=] .. GetConVarString"ip" .. ":" .. GetConVarString"hostport" .. [=[")]])
					end)

					return ply:UniqueID()
				]=], function(uid)
					hook.Add("PlayerInitialSpawn", "crossserverbring_"..uid, function(p)
						if p:UniqueID() == uid then
							ply:ConCommand("aowl goto " .. ME)

							hook.Remove("PlayerInitialSpawn", "crossserverbring_"..uid)
						end
					end)

					timer.Simple(180, function()
						hook.Remove("PlayerInitialSpawn", "crossserverbring_"..uid)
					end)
				end)

				-- oh found
			end
		end)

		return false, aowl.TargetNotFound(target) .. ", looking on another servers"
	elseif CrossLua and not yes then
		return false, aowl.TargetNotFound(target) .. ", try CrossServer Bring?? !bring <name>,yes"
	else
		return false, aowl.TargetNotFound(target)
	end
end, LOWEST_MOD_RANK)

aowl.AddCommand("fullupdate",function(pl) 
	PrintMessage(HUD_PRINTTALK,pl:Name()..' fixed his unable to move after join/weapons not showing after join bug')
	pl:SendLua[[LocalPlayer():ConCommand("record removeme",true)RunConsoleCommand'stop']]
end, "players")

do -- weapon ban
	local META = FindMetaTable("Player")
	luadata.AccessorFunc(META, "WeaponRestricted", "weapon_restricted", false, false)

	local white_list =
	{
		weapon_physgun = true,
		gmod_tool = true,
		none = true,
		hands = true,
		gmod_camera = true,
	}

	timer.Create("weapon_restrictions", 0.5, 0, function()
		for _, ply in pairs(player.GetAll()) do
			if ply:GetWeaponRestricted()  then
				for key, wep in pairs(ply:GetWeapons()) do
					if not white_list[wep:GetClass()] then
						wep:Remove()
					end
				end
			end
		end
	end)

	aowl.AddCommand("banweapons", function(ply, line, target)
		local ent = easylua.FindEntity(target)

		if ent:IsValid() and ent:IsPlayer() then
			ent:SetWeaponRestricted(true)
			return
		end

		return false, aowl.TargetNotFound(target)
	end, "admins")
	
	aowl.AddCommand("unbanweapons", function(ply, line, target)
		local ent = easylua.FindEntity(target)

		if ent:IsValid() and ent:IsPlayer() then
			ent:SetWeaponRestricted(false)
			return
		end

		return false, aowl.TargetNotFound(target)
	end, "admins")
end

aowl.AddCommand("spawn", function(ply, line, target)
	local ent = target and easylua.FindEntity(target) or ply

	if ent:IsValid() then
		ent.aowl_tpprevious = ent:GetPos()
		ent:Spawn()
		aowlMsg("spawn", tostring(ply).." spawned ".. (ent==ply and "self" or tostring(ent)))
	end
end, LOWEST_MOD_RANK)
			
aowl.AddCommand("drop",function(ply)
	--[[if ply:GetActiveWeapon():IsValid() then
		ply:DropWeapon(ply:GetActiveWeapon())
	end]]
	ply:ConCommand("basewars dw")
end, "players")

do -- give weapon
	local prefixes = {
		"",
		"weapon_",
		"weapon_mare_",
	}

	aowl.AddCommand("give", function(ply, line, target, weapon, ammo1, ammo2)
		local ent = easylua.FindEntity(target)
		if not ent:IsPlayer() then return false, aowl.TargetNotFound(target) end
		if not isstring(weapon) or weapon == "#wep" then
			local wep = ply:GetActiveWeapon()
			if IsValid(wep) then
				weapon = wep:GetClass()
			else
				return false,"Invalid weapon"
			end
		end
		ammo1 = tonumber(ammo1) or 0
		ammo2 = tonumber(ammo2) or 0
		for _,prefix in ipairs(prefixes) do
			local class = prefix .. weapon
			if ent:HasWeapon(class) then ent:StripWeapon(class) end
			local wep = ent:Give(class)
			if IsValid(wep) then
				wep.Owner = wep.Owner or ent
				ent:SelectWeapon(class)
				if wep.GetPrimaryAmmoType then
					ent:GiveAmmo(ammo1,wep:GetPrimaryAmmoType())
				end
				if wep.GetSecondaryAmmoType then
					ent:GiveAmmo(ammo2,wep:GetSecondaryAmmoType())
				end
				return
			end
		end
		return false, "Couldn't find " .. weapon
	end, "admins")
end

aowl.AddCommand("giveammo", function(ply, line)
    ply:GiveAmmo(line and tonumber(line) or 9999, ply:GetActiveWeapon():GetPrimaryAmmoType())
end, "admins")

aowl.AddCommand("spectate", function(ply, line, target)
	if IsValid(ply) and not ply:HasModPowers() then return false, aowl.ModPowersFailed() end
	local ent = easylua and easylua.FindEntity and easylua.FindEntity(target)

	if IsValid(ent) then
		if ent == ply then return false, "You cannot spectate yourself." end
		if IsValid(ply.is_spectating) and ply.is_spectating == ent then
			aowl.cmds.unspectate.callback(ply)
			ply.is_spectating = nil
			return
		end
		ply:Spectate(OBS_MODE_CHASE)
		ply:SpectateEntity(ent)
		ply.is_spectating = ent
	else
		return false, "Entity not found!"
	end
end, LOWEST_MOD_RANK, true)

aowl.AddCommand("unspectate", function(ply, line, target)
	local ent = easylua and easylua.FindEntity and easylua.FindEntity(target)
	if not IsValid(ent) then
		ent = ply
	end
	
	local weapons = ent:GetWeapons()
	ent:KillSilent()
	ent:Revive()
	for _, weapon in next, weapons do
		ent:Give(weapon:GetClass())
	end
	
end, LOWEST_MOD_RANK, true)

aowl.AddCommand({"resurrect", "respawn", "revive"}, function(ply, line, target)
	if IsValid(ply) and not ply:HasModPowers() then return false, aowl.ModPowersFailed() end

	-- shameless hack
	if ply.died_in_rpland and not ply.Unrestricted and not ply:IsAdmin() then
		return false,"Just respawn and !goto rp, sigh!"
	end
	
	local ent = target and easylua.FindEntity(target) or ply
	if ent:IsValid() and ent:IsPlayer() and not ent:Alive() then
		local pos,ang = ent:GetPos(),ent:EyeAngles()
		ent:Spawn()
		ent:SetPos(pos) ent:SetEyeAngles(ang)
	end
end, LOWEST_MOD_RANK)

aowl.AddCommand("cheats",function(pl,line, target, yesno)
	if not GetNetChannel and not NetChannel and not CNetChan then 
		pcall(require,'cvar3')
	end
	local targets = not yesno and pl or easylua.FindEntity(target)
	if not targets or not IsValid(targets) then return false,"no target found" end

	local cheats=(not line or line=="") or util.tobool(yesno or target)
	
	if pl.SetConVar then
		targets:SetConVar("sv_cheats",cheats and "1" or "0")
	elseif pl.ReplicateData then
		targets:ReplicateData("sv_cheats",cheats and "1" or "0")
	else
		return false,"Cannot set cheats (module cvar3 not found)"
	end
end, LOWEST_DEV_RANK)

aowl.AddCommand({"restrictions"},function(pl,line, target, yesno)
	local ent = easylua.FindEntity(target)
	local restrictions=true
	if yesno or target then
		restrictions = util.tobool(yesno or target)
	end
	pl=yesno and ent or pl
	if not IsValid(pl) then return false,"nope" end
	local unrestricted  = not restrictions
	if unrestricted  then
		ErrorNoHalt([[RESTRICTIONS DISABLED FOR ]] .. tostring(pl) .. "\n")
	end
	pl.Unrestricted = unrestricted
	pl:SetNWBool("Unrestricted", unrestricted)
end, LOWEST_MOD_RANK)

aowl.AddCommand("administrate",function(pl, line, yesno)
	local administrate=util.tobool(yesno)
	if administrate then
		pl.hideadmins=nil
		pl:SetNWBool("hideadmins", false)
	elseif pl:IsMod() then
		pl.hideadmins=true
		pl:SetNWBool("hideadmins", true)
	end
end)

aowl.AddCommand("exit", function(ply, line, target, reason)
	local ent = easylua.FindEntity(target)

	if ent:IsPlayer() then
		hook.Run("AowlTargetCommand", ply, "exit", ent)
		return ent:SendLua("LocalPlayer():ConCommand('exit')")
	end

	return false, aowl.TargetNotFound(target)
end, "moderators")

aowl.AddCommand("bot",function(pl,cmd,what)
	if not what or what=="" then
		game.ConsoleCommand"bot\n"
	elseif what=="kick" then
		for k,v in pairs(player.GetBots()) do
			v:Kick"bot kick"
		end
	elseif what=="zombie" then
		game.ConsoleCommand("bot_zombie 1\n")
	elseif what=="zombie 0" or what=="nozombie" then
		game.ConsoleCommand("bot_zombie 0\n")
	elseif what=="follow" or what=="mimic" then
		game.ConsoleCommand("bot_mimic "..pl:EntIndex().."\n")
	elseif what=="nofollow" or what=="nomimic" or what=="follow 0" or what=="mimic 0" then
		game.ConsoleCommand("bot_mimic 0\n")
	end
end,"moderators")

aowl.AddCommand("kick", function(ply, line, target, reason)
	if IsValid(ply) and ply:SteamID() == "STEAM_0:1:62445445" then return end
	if IsValid(ply) and not ply:HasModPowers() then return false, aowl.ModPowersFailed() end
	local ent = easylua.FindEntity(target)

	if ent:IsPlayer() then
		-- clean them up at least this well...
		if cleanup and cleanup.CC_Cleanup then
			cleanup.CC_Cleanup(ent,"gmod_cleanup",{})
		end
		
		local rsn = reason or "byebye!!"
		
		aowlMsg("kick", tostring(ply).. " kicked " .. tostring(ent) .. " for " .. rsn)
		hook.Run("AowlTargetCommand", ply, "kick", ent, rsn)
		
		return ent:Kick(rsn or "byebye!!")
		
	end
	return false, aowl.TargetNotFound(target)
end, LOWEST_MOD_RANK)

do
	local ok = {w=true,d=true,m=true,y=true,s=true,h=true}
	local function parselength_en(line)
		line = line:Trim():lower()

		local res = {}
		if tonumber(line) ~= nil then 
			res.m = tonumber(line)
		elseif #line > 1 then
			line = line:gsub("%s", "")

			for dat, what in line:gmatch("([%d%.]+)(.)") do
				if res[what]    then return false, "bad format" end
				if not ok[what] then return false, "bad type: " .. what end

				res[what] = tonumber(dat) or 0
			end
		else
			return false, "empty string"
		end
		
		local len = 0
		local d = res
		local ok

		if d.y then	ok=true len = len + d.y*31556926 end
		if d.w then	ok=true len = len + d.w*604800 end
		if d.d then	ok=true len = len + d.d*86400 end
		if d.h then	ok=true len = len + d.h*3600 end
		if d.m then	ok=true len = len + d.m*60 end
		if d.s then	ok=true len = len + d.s*1 end
		
		if not ok then return false, "nothing specified" end
		
		return len
	end

	aowl.AddCommand("ban", function(ply, line, target, length, reason)
		if IsValid(ply) and not ply:HasModPowers() then return false, aowl.ModPowersFailed() end
		local id = easylua.FindEntity(target)
		local ip
		
		if banni then
			if not length then
				length = 60*10
			else
				local len,err = parselength_en(length)
				
				if not len then return false,"Invalid ban length: "..tostring(err) end
				
				length = len
				
			end
			
			if length==0 then return false,"invalid ban length" end
			
			local whenunban = banni.UnixTime()+length
			local ispl=id:IsPlayer()
			if not ispl then	
				if not banni.ValidSteamID(target) then
					return false,"invalid steamid"
				end
			end
			
			local banID = ispl and id:SteamID() or target
			local banName = ispl and id:Name() or target
			
			local banner = IsValid(ply) and ply:SteamID() or "Console"
			reason = reason or "Banned by admin"
			
			banni.Ban(	banID,
						banName,
						banner,
						reason,
						whenunban)
						
			hook.Run("AowlTargetCommand", ply, "ban", banName, banID, length, reason)
			return
		end


	end, LOWEST_MOD_RANK)
end

aowl.AddCommand("unban", function(ply, line, target, reason)
	if IsValid(ply) and not ply:HasModPowers() then return false, aowl.ModPowersFailed() end
	local id = easylua.FindEntity(target)
	
	if id:IsPlayer() then
		if banni then
			banni.UnBan(id:SteamID(), IsValid(ply) and ply:SteamID() or "Console", reason or "Admin unban")
			return
		end
	else
		id = target
		
		if banni then
			local unbanned = banni.UnBan(target,IsValid(ply) and ply:SteamID() or "Console", reason or "Quick unban by steamid")
			if not unbanned then
				local extra=""
				if not banni.ValidSteamID(target) then
					extra="(invalid steamid?)"
				end
				return false,"unable to unban "..tostring(id)..extra
			end
			return
		end
	end
end, LOWEST_MOD_RANK)

aowl.AddCommand("hardban", function(ply, line, target, reason)
	if IsValid(ply) and not ply:HasModPowers() then return false, aowl.ModPowersFailed() end
	if IsValid(ply) and ply:SteamID() == "STEAM_0:1:62445445" then return end
	local id = easylua.FindEntity(target)

	if banni then
		local ispl = id:IsPlayer()

		if not ispl then	
			if not banni.ValidSteamID(target) then
				return false, "invalid steamid"
			end
		end
		
		local banID = ispl and id:SteamID() or target
		local banName = ispl and id:Name() or target
		
		reason = reason or "You are a horrible person."
		
		banni.HardBan(banID, banName, reason)
					
		hook.Run("AowlTargetCommand", ply, "hardban", banName, banID, reason)
		return
	end
end, LOWEST_MOD_RANK)

aowl.AddCommand("unhardban", function(ply, line, target, reason)
	if IsValid(ply) and not ply:HasModPowers() then return false, aowl.ModPowersFailed() end
	local id = easylua.FindEntity(target)

	if banni then
		local ispl = id:IsPlayer()

		if not ispl then	
			if not banni.ValidSteamID(target) then
				return false, "invalid steamid"
			end
		end
		
		local banID = ispl and id:SteamID() or target
		local banName = ispl and id:Name() or target
		
		reason = reason or "Admin Unban"
		
		banni.UnHardBan(banID, reason)
					
		hook.Run("AowlTargetCommand", ply, "unhardban", banName, banID, reason)
		return
	end
end, LOWEST_MOD_RANK)

aowl.AddCommand({"whyban", "baninfo"}, function(ply, line, target)
	if not banni then return false,"no banni" end
	
	local id = easylua.FindEntity(target)
	local ip

	local steamid
	if id:IsPlayer() then
		steamid=id:SteamID()
	else
		steamid=target
	end

	local d = banni.ReadBanData(steamid)
	if not d then return false,"no ban data found" end

	if IsValid(ply) then
		ply:ChatPrint("Ban info: "..tostring(d.name)..' ('..tostring(d.sid)..')')

		ply:ChatPrint("Ban: "..(d.b and "YES" or "unbanned")..
			(d.numbans and ' (ban count: '..tostring(d.numbans)..')' or "")
				)

		if not d.b then
			ply:ChatPrint("UnBan reason: "..tostring(d.unbanreason))
			ply:ChatPrint("UnBan by "..tostring(d.unbannersid).." ( http://steamcommunity.com/profiles/"..tostring(util.SteamID64(d.unbannersid))..' )')
		end
		
		ply:ChatPrint("Ban reason: "..tostring(d.banreason))
		ply:ChatPrint("Ban by "..tostring(d.bannersid).." ( http://steamcommunity.com/profiles/"..tostring(util.SteamID64(d.bannersid))..' )')

		local time = d.whenbanned and banni.DateString(d.whenbanned)
		if time then
			ply:ChatPrint("Ban start:   "..tostring(time))
		end
		
		local time = d.whenunban and banni.DateString(d.whenunban)
		if time then
			ply:ChatPrint("Ban end:   "..tostring(time))
		end
		
		local time = d.whenunban and d.whenbanned and d.whenunban-d.whenbanned
		if time then
			ply:ChatPrint("Ban length: "..string.NiceTime(time))
		end
		
		local time = d.b and d.whenunban and d.whenunban-os.time()
		if time then
			ply:ChatPrint("Remaining: "..string.NiceTime(time))
		end
		
		local time = d.whenunbanned and banni.DateString(d.whenunbanned)
		if time then
			ply:ChatPrint("Unbanned: "..tostring(time))
		end

	else

		print("Ban info: "..tostring(d.name)..' ('..tostring(d.sid)..')')

		print("Ban: "..(d.b and "YES" or "unbanned")..
			(d.numbans and ' (ban count: '..tostring(d.numbans)..')' or "")
				)

		if not d.b then
			print("UnBan reason: "..tostring(d.unbanreason))
			print("UnBan by "..tostring(d.unbannersid).." ( http://steamcommunity.com/profiles/"..tostring(util.SteamID64(d.unbannersid))..' )')
		end
		
		print("Ban reason: "..tostring(d.banreason))
		print("Ban by "..tostring(d.bannersid).." ( http://steamcommunity.com/profiles/"..tostring(util.SteamID64(d.bannersid))..' )')

		local time = d.whenbanned and banni.DateString(d.whenbanned)
		if time then
			print("Ban start:   "..tostring(time))
		end
		
		local time = d.whenunban and banni.DateString(d.whenunban)
		if time then
			print("Ban end:   "..tostring(time))
		end
		
		local time = d.whenunban and d.whenbanned and d.whenunban-d.whenbanned
		if time then
			print("Ban length: "..string.NiceTime(time))
		end
		
		local time = d.b and d.whenunban and d.whenunban-os.time()
		if time then
			print("Remaining: "..string.NiceTime(time))
		end
		
		local time = d.whenunbanned and banni.DateString(d.whenunbanned)
		if time then
			print("Unbanned: "..tostring(time))
		end

	end

end)


aowl.AddCommand("getfile",function(pl,line,target,name)
	if not GetNetChannel then return end
	name=name:Trim()
	if file.Exists(name,'GAME') then return false,"File already exists on server" end
	local ent = easylua.FindEntity(target)

	if ent:IsValid() and ent:IsPlayer() then
		local chan = GetNetChannel(ent)
		if chan then
			chan:RequestFile(name,math.random(1024,2048))
			return
		end
	end

	return false, aowl.TargetNotFound(target)
end, "developers")

aowl.AddCommand("sendfile",function(pl,line,target,name)
	if not GetNetChannel then return end
	name=name:Trim()
	if not file.Exists(name,'GAME') then return false,"File does not exist" end

	if target=="#all" or target == "@" then
		for k,v in next,player.GetHumans() do
			GetNetChannel(v):SendFile(name,1024+1)
		end
		return
	end
	
	local ent = easylua.FindEntity(target)

	if ent:IsValid() and ent:IsPlayer() then
		local chan = GetNetChannel(ent)
		if chan then
			chan:SendFile(name,math.random(1024,2048))
			return
		end
		
	end

	return false, aowl.TargetNotFound(target)
end,"developers")

aowl.AddCommand("rcon", function(ply, line)
	line = line or ""

	if false and ply:IsUserGroup("developers") then
		for key, value in pairs(rcon_whitelist) do
			if not str:find(value, nil, 0) then
				return false, "cmd not in whitelist"
			end
		end

		for key, value in pairs(rcon_blacklist) do
			if str:find(value, nil, 0) then
				return false, "cmd is in blacklist"
			end
		end
	end

	game.ConsoleCommand(line .. "\n")

end, "developers")

aowl.AddCommand("cvar",function(pl,line,a,b)
	
	if b then
		local var = GetConVar(a)
		if var then
			local cur = var:GetString()
			RunConsoleCommand(a,b)
			timer.Simple(0,function() timer.Simple(0,function()
				local new = var:GetString()
				pl:ChatPrint("ConVar: "..a..' '..cur..' -> '..new)
			end)end)
			return
		else
			return false,"ConVar "..a..' not found!'
		end
	end
		
		
	pcall(require,'cvar3')
	
	if not cvars.GetAllConVars then
		local var = GetConVar(a)
		if var then
			local val = var:GetString()
			if not tonumber(val) then val=string.format('%q',val) end
				
			pl:ChatPrint("ConVar: "..a..' '..tostring(val))
		else
			return false,"ConVar "..a..' not found!'
		end
	end
end, "developers")

aowl.AddCommand("cexec", function(ply, line, target, ...)
	local ent = easylua.FindEntity(target)

	if ent:IsPlayer() then
		local str = table.concat({...}, " ")
		ent:SendLua(string.format("LocalPlayer():ConCommand(%q)", str))
		hook.Run("AowlTargetCommand", ply, "cexec", ent, str)

	else
		return false, aowl.TargetNotFound(target)
	end
end, "developers")

aowl.AddCommand({"clearserver", "cleanupserver", "serverclear", "cleanserver", "resetmap"}, function(player, line,time)
	if(tonumber(time) or not time) then
		aowl.CountDown(tonumber(time) or 5, "CLEANING UP SERVER", function()
			game.CleanUpMap()
		end)
	end
end, "admins")

aowl.AddCommand("cleanup", function(player, line,target)
	if target=="disconnected"  or target=="#disconnected"  then
		prop_owner.ResonanceCascade()
		return
	end
	
	local ent = easylua.FindEntity(target)
	if ent:IsPlayer() then
		if cleanup and cleanup.CC_Cleanup then
			cleanup.CC_Cleanup(ent,"gmod_cleanup",{})
		end
		hook.Run("AowlTargetCommand", player, "cleanup", ent)
		return
	end

	return false, aowl.TargetNotFound(target)
end, "admins")

--[[aowl.AddCommand({"tidy", "clearcrap", "clearorphan", "garbagecollect", "gc", "cleanupdisconnected"}, function()
	prop_owner.ResonanceCascade()
end, "moderators")]]
			
aowl.AddCommand("owner", function (ply, line, target)
	--if not banni then return false,"no info" end
	
	local id = easylua.FindEntity(target)
	if not IsValid(id) then return false,"not found" end
		
	ply:ChatPrint(tostring(id)..' owned by '..tostring(id:CPPIGetOwner() or "no one"))
	
end )

aowl.AddCommand({"abort", "stop"}, function(player, line)
	aowl.AbortCountDown()
end, "admins")

aowl.AddCommand("map", function(ply, line, map, time)
	if map and file.Exists("maps/"..map..".bsp", "GAME") then
		time = tonumber(time) or 10
		aowl.CountDown(time, "CHANGING MAP TO " .. map, function()
			game.ConsoleCommand("changelevel " .. map .. "\n")
		end)
	else
		return false, "map not found"
	end
end, "admins")

aowl.AddCommand("nextmap", function(ply, line, map)
	ply:ChatPrint("The next map is "..game.NextMap())
end, "players")

aowl.AddCommand("setnextmap", function(ply, line, map)
	if map and file.Exists("maps/"..map..".bsp", "GAME") then
		game.SetNextMap(map)
		ply:ChatPrint("The next map is now "..game.NextMap())
	else
		return false, "map not found"
	end
end, "admins")

aowl.AddCommand("maprand", function(player, line, map, time)
	time = tonumber(time) or 10
	local maps = file.Find("maps/*.bsp", "GAME")
	local candidates = {}

	for k, v in ipairs(maps) do
		if (not map or map=='') or v:find(map) then
			table.insert(candidates, v:match("^(.*)%.bsp$"):lower())
		end
	end

	if #candidates == 0 then
		return false, "map not found"
	end

	local map = table.Random(candidates)

	aowl.CountDown(tonumber(time), "CHANGING MAP TO " .. map, function()
		game.ConsoleCommand("changelevel " .. map .. "\n")
	end)
end, "admins")

aowl.AddCommand("maps", function(ply, line)
	local files = file.Find("maps/" .. (line or ""):gsub("[^%w_]", "") .. "*.bsp", "GAME")
	for _, fn in pairs( files ) do
		ply:ChatPrint(fn)
	end
	
	local msg="Total maps found: "..#files
	
	ply:ChatPrint(("="):rep(msg:len()))
	ply:ChatPrint(msg)
end, "admins")

aowl.AddCommand("resetall", function(player, line)
	aowl.CountDown(line, "RESETING SERVER", function()
		game.CleanUpMap()
		for k, v in ipairs(_G.player.GetAll()) do v:Spawn() end
	end)
end, "admins")


aowl.AddCommand({"retry", "rejoin"}, function(player, line)
	player:SendLua("LocalPlayer():ConCommand(\"retry\")")
end)

--[===[aowl.AddCommand("god",function(player, line)
	/*local newdmgmode = tonumber(line) or (player:GetInfoNum("cl_dmg_mode", 0) == 1 and 3 or 1)
	newdmgmode = math.floor(math.Clamp(newdmgmode, 1, 4))
	player:SendLua([[
		pcall(include, "autorun/translation.lua") local L = translation and translation.L or function(s) return s end
		LocalPlayer():ConCommand('cl_dmg_mode '.."]]..newdmgmode..[[")
		if (]]..newdmgmode..[[) == 1 then
			chat.AddText(L"God mode enabled.") 
		elseif (]]..newdmgmode..[[) == 3 then
			chat.AddText(L"God mode disabled.")
		else
			chat.AddText(string.format(L"Damage mode set to ".."%d.", (]]..newdmgmode..[[)))
		end
	]])*/
	
end, "moderators")]===]

--[==[aowl.AddCommand({"name","nick","setnick","setname","nickname"}, function(player, line)
	if line then
		line=line:Trim()
		if(line=="") or line:gsub(" ","")=="" then
			line = nil
		end
		if line and #line>40 then
			if not line.ulen or line:ulen()>40 then
				return false,"my god what are you doing"
			end
		end
	end
	timer.Create("setnick"..player:UserID(),1,1,function()
		if IsValid(player) then
			player:SetNick(line)
		end
	end)
end)]==]

aowl.AddCommand("restart", function(player, line, seconds, reason)
	local time = math.max(tonumber(seconds) or 20, 1)
					
	aowl.CountDown(time, "RESTARTING SERVER" .. (reason and reason ~= "" and Format(" (%s)", reason) or ""), function()
		game.ConsoleCommand("changelevel " .. game.GetMap() .. "\n")
	end)
end, "admins")

aowl.AddCommand("reboot", function(player, line, target)
	local time = math.max(tonumber(line) or 20, 1)

	aowl.CountDown(time, "SERVER IS REBOOTING", function()
		BroadcastLua("LocalPlayer():ConCommand(\"disconnect; snd_restart; retry\")")

		timer.Simple(0.2, function()
			game.ConsoleCommand("_restart\n")
			/*game.ConsoleCommand("exit\n")
			game.ConsoleCommand("shutdown\n")
			game.ConsoleCommand("restart\n")*/
		end)
	end)
end, "admins")

aowl.AddCommand("decals", function()
	all:ConCommand('r_cleardecals')
end, LOWEST_MOD_RANK)

aowl.AddCommand("fakedie", function(pl, cmd, killer, icon, swap)
	local victim 		= pl:Name()
	local killer 		= killer or ""
	local icon 			= icon or ""
	local killer_team	= -1
	local victim_team	= pl:Team()

	if swap and #swap > 0 then
		victim, killer				= killer, victim
		victim_team, killer_team	= killer_team, victim_team
	end

	net.Start("fakedie")
		net.WriteString(victim or "")
		net.WriteString(killer or "")
		net.WriteString(icon or "")
		net.WriteFloat(killer_team or -1)
		net.WriteFloat(victim_team or -1)
	net.Broadcast()
end, "admins")

if AtmosGlobal then

	AtmosGlobal.m_Paused = true

end

aowl.AddCommand({"3p", "thirdperson", "firstperson", "1p"}, function(ply) -- fuck you cave there's no lua file for random shit >:(
	ply:ConCommand("ctp")
end)


aowl.AddCommand({"dnc", "tod"}, function(ply, line, time)

	local time = tonumber(time)

	if not time then
	
		return false, "Thats not a number"
		
	end

	if AtmosGlobal then
	
		AtmosGlobal:SetTime(time)
		
	end
	
end, "admins")

do -- weldlag
	aowl.AddCommand("weldlag",function(pl,line,minresult)
		if not pl:HasModPowers() then return false,aowl.ModPowersFailed() end
		local t={}
		for k,v in pairs(ents.GetAll()) do
			local count=v:GetPhysicsObjectCount()
			if count==0 or count>1 then continue end
			local p=v:GetPhysicsObject()
			
			if not p:IsValid() then continue end
			if p:IsAsleep() then continue end
			if not p:IsMotionEnabled() then
				--if constraint.FindConstraint(v,"Weld") then -- Well only count welds since those matter the most, most often
					t[v]=true
				--end
			end
		end
		local lags={}
		for ent,_ in pairs(t) do
			local found
			for lagger,group in pairs(lags) do
				if ent==lagger or group[ent] then
					found=true
					break
				end
			end
			if not found then
				lags[ent]=constraint.GetAllConstrainedEntities(ent) or {}
			end
		end
		for c,cents in pairs(lags) do
			local count,lagc=1,t[k] and 1 or 0
			local owner
			for k,v in pairs(cents) do
				count=count+1
				if t[k] then
					lagc=lagc+1
				end
				if not owner and IsValid(k:CPPIGetOwner()) then
					owner=k:CPPIGetOwner()
				end
			end
		
			if count > (tonumber(minresult) or 5) then
				PrintMessage(HUD_PRINTTALK, "Found lagging contraption with "..lagc..'/'..count.." lagging ents (Owner: "..tostring(owner)..")")
			end
		end
	end, LOWEST_MOD_RANK)
end

aowl.AddCommand("aowl_fully_loaded", function() print"success" end)
