do
	print("aowl.lua: disabled since superseded by tetra")
	return
end

assert(FAST_ADDON_EASYLUA, "aowl requires easylua!")
assert(FAST_ADDON_LUADATA, "aowl requires luadata!")

local list =
{
	players    =    1,
	donators   =    2,

	helpers    =    9,
		viphelpers = 9,
	moderators =   99,
		vipmoderators = 99,
	admins     =  999, -- admins and devs get so many perms that vip shit doesn't matter

	newdevs    =   10,
	developers =  100,
	leaddevs   = 1000,

	managers   = 5000,
	owners     = math.huge,
}

local realNames =
{
	newdevs  = "N.Developers",
	leaddevs = "L.Developers",
	viphelpers = "Helpers",
	vipmoderators = "Moderators",
}

local alias =
{
	user           = "players",
	users          = "players",
	player         = "players",
	default        = "players",

	vips           = "donators",
	
	mods           = "moderators",
	devs           = "developers",

	admin          = "admins",
	admins         = "admins",
	administrator  = "admins",
	administrators = "admins",
	
	management     = "managers",
	manager        = "managers",
	superadmin     = "managers",
	superadmins    = "managers",

	gays           = "owners",
}

local META = FindMetaTable("Player")

function META:CheckUserGroupLevel(name)

	name = alias[name] or name
	local ugroup = self:GetUserGroup()

	local a = list[ugroup]
	local b = list[name]

	return a and b and a >= b
end

function META:GetUserGroupName()
	local ugroup = self:GetUserGroup()
	if realNames[ugroup] then return realNames[ugroup] end

	return ugroup:gsub("^%l", string.upper)
end

function META:ShouldHideAdmins()
	return self.hideadmins or self:GetNWBool("hideadmins")
end


function META:IsDonator()
	if self:ShouldHideAdmins() then
		return false
	end

	return self:CheckUserGroupLevel("donators")
end


function META:IsMod(excludeHelpers)
	if self:ShouldHideAdmins() then
		return false
	end

	return self:CheckUserGroupLevel(excludeHelpers and "moderators" or "helpers")
end

function META:IsDev(excludeNew)
	if self:ShouldHideAdmins() then
		return false
	end
	if self:IsUserGroup("moderators") then -- mods are higher than newdevs but are NOT devs
		return false
	end

	return self:CheckUserGroupLevel(excludeNew and "developers" or "newdevs")
end
META.IsAdmin = META.IsDev -- default game 'admin' status is for all devs and admin+ staff
META.IsSuperAdmin = META.IsDev -- default game 'superadmin' status is for all devs and admin+ staff

function META:IsServerAdmin()
	if self:ShouldHideAdmins() then
		return false
	end

	return self:CheckUserGroupLevel("admins")
end

function META:IsManager()
	if self:ShouldHideAdmins() then
		return false
	end

	return self:CheckUserGroupLevel("managers")
end


function META:AlwaysHasModPowers()
	return
		self:IsMod() and -- < helper = no
		(self:IsUserGroup("moderators") or self:IsAdmin()) -- >= admin = yes, mod = yes
end

function META:HasModPowers() -- do not use this function on tick, only for commands
	if self:AlwaysHasModPowers() then return true end

	-- this code is for helpers, newdevs and devs
	for _, v in ipairs(player.GetAll()) do
		if v:AlwaysHasModPowers() and (not v.AFKTime or v:AFKTime() <= 60 * 10) then
			return false
		end
	end

	return true
end


function META:IsUserGroup(name)
	name = alias[name] or name
	name = name:lower()
	
	local ugroup = self:GetUserGroup()
	
	return ugroup == name or false
end

function META:GetUserGroup()
	if self:ShouldHideAdmins() then
		return "players"
	end

	return self:GetNetworkedString("UserGroup"):lower()
end

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

if CLIENT then return end

-- This is the file where the user ranks are stored.
-- This is used internally.
local USERSFILE = "aowl/users.txt"
file.CreateDir("aowl")

local dont_store =
{
	"players",
	"users",
}

local function clean_users(users, _steamid)

	for name, group in next, users do
		name = name:lower()

		if (table.HasValue(dont_store, name) or not list[name]) then
			print("Cleaning illegal group ", name)
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

function aowl.SetUserGroupForSteamID(id, nick, name)
	local users = luadata.ReadFile(USERSFILE)
		users = clean_users(users, id)
		users[name] = users[name] or {}
		users[name][id] = nick:gsub("%A", "") or "???"

	luadata.WriteFile(USERSFILE, users)
	
	aowlMsg("rank", string.format("Changing %s (%s) usergroup to %s", nick, id, name))
end

function META:SetUserGroup(name, force)
	name = name:Trim()
	name = alias[name] or name

	self:SetNetworkedString("UserGroup", name)

	if (force == false or #name == 0) then
		return
	end

	name = name:lower()

	if not table.HasValue(dont_store, name) and (force or list[name]) then
		if (!list[name]) then
			aowlMsg("ForceRank", self:Nick() .. " -> " .. name .. " (Non-Existant!)")
		end

		aowl.SetUserGroupForSteamID(self:SteamID(), self:Nick(), name)
	end
end

function aowl.CleanUsers()
	local users = luadata.ReadFile(USERSFILE)
		users = clean_users(users, "")

	luadata.WriteFile(USERSFILE, users)
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

local users_file_date, users_file_cache = -2, nil
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
