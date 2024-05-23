local META 		= FindMetaTable("Player")
local BANFILE 	= "aowl/banni.txt"
local HARDFILE 	= "aowl/hardbanni.txt"

function banni.HardBan(id, name, reason)
	local hardbans = luadata.ReadFile(HARDFILE)
		hardbans[id] = {
			name 	= name,
			reason 	= reason,
		}
	luadata.WriteFile(HARDFILE, hardbans)

	local ply = banni.GetEntitiesInvolves(id)

	if (ply) then
		cleanup.CC_Cleanup(ply, nil, {})

		ply:Kick("hardbanni (server access revoked) - " .. reason)
	end

	banni.Message("HexaHedron", name, "THE END OF TIME", reason, true)
end

function banni.UnHardBan(id, reason)
	local hardbans = luadata.ReadFile(HARDFILE)
		local name = hardbans[id].name
		hardbans[id] = nil
	luadata.WriteFile(HARDFILE, hardbans)

	banni.Message("HexaHedron", name, nil, reason, false)
end

function banni.IsHardBanned(id)
	local hardbans = luadata.ReadFile(HARDFILE)

	return hardbans[id]
end

function banni.ReadBanData(id)
	local bans = luadata.ReadFile(BANFILE)
		local ban = bans[id]

	if (ban) then
		return ban
	end

	return false
end

function banni.ExpireBans()
	local bans = luadata.ReadFile(BANFILE)

	for id, ban in next, bans do
		if (ban.b and ban.whenunban - banni.UnixTime() < 0) then
			banni.UnBan(id, "System", "Ban time has expired.")
		end
	end
end
timer.Create("banni_unban", 5, 0, banni.ExpireBans)

function banni.SetVars(banned, ply, banner, unban, reason)
	if (!banned) then
		ply:SetNetData("banner", 	nil)
		ply:SetNetData("unban", 	nil)
		ply:SetNetData("banreason", nil)
		ply:SetNetData("banned", 	false)

		all:EmitSound("buttons/combine_button_locked.wav")
		ply:SetWeaponRestricted(false)
		ply:Spawn()

		return
	end

	ply:SetWeaponRestricted(true)
	all:EmitSound("ambient/alarms/klaxon1.wav")

	ply:SetRunSpeed(130) 
	ply:SetWalkSpeed(100)

	ply:SetNetData("banner", 	banner)
	ply:SetNetData("unban", 	unban)
	ply:SetNetData("banreason", reason)
	ply:SetNetData("banned", 	true)
end

function banni.GetEntitiesInvolves(sid, bannerid)
	local players = player.GetAll()
	local banned, admin

	for i = 1, #players do
		local ply = players[i]

		if (ply and ply:SteamID() == sid) then
			banned = ply
		end

		if (bannerid and ply and ply:SteamID() == bannerid) then
			admin = ply
		end
	end

	return banned, admin	
end

function banni.Ban(id, name, banner, reason, unban)
	local bans = luadata.ReadFile(BANFILE)
		local oldban = bans[id]
		bans[id] = {
			sid 			= id,
			name 			= name,

			bannersid 		= banner,
			banreason 		= reason,

			whenunban 		= unban,
			whenbanned 		= banni.UnixTime(),

			numbans 		= (oldban and oldban.numbans or 0) + 1,
			b 				= true,

			unbanreason 	= nil,
			unbannersid		= nil,
			whenunbanned 	= nil,
		}
	luadata.WriteFile(BANFILE, bans)


	local bannedPlayer, adminPlayer = banni.GetEntitiesInvolves(id, banner)

	local niceUnban = banni.DateString(unban)
	local bannerDisplay = (adminPlayer and adminPlayer:Nick()) or banner

	if (bannedPlayer) then
		banni.SetVars(true, bannedPlayer, bannerDisplay, unban, reason)
		cleanup.CC_Cleanup(bannedPlayer, nil, {})
	end

	banni.Message(bannerDisplay, name, niceUnban, reason, true)
end

function banni.UnBan(id, unbanner, reason)
	local bans = luadata.ReadFile(BANFILE)
		if (!bans[id] or !bans[id].b) then 
			print("Cannot unban, no banni")

			return
		end

		bans[id].b 				= false
		bans[id].unbanreason 	= reason
		bans[id].whenunbanned 	= banni.UnixTime()
		bans[id].unbannersid 	= unbanner
	luadata.WriteFile(BANFILE, bans)

	local name = bans[id].name

	local unbannedPlayer, adminPlayer = banni.GetEntitiesInvolves(id, unbanner)
	local unbannerDisplay = (adminPlayer and adminPlayer:Nick()) or unbanner

	if (unbannedPlayer) then
		banni.SetVars(false, unbannedPlayer)
	end

	banni.Message(unbannerDisplay, name, nil, reason, false)
end

function banni.ResetBanCount(id)
	local bans = luadata.ReadFile(BANFILE)
		if (!bans[id]) then 
			print("Cannot reset, no banni")

			return
		end

		bans[id].numbans = 0
	luadata.WriteFile(BANFILE, bans)
end

util.AddNetworkString("bannimsg")
function banni.Message(banner, banned, expire, reason, isbanned)
	net.Start("bannimsg")
		net.WriteString(banner or "")
		net.WriteString(banned or "")
		net.WriteString(expire or "")
		net.WriteString(reason or "")
		net.WriteBool(isbanned)
	net.Broadcast()
end

function banni.PlayerInitialSpawn(ply)
	local ban = banni.ReadBanData(ply:SteamID())
	if (!ban or !ban.b) then
		return
	end

	ply:SetWeaponRestricted(true)

	banni.SetVars(true, ply, ban.bannersid, ban.whenunban, ban.banreason)
end
hook.Add("PlayerInitialSpawn", "banni_spawn", banni.PlayerInitialSpawn)

function banni.CheckPassword(sid64)
	local sid 		= SteamID64ToSteamID(sid64)
	local baninfo 	= banni.ReadBanData(sid)

	local hardban 	= banni.IsHardBanned(sid)

	local slots 	= game.MaxPlayers()
	local players 	= player.GetAll()
	local cur 		= #players

	if (hardban) then
		return false, "hardbanni - " .. hardban.reason
	end

	if (cur >= slots) then
		return false, "Darn, the server's full, best try again later! Remember you can still join if you are banned."
	end

	if (cur >= slots - 1) then
		if (baninfo and baninfo.b) then
			return false, "Sorry, but the server is (nearly) full and you are banned, your ban expires on " .. banni.DateString(baninfo.whenunban)
		else
			for i = 1, #players do
				local v = players[i]

				if (v:IsBanned()) then
					v:Kick("Sorry, but the server is (nearly) full. You are banned and have been (selected randomly and) kicked to make room for non-banned players.")

					break
				end
			end
		end
	end
end
hook.Add("CheckPassword", "banni_connect", banni.CheckPassword)

local function hooki(ply)
	if (!ply or !ply:IsPlayer()) then
		return
	end

	if (ply:IsBanned()) then
		if (SERVER) then
			ply:StripWeapons()
			ply:StripAmmo()
		end
		
		return false
	end
end

hook.Add("PlayerCanHearPlayersVoice", "banni_voip", function(lis, tal) if (hooki(tal) == false) then return false end end)
hook.Add("PlayerSpawn", "banni_spawn", function(ply) timer.Simple(0, function() if (hooki(ply) == false) then ply:SetRunSpeed(130) ply:SetWalkSpeed(100) end end) end)