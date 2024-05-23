if SERVER then
	util.AddNetworkString("hentai")
	local quotes = {
		"No, drink it.",
		"You want more, right?",
		"It's not that weird...",
		"I'm about to cum onii-chan!",
		"Onii-chan don't spank me..",
		"Onii-chan don't stop..",
		"Onii-chan keep doing me, please..",
		"I'm cuming onii!",
		"Onii please drink my .. juice",
		"Onii please don't look at me with that look..",
		"{NAME} please don't stop",
		"{NAME} don't spank me that hard..",
		"{NAME} p-please be gentle..",
		"{NAME} its my first time." ,
		"{NAME} please follow me into the shower",
		"Teacher we're having an orgy" ,
		"Please don't look we're having a orgy here, baka!",
		"Be more gentle baka!",
		"You shouldn't care about what other people say about our relationship!",
		"I can't retain myself anymore, {NAME}...",
		"I love you, {NAME}!...",
		"I.. Love you, baka..",
		"I can feel it inside of my uterus!",
		"You're so hot",
		"You're quite large down there {NAME}..",
		"Baka! It hurts..",
		"My hole is getting penetrated by a dirty ..." ,
		"Stop fingering my hole.. Baka..",
		"I didn't say stop."
	}

	-- DarkRP causes a really stupid double hooking issue.
	if (SERVER and GAMEMODE and GAMEMODE.OldChatHooks and GAMEMODE.OldChatHooks.hentai) then
		GAMEMODE.OldChatHooks.hentai = nil
	end


	hentai = hentai or {}
	hentai.quotes = quotes

	function hentai.Speak(ply)
		local text = table.Random(hentai.quotes):gsub("{NAME}", (ply or table.Random(player.GetAll())):Nick())

		net.Start("hentai")
			net.WriteString(string.anime and string.anime(text) or text)
		net.Broadcast()
	end

	function hentai.PlayerSay(ply, str)
		if (str:lower():find("hentai")) then
			timer.Simple(0.1, hentai.Speak)
		end
	end
	hook.Add("PlayerSay", "hentai", hentai.PlayerSay)
else
	local hentaiColor = Color(255, 150, 255, 255)
	net.Receive("hentai", function()
		local txt = net.ReadString()
		chat.AddText(hentaiColor, 'Hentai', color_white, ": " .. txt)
	end)
end
