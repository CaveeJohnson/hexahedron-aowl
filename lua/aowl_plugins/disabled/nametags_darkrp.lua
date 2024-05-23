local tag = "nametags"

local PLAYER = FindMetaTable("Player")

if SERVER then
	util.AddNetworkString(tag .. "TitleChange")

	function PLAYER:SetCustomTitle(txt)
		if #txt > 67 then
			aowl.Message(self, "my god what are you doing")
		end

		self:SetPData(tag .. "Title", txt)
		self:SetNWString(tag .. "Title", txt)

		net.Start(tag .. "TitleChange")
			net.WriteInt(self:EntIndex(), 16)
			net.WriteString(txt)
		net.Broadcast()
	end

	net.Receive(tag .. "TitleChange", function(_, ply)
		local txt = net.ReadString()
		ply:SetCustomTitle(txt)
	end)

	aowl.AddCommand("title", function(caller, _, txt, ply)
		if not txt or txt:Trim() == "" then txt = "" end
		if not ply or ply:Trim() == "" then
			ply = caller
		end
		if ply ~= caller then
			ply = easylua.FindEntity(ply)
		end
		if not IsValid(ply) then return false, "Invalid player" end
		
		ply:SetCustomTitle(txt)
	end)

	hook.Add("PlayerSpawn", tag, function(ply)
		ply:SetCustomTitle(ply:GetPData(tag .. "Title") or "")
	end)
end

function PLAYER:GetCustomTitle()
	return self:GetNWString(tag .. "Title")
end

if CLIENT then
	function PLAYER:SetCustomTitle(txt)
		net.Start(tag .. "TitleChange")
			net.WriteString(txt)
		net.SendToServer()
	end

	net.Receive(tag .. "TitleChange", function()
		local plyID = net.ReadInt(16)
		local txt = net.ReadString()
		Entity(plyID).CustomTitle = txt
	end)

	local iFont = 1
	local function CreateFont(font, size, weight, italic, additive, blursize)
		surface.CreateFont(tag .. "_" .. iFont, {
			font = font,
			size = size,
			weight = weight,
			italic = italic,
			additive = additive
		})

		surface.CreateFont(tag .. "_" .. iFont .. "_blur", {
			font = font,
			size = size,
			weight = weight,
			italic = italic,
			blursize = blursize,
			additive = false,
		})

		iFont = iFont + 1
	end

	CreateFont("Roboto", 128, 880, false, false, 8)
	CreateFont("Segoe UI Light", 72, 2000, true, false, 6)

	local pos = Vector()
	local ang = Angle()
	local eyeAng = Angle()
	hook.Add("RenderScene", tag, function(pos, ang)
		eyeAng = ang
	end)

	local function DrawNameTagText(txt, font, y, color, alpha, scale, times)
		if not txt then return end
		cam.Start3D2D(pos + Vector(0, 0, 24), ang, .066 * scale)
			surface.SetFont(font)
			local txtW, txtH = surface.GetTextSize(txt)
			local brightness = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b
			local shadowColor
			if false --[[ brightness < 175 ]] then
				shadowColor = Color(255, 255, 255, 255 * alpha)
			else
				shadowColor = Color(0, 0, 0, 255 * alpha)
			end
			for i = 1, times do
				surface.SetFont(font .. "_blur")
				surface.SetTextColor(shadowColor)
				surface.SetTextPos(-txtW / 2 - 1, 128 * y)
				surface.DrawText(txt)
			end

			surface.SetFont(font)
			surface.SetTextPos(-txtW / 2, 128 * y)
			surface.SetTextColor(Color(color.r, color.g, color.b, 255 * alpha))
			surface.DrawText(txt)
		cam.End3D2D()
	end

	local drawablesData = {}

	local big = 2^16

	local maxRange = 192
	local fadeSpeed = 10
	local nametags_draw_localplayer = CreateClientConVar("cl_nametags_drawlocalplayer", "1", true, false)
	hook.Add("PostDrawTranslucentRenderables", tag, function()
		local lPly = LocalPlayer()
		for _, ply in next, player.GetAll() do
			if not drawablesData[ply:EntIndex()] then drawablesData[ply:EntIndex()] = { coneAlpha = 1 } end
			local isLPly = ply:EntIndex() == lPly:EntIndex()

			local dist = ply:GetPos():Distance(lPly:GetPos())
			local alpha = 1
			local distAlpha = 1
			local data = drawablesData[ply:EntIndex()]
			local dir = 0.95
			local vec1 = ply:GetShootPos() - lPly:GetShootPos()
			local looking = lPly:GetAimVector():Dot(vec1:GetNormalized())
			if looking > dir then 
				if dist <= 64 then
					distAlpha = math.max(0, math.TimeFraction(32, 64, dist))
				elseif dist >= maxRange then
					distAlpha = math.max(0, 1 - math.TimeFraction(maxRange, maxRange + 64, dist))
				end
				data.coneAlpha = Lerp(FrameTime() * fadeSpeed, data.coneAlpha, 1)
			else
				data.coneAlpha = Lerp(FrameTime() * fadeSpeed, data.coneAlpha, 0)
			end
			if not ply:Alive() then
				data.coneAlpha = 1
			end
			alpha = data.coneAlpha * distAlpha
			if nametags_draw_localplayer:GetBool() and isLPly and lPly:ShouldDrawLocalPlayer() then alpha = 1 end
		
			if alpha == 0 then continue end

			local mins, maxs = ply:GetModelBounds()
			local plyEnt
			if IsValid(ply:GetRagdollEntity()) and not ply:Alive() then
				plyEnt = ply:GetRagdollEntity()
			else
				plyEnt = ply
			end

			local eyes = plyEnt:GetAttachment(ply:LookupAttachment("eyes"))
			if not eyes then continue end

			pos = eyes.Pos
			ang = Angle()
			ang.p = eyeAng.p
			ang.r = eyeAng.r
			ang.y = eyeAng.y
			ang:RotateAroundAxis(ang:Up(), -90)
			ang:RotateAroundAxis(ang:Forward(), 90)
			
			local Y = 0

			if ply:getDarkRPVar("HasGunlicense") then
				Y = Y - 0.5
			end

			if ply:getDarkRPVar("wanted") then
				Y = Y - 1.5	
				DrawNameTagText("WANTED!", tag .. "_1", Y, Color(255, 64, 64), alpha, .75, 2)

				Y = Y + 0.85
				DrawNameTagText("for: " .. ply:getDarkRPVar("wantedReason"), tag .. "_2", Y, color_white, alpha, .75, 3)
				
				Y = Y + (1.5 - 0.85)
			end

			local nick = ply:Nick()
			nick = string.gsub(nick, "<(.+)=(.+)>", "")
			DrawNameTagText(nick, tag .. "_1", Y, team.GetColor(ply:Team()), alpha, .75, 2)

			local title = ply:GetCustomTitle()
			if title ~= "" then
				Y = Y + 1
				DrawNameTagText(ply:GetCustomTitle(), tag .. "_2", Y, color_white, alpha, .75, 3)	
			else
				Y = Y + 0.5
			end

			Y = Y + 0.5

			local str = "Healthy"
			local color = Color(64, 255, 64)
			local health = ply:Health()
			local armor = ply:Armor()

			if health >= big then
				str = "IMMORTAL"
				color = Color(220, 220, 64)
			elseif health >= 80 and armor >= 50 then
				str = "Heavily Armoured"
				color = Color(100, 225, 255)
			elseif health >= 80 and armor >= 20 then
				str = "Armoured"
				color = Color(100, 255, 220)
			elseif health >= 150 then
				str = "Strong"
				color = Color(100, 255, 130)
			elseif health <= 0 then
				str = "Dead"
				color = Color(255, 64, 64)
			elseif health >= 1 and health <= 25 then
				str = "Near death"
				color = Color(255, 127, 64)
			elseif health >= 26 and health <= 50 then
				str = "Badly wounded"
				color = Color(255, 255, 64)
			elseif health >= 51 and health <= 75 then
				str = "Wounded"
				color = Color(127, 255, 64)
			end
			DrawNameTagText(str, tag .. "_2", Y, color, alpha, .75, 3)
			
			Y = Y + 0.5
			DrawNameTagText(ply:getDarkRPVar("job"), tag .. "_2", Y, color_white, alpha, .75, 3)

			if ply:getDarkRPVar("HasGunlicense") then
				Y = Y + 0.5
				DrawNameTagText("Has a gun license", tag .. "_2", Y, Color(255, 127, 64), alpha, .75, 3)
			end
		end
	end)
end
