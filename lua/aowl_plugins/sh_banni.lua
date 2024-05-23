banni = banni or {}

local META 		= FindMetaTable("Player")
local BANFILE 	= "aowl/banni.txt"
local HARDFILE 	= "aowl/hardbanni.txt"

function banni.UnixTime()
	return os.time()
end

function banni.ValidSteamID(id)
	if (!id) 										then return false end
	if (!isstring(id)) 								then return false end

	id = id:lower():Trim()

	if (!id:find("steam_[0-9]+:[0-9]+:[0-9]+"))		then return false end
	
	return true
end

function banni.DateString(timestamp)
	return os.date("%d/%m/%y, %X", timestamp)
end

function META:IsBanned()
	return self:GetNetData("banned")
end
if CLIENT then
	local redColor 	= Color(255, 50 , 50 , 255)
	local colGrey 	= Color(120, 120, 120, 255)
	local colTrans 	= Color(0  , 0  , 0  , 90 )

	surface.CreateFont(
		"banni",
		{
			font		= "Roboto Bk",
			size		= 50,
			weight		= 800,
		}
	)

	net.Receive("bannimsg", function()
		local banner = net.ReadString()
		local banned = net.ReadString()
		local expire = net.ReadString()
		local reason = net.ReadString()

		local isbanned = net.ReadBool()

		chat.AddText(
			color_white, banner,
			redColor, (isbanned and " BANNED " or " UNBANNED "),
			color_white, banned .. (isbanned and " until " .. expire or "") .. " -> \"" .. reason .. "\""
		)
	end)

	local BaseInfo = {
		["$basetexture"]	= "models/debug/debugwhite",
	}

	local bannimat = CreateMaterial("Banni", "VertexLitGeneric", BaseInfo)
	local _banned

	local function entitybanni(ply)
		if (not ply:Alive() or not ply:IsBanned()) then
			return
		end

		_banned = true

		render.SuppressEngineLighting(true)
			render.ModelMaterialOverride(bannimat)
			render.MaterialOverride(bannimat)
			render.SetColorModulation(1, 0, 0)
			--render.SetBlend(0.5)
	end
	hook.Add("PrePlayerDraw", "entity_banni", entitybanni)

	local function entitybanni2(ply)
		if (_banned) then
				--render.SetBlend(1)
				render.MaterialOverride(0)
				render.SetColorModulation(1, 1, 1)
				render.ModelMaterialOverride(0)
			render.SuppressEngineLighting(false)

			_banned = false
		end
	end
	hook.Add("PostPlayerDraw", "entity_banni", entitybanni2)

	local function drawbanni()
		local time, ply		= CurTime(), LocalPlayer()
		local isbanned 		= ply:GetNetData("banned")

		if (!isbanned) then
			return
		end

		surface.SetFont("banni")

		local scrw, scrh 	= ScrW(), ScrH()

		local unban = ply:GetNetData("unban")
		local banner = ply:GetNetData("banner")

		if (!unban or !banner) then
			return
		end

		local niceUnban = banni.DateString(unban) .. " (" .. math.max(math.floor((unban - banni.UnixTime()) / 60), 1) .. " mins)"

		local w = surface.GetTextSize("Banned by " .. banner)
		local w2 = surface.GetTextSize(niceUnban)

		surface.SetDrawColor(colTrans)
		surface.DrawRect((scrw / 2) - math.max(w / 2, w2 / 2) - 10, 10, math.max(w, w2) + 20, 130)

		surface.SetTextColor(redColor)

		surface.SetTextPos((scrw / 2) - w / 2, 20)
		surface.DrawText("Banned by " .. banner)

		surface.SetTextColor(color_white)

		surface.SetTextPos((scrw / 2) - w2 / 2, 80)
		surface.DrawText(niceUnban)
	end
	hook.Add("HUDPaint", "banni_info", drawbanni)
end

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

local function hooki2(ply)
	if (!ply or !ply:IsPlayer()) then
		return
	end

	if (ply:IsBanned()) then
		return true
	end
end

hook.Add("CanTool", "banni_tool", hooki)
hook.Add("PhysgunPickup", "banni_physgun", hooki)
hook.Add("PlayerShouldTakeDamage", "banni_hurt", function(ply, atc) if (hooki(atc) == false) then return false end end)
hook.Add("PlayerSpawnProp", "banni_prop", hooki)
hook.Add("PlayerUse", "banni_entuse", hooki)
--hook.Add("OnPlayerChat", "banni_mute", hooki2)