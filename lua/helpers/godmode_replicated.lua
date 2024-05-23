local META = FindMetaTable("Player")

if SERVER then
	hook.Add("PlayerTick", "GodReplicated", function(ply)
		ply:SetNWBool("IsGod", ply:IsFlagSet(FL_GODMODE))
	end)
end

function META:IsGod()
	return self:GetNWBool("IsGod")
end
