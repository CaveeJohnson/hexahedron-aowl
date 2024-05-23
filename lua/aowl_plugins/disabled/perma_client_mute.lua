local META = FindMetaTable("Player")
local cache

META.Old_IsMuted = META.Old_IsMuted or META.IsMuted

function META:IsMuted()
	local id = self:UniqueID()

	if (not cache) then
		cache = luadata.ReadFile("muted_list.txt")
	end
	
	return cache[id]
end

META.Old_SetMuted = META.Old_SetMuted or META.SetMuted

function META:SetMuted(b)
	local id = self:UniqueID()
	
	if not cache then
		cache = luadata.ReadFile("muted_list.txt")
	end
	
	cache[id] = b
	
	-- so it removes instead of adds
	if (not b) then
		b = nil
	end
	
	luadata.SetKeyValueInFile("muted_list.txt", id, b)	
end

timer.Create("update_muted_players", 2, 0, function()
	if (not cache) then
		cache = luadata.ReadFile("muted_list.txt")
	end

	local players = player.GetAll()
	
	for i = 1, #players do
		local ply = players[i]

		if (cache[ply:UniqueID()]) then
			if (not ply:Old_IsMuted()) then
				ply:Old_SetMuted(true)
			end
		end
	end
end)
