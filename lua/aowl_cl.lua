do
	print("aowl.lua: disabled since superseded by tetra")
	return
end

-- All of aowl's clientside is now contained within this file.
-- Why? Not because we don't want people stealing serverside code, but
-- rather because what is the point in making the client load another
-- several hundred lines of code and functions that will just error
-- if ran?

-- Nothing is ever in this but it can be used to check if the server
-- is running aowl :)
aowl = {}

local function L(s) return s end

-- TODO: Rewrite this entire file, it's pretty bad...

do -- groups

	local list =
	{
		players 	= 1,
		moderators 	= 2,
		developers 	= 10, -- 3,
		owners 		= math.huge,
	}

	local alias =
	{
		user 			= "players",
		users 			= "players",
		player 			= "players",
		default 		= "players",

		mods 			= "moderators",

		devs 			= "developers",
		admin 			= "developers",
		admins 			= "developers",
		administrator 	= "developers",
		administrators 	= "developers",

		gays 			= "owners",
		superadmin 		= "owners",
		superadmins 	= "owners",
	}

	local META = FindMetaTable("Player")

	function META:CheckUserGroupLevel(name)

		name = alias[name] or name
		local ugroup = self:GetUserGroup()

		local a = list[ugroup]
		local b = list[name]

		return a and b and a >= b
	end

	function META:ShouldHideAdmins()
		return self.hideadmins or false
	end

	function META:IsMod()
		if (self:ShouldHideAdmins()) then
			return false
		end

		return self:CheckUserGroupLevel("moderators")
	end

	function META:IsAdmin()
		if (self:ShouldHideAdmins()) then
			return false
		end

		return self:CheckUserGroupLevel("developers")
	end

	function META:IsSuperAdmin()
		if (self:ShouldHideAdmins()) then
			return false
		end

		return self:CheckUserGroupLevel("developers")
	end

	function META:IsUserGroup(name)
		name = alias[name] or name
		name = name:lower()

		local ugroup = self:GetUserGroup()

		return ugroup == name or false
	end

	function META:GetUserGroup()
		if (self:ShouldHideAdmins()) then
			return "players"
		end

		return self:GetNetworkedString("UserGroup"):lower()
	end

	if SERVER then
		local dont_store =
		{
			"players",
			"users",
		}

		local function clean_users(users, _steamid)

			for name, group in next, users do
				name = name:lower()

				if (not list[name]) then
					users[name] = nil

				else
					for steamid in next, group do
						if (steamid:lower() == _steamid:lower()) then
							group[steamid] = nil
						end
					end

				end
			end

			return users
		end

		local function safe(str)
			return str:gsub("{",""):gsub("}","")
		end

		function META:SetUserGroup(name, force)
			name = name:Trim()
			name = alias[name] or name

			self:SetNetworkedString("UserGroup", name)

			if (force == false or #name == 0) then
				return
			end

			name = name:lower()

			if force or (not table.HasValue(dont_store, name) and list[name]) then
				if (!list[name]) then
					aowlMsg("ForceRank", self:Nick() .. " -> " .. name .. " (Non-Existant!)")
				end

				local users = luadata.ReadFile(USERSFILE)
					users = clean_users(users, self:SteamID())
					users[name] = users[name] or {}
					users[name][self:SteamID()] = self:Nick():gsub("%A", "") or "???"

				file.CreateDir("aowl")
				luadata.WriteFile(USERSFILE, users)

				aowlMsg("rank", string.format("Changing %s (%s) usergroup to %s", self:Nick(), self:SteamID(), name))
			end
		end

		function aowl.GetUserGroupFromSteamID(id)
			for name, users in next, luadata.ReadFile(USERSFILE) do
				for steamid, nick in next, users do
					if (steamid == id) then
						return name, nick
					end
				end
			end
		end

		function aowl.CheckUserGroupFromSteamID(id, name)
			local group = aowl.GetUserGroupFromSteamID(id)

			if (group) then
				name = alias[name] or name

				local a = list[group]
				local b = list[name]

				return a and b and a >= b
			end

			return false
		end

		local users_file_date,users_file_cache = -2, nil
		hook.Add("PlayerSpawn", "PlayerAuthSpawn", function(ply)

			ply:SetUserGroup("players")

			if (game.SinglePlayer() or ply:IsListenServerHost()) then
				ply:SetUserGroup("owners")

				return
			end

			local timestamp = file.Time(USERSFILE, "DATA")
			timestamp = timestamp and timestamp > 0 and timestamp or 0/0


			if users_file_date ~= timestamp then
				users_file_cache = luadata.ReadFile(USERSFILE) or {}
				users_file_date = timestamp
			end

			for name, users_file_cache in next, users_file_cache do
				for steamid in next, users_file_cache do
					if (ply:SteamID() == steamid or ply:UniqueID() == steamid) then
						ply:SetUserGroup(name, false)
					end
				end
			end
		end)

		hook.Add("InitPostEntity", "LoadNoLimits", function()
			local META = FindMetaTable("Player")

			local _R_Player_GetCount = META.GetCount

			function META:GetCount(limit, minus)
				if (self.Unrestricted) then
					return -1
				else
					return _R_Player_GetCount(self, limit, minus)
				end
			end
		end)
	end
end

local CONFIG = {}

CONFIG.TargetTime 	= 0
CONFIG.Counting 	= false
CONFIG.Warning 		= ""
CONFIG.PopupText	= {}

CONFIG.PopupPos		= {
	{0,0},
	{0,0},
	{0,0},
}

CONFIG.LastPopup	= CurTime()

CONFIG.Popups		= {
	"HURRY!",
	"FASTER!",
	"YOU WON'T MAKE IT!",
	"QUICKLY!",
	"GOD YOU'RE SLOW!",
	"DID YOU GET EVERYTHING?!",
	"ARE YOU SURE THAT'S EVERYTHING?!",
	"OH GOD!",
	"OH MAN!",
	"YOU FORGOT SOMETHING!",
	"SAVE SAVE SAVE",
}

CONFIG.StressSounds = {
	Sound("vo/ravenholm/exit_hurry.wav"),
	Sound("vo/npc/Barney/ba_hurryup.wav"),
	Sound("vo/Citadel/al_hurrymossman02.wav"),
	Sound("vo/Streetwar/Alyx_gate/al_hurry.wav"),
	Sound("vo/ravenholm/monk_death07.wav"),
	Sound("vo/coast/odessa/male01/nlo_cubdeath02.wav"),
}

CONFIG.NextStress	= CurTime()

CONFIG.NumberSounds = {
	Sound("npc/overwatch/radiovoice/one.wav"),
	Sound("npc/overwatch/radiovoice/two.wav"),
	Sound("npc/overwatch/radiovoice/three.wav"),
	Sound("npc/overwatch/radiovoice/four.wav"),
	Sound("npc/overwatch/radiovoice/five.wav"),
	Sound("npc/overwatch/radiovoice/six.wav"),
	Sound("npc/overwatch/radiovoice/seven.wav"),
	Sound("npc/overwatch/radiovoice/eight.wav"),
	Sound("npc/overwatch/radiovoice/nine.wav"),
}

CONFIG.LastNumber	= CurTime()

surface.CreateFont(
	"aowl_restart",
	{
		font		= "Roboto Bk",
		size		= 60,
		weight		= 1000,
	}
)

surface.CreateFont(
	"aowl_restart_retard",
	{
		font		= "Roboto Bk",
		size		= 30,
		weight		= 1000,
	}
)

local colGrey 	= Color(50 , 50 , 50 , 255)
local colGreen 	= Color(0  , 255, 255, 255)

local function DrawWarning()
	surface.SetFont("aowl_restart")

	local localised 	= L(CONFIG.Warning)
	local messageWidth 	= surface.GetTextSize(localised)

	local scrw, scrh 	= ScrW(), ScrH()
	local time, ply		= CurTime(), LocalPlayer()

	local timeRemaining = CONFIG.TargetTime - time

	surface.SetDrawColor(  0, 120, 255, 10 + (math.sin(time * 3) * 20))
	surface.DrawRect(0, 0, scrw, scrh)

	-- Countdown bar
	surface.SetDrawColor(colGreen)
	surface.DrawRect(
		(scrw - messageWidth) / 2,
		75,
		messageWidth * math.max(0, timeRemaining / (CONFIG.TargetTime - CONFIG.StartedCount)),
		20
	)

	surface.SetDrawColor(color_black)
	surface.DrawOutlinedRect(
		(scrw - messageWidth) / 2,
		75,
		messageWidth,
		20
	)

	surface.SetTextColor(colGrey)

	-- retard warning
	surface.SetFont("aowl_restart_retard")

	local retardProofing = "Refunds are automatic!"
	local ww, wh = surface.GetTextSize(retardProofing)
	surface.SetTextPos((scrw / 2) - ww / 2, 50 - wh / 2)
	surface.DrawText(retardProofing)

	-- Countdown message
	surface.SetFont("aowl_restart")

	local messageTable = string.Split(localised, "\n")
	local y = 100

	for i = 1, #messageTable do
		local messageLine = messageTable[i]

		local w, h = surface.GetTextSize(messageLine)
		w = w or 56

		surface.SetTextPos((scrw / 2) - w / 2, y)
		surface.DrawText(messageLine)

		y = y + h
	end

	-- Countdown timer
	local Count = string.format("%.3f", timeRemaining)
	local w = surface.GetTextSize(Count)

	surface.SetTextPos((scrw / 2) - w / 2, y)
	surface.DrawText(Count)

	surface.SetTextColor(255, 255, 255, 255)

	--[[if (time - CONFIG.LastPopup > 0.5) then
		for i = 1, 3 do
			CONFIG.PopupText[i] = L(table.Random(CONFIG.Popups))

			local w, h = surface.GetTextSize(CONFIG.PopupText[i])
			CONFIG.PopupPos[i] = {math.random(1, scrw - w), math.random(1, scrh - h) }
		end
		CONFIG.LastPopup = time
	end]]

	--[[if (time > CONFIG.NextStress) then
		ply:EmitSound(CONFIG.StressSounds[math.random(1, #CONFIG.StressSounds)], 80, 100)
		CONFIG.NextStress = time + math.random(1, 2)
	end]]

	local num = math.floor(CONFIG.TargetTime - time)
	if (CONFIG.NumberSounds[num] and time - CONFIG.LastNumber > 1) then
		CONFIG.LastNumber = time
		ply:EmitSound(CONFIG.NumberSounds[num], 511, 100)
	end

	--[[for i = 1, 3 do
		surface.SetTextPos(CONFIG.PopupPos[i][1], CONFIG.PopupPos[i][2])
		surface.DrawText(CONFIG.PopupText[i])
	end]]
end

local siren = Sound("ambient/alarms/combine_bank_alarm_loop4.wav")

local function countdown(um)
	local typ 			= um:ReadShort()
	local time 			= um:ReadShort()

	local ctime, ply 	= CurTime(), LocalPlayer()

	CONFIG.Sound = CONFIG.Sound or CreateSound(ply, siren)
	CONFIG.Sound:SetSoundLevel(45)

	if typ == -1 then
		CONFIG.Counting = false
		CONFIG.Sound:FadeOut(2)

		hook.Remove("HUDPaint", "__countdown__")

		return
	end

	CONFIG.Sound:Play()
	CONFIG.StartedCount = ctime
	CONFIG.TargetTime 	= ctime + time
	CONFIG.Counting 	= true

	hook.Add("HUDPaint", "__countdown__", DrawWarning)

	if 		(typ == 0) then
		CONFIG.Warning = "SERVER IS RESTARTING THE LEVEL\nSAVE YOUR PROPS AND HIDE THE CHILDREN!"

	elseif 	(typ == 1) then
		CONFIG.Warning = string.format("SERVER IS CHANGING LEVEL TO %s\nSAVE YOUR PROPS AND HIDE THE CHILDREN!", um:ReadString():upper())

	elseif 	(typ == 2) then
		CONFIG.Warning = um:ReadString()

	end
end
usermessage.Hook("__countdown__", countdown)

local function kill(um)
	local ply 		= um:ReadEntity()
	local vel 		= um:ReadLong()
	local angvel 	= um:ReadLong()

	if not ply or not IsValid(ply) then
		return
	end

	local id = "find_rag_" .. ply:EntIndex()

	local f = function()
		if not ply:IsValid() then
			return
		end

		local rag = ply:GetRagdollEntity() or NULL
		if not rag:IsValid() then
			return
		end

		local phys = rag:GetPhysicsObject() or NULL

		if not phys:IsValid() then
			return
		end

		local vel = ply:GetAimVector() * vel
		local angvel = VectorRand() * angvel

		for i = 0, rag:GetPhysicsObjectCount() - 1 do
			local phys = rag:GetPhysicsObjectNum(i)	or NULL

			if phys:IsValid() then
				phys:SetVelocity(vel)
				phys:AddAngleVelocity(angvel)
			end
		end

		phys:SetVelocity(vel)
		phys:AddAngleVelocity(angvel)

		timer.Remove(id)
	end

	timer.Create(id, 0, 100, f)
end
usermessage.Hook("aowl_kill", kill)

local function fakedie()
	local victim 		= net.ReadString()
	local killer 		= net.ReadString()
	local icon 			= net.ReadString()
	local killer_team 	= net.ReadFloat()
	local victim_team 	= net.ReadFloat()

	GAMEMODE:AddDeathNotice(killer, killer_team, icon, victim, victim_team)
end
net.Receive("fakedie", fakedie)
