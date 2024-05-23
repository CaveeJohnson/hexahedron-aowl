
local meta 		= {
	__index = table
}
local queue 	= setmetatable({}, meta)
local started 	= false

local function doqueue()
	local sent

	for pl, plqueue in next, queue do
		sent = true

		if (not IsValid(pl)) then
			queue[pl] = nil
		else
			local func = plqueue:remove(1)

			if (not func) then
				queue[pl] = nil
			else
				local ok, err = pcall(func)
				if (not ok) then
					ErrorNoHalt("net_queue -> " .. err .. "\n")
				end
			end
		end
	end
	if (not sent) then 
		started = false
		hook.Remove("Think", "netqueue") 
	end
end

function net.queuesingle(pl, func)
	if (not started) then
		hook.Add("Think", "netqueue", doqueue)
	end
	
	local plqueue = queue[pl] or setmetatable({}, meta)
	queue[pl] = plqueue
	plqueue:insert(func)
end

function net.queue(targets, func)
	if (targets == true) then 
		targets = nil

	elseif (targets and isentity(targets)) then
		targets = {targets}

	end

	targets = targets or player.GetHumans()

	for i = 1, #targets do
		local pl = targets[i]
		net.queuesingle(pl, function() func(pl) end)
	end
end
