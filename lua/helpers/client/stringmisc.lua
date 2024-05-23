local META = string

function META:OpenURL()
	gui.OpenURL(self)
end

function cmd(str)
	LocalPlayer():ConCommand(str)
end

function Say(...)
	local tbl = {...}

	local function cmdsay()
		cmd("say " .. string.format(unpack(tbl)))
	end
	timer.Simple(0.8, cmdsay)
end
