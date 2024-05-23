local Tag = "propkill"

hook.Add("PhysgunPickup", Tag, function(pl, ent)
    ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
end)
