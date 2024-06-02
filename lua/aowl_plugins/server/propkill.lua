local Tag = "propkill"

do
	local ignore

	hook.Add("PhysgunPickup", Tag, function(pl, ent)
		if ent:IsPlayer() then return end
		if ignore then return end

		ignore = true
		local canTouch = hook.Run("PhysgunPickup", pl, ent)
		ignore = false

		if canTouch and not ent:CreatedByMap() and not (ent:GetCollisionGroup() == COLLISION_GROUP_WORLD) then
			ent.Old_ColGroup = ent:GetCollisionGroup() or COLLISION_GROUP_NONE
			ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		end
	end)
end

hook.Add("PhysgunDrop", Tag, function(pl, ent)
	if ent:IsPlayer() then return end
	ent:SetPos(ent:GetPos())

	if ent.Old_ColGroup then
		ent:SetCollisionGroup(ent.Old_ColGroup)
		ent.Old_ColGroup = nil
	end

	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then
		phys:AddAngleVelocity(phys:GetAngleVelocity() * -1)
	end
end)

hook.Add("PlayerShouldTakeDamage", Tag, function(pl, ent)
	if hook.Run("PropKill-PlayerShouldTakeDamage", pl, ent) then
		ent:SetPos(ent:GetPos())
		
		return false
	end
end)

hook.Add("EntityTakeDamage", Tag, function(pl, dmg)
	if hook.Run("PropKill-EntityTakeDamage", pl, dmg) then
		dmg:SetDamage(0)
	end
end)
