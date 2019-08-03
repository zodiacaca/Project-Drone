

local bodyMat = Material( "hud/pjt_drn_body" )
local bodyLMat = Material( "hud/pjt_drn_body_left" )
local bodyBMat = Material( "hud/pjt_drn_body_back" )
local meter2Mat = Material( "hud/pjt_drn_meter2" )
local blockGMat = Material( "hud/pjt_drn_block_g" )
local blockRMat = Material( "hud/pjt_drn_block_r" )
local cameraMat = Material( "hud/pjt_drn_camera" )
local vectorMat = Material( "hud/pjt_drn_vector" )
local positionMat = Material( "hud/pjt_drn_position" )
local screenMat = Material( "hud/pjt_drn_screen" )
local statMat = Material( "hud/pjt_drn_status" )
local interfaceMat = Material( "hud/pjt_drn_interface" )
local pointerZMat = Material( "hud/pjt_drn_z" )
local pointerAngZMat = Material( "hud/pjt_drn_za" )
local pointerAngXMat = Material( "hud/pjt_drn_xa" )
local camHUDMat = Material( "hud/pjt_drn_cam" )
local frame1Mat = Material( "hud/pjt_drn_frame1" )
local ampMat = Material( "hud/pjt_drn_amplitude" )
local ampInvertMat = Material( "hud/pjt_drn_amplitude_invert" )
local vcMat = Material( "hud/pjt_drn_vc" )
local vcTextMat = Material( "hud/pjt_drn_vc_text" )
local vcBackgroundMat = Material( "hud/pjt_drn_vc_bg" )
local vcConfirmMat = Material( "hud/pjt_drn_vc_confirm" )

local camRT
local att = 1

local nextVC = 0

-- functions
local pjt_drn_hud_interface
local pjt_drn_hud_body
local pjt_drn_hud_engine
local pjt_drn_hud_batterie
local pjt_drn_hud_meter
local pjt_drn_hud_altitude
local pjt_drn_hud_speed
local pjt_drn_hud_direction
local pjt_drn_hud_position
local pjt_drn_hud_status
local pjt_drn_hud_screen
local pjt_drn_hud_voice
local vcToServer


local volume = {}
local length = 100
local sect = 1

for i = 1, length do

	volume[i] = 0
	
end

local n = 1
nextUpdateVol = CurTime()


local statTable = {
	[1] = "BalancingAng",
	[2] = "BalancingAngVel",
	[3] = "Proceeding",
	[4] = "Anti-AngVel",
	[5] = "Anti-Vel",
	[6] = "Manual",
	[7] = "Idle"
}


local function project_drone_hud()

	for k, v in pairs(ents.GetAll()) do

		if v:GetClass() == "project_drone" then

			local angZ = v:GetAngles().z
			angZ = math.Round(angZ, 3)
			local angVelZ = v:GetAngVelZ()
			angVelZ = math.Round(angVelZ, 3)

			local angX = v:GetAttachment(2).Ang.z
			angX = math.Round(angX, 3)
			local angVelX = v:GetAngVelX()
			angVelX = math.Round(angVelX, 3)
			
			local VelX = v:GetVelX()
			VelX = math.Round(VelX, 3)
			
			local VelY = v:GetVelY()
			VelY = math.Round(VelY, 3)
			
			local altitude = v:GetAltitude()
			local height = v:GetHeightValue()
			local offset = v:GetTemporaryOffset()
			local batterie = v:GetBatterie()
			local newPositon = v:GetNewPosition() or Vector(0, 0, 0)
			local lwstat = v:GetLWStat()
			local tvstat = v:GetTVStat()
			local owner = v:GetEntOwner() and Entity(v:GetEntOwner()) or nil
			local angY = owner:InVehicle() and owner:GetVehicle():WorldToLocalAngles( v:GetAngles() ).y - 90 or v:GetAngles().y

			-- // interface, light, target
			pjt_drn_hud_interface()

			-- // body frame
			pjt_drn_hud_body(v)

			-- // engine value
			pjt_drn_hud_engine(v)

			-- // batterie
			pjt_drn_hud_batterie(batterie)
			
			-- // meter
			pjt_drn_hud_meter(angZ, angVelZ, angX, angVelX)

			-- // altitude
			pjt_drn_hud_altitude(altitude, height, offset)

			-- // speed, weapon, defence
			pjt_drn_hud_speed(v, VelX, VelY, owner)

			-- // direction
			pjt_drn_hud_direction(angY, owner)
			
			-- // distance
			pjt_drn_hud_position(v, angY, owner, newPositon)
			
			-- // status
			pjt_drn_hud_status(lwstat, tvstat)
			
			-- // screen
			pjt_drn_hud_screen(v)
			
			-- // voice
			pjt_drn_hud_voice(v)
			
			-- // misc
			-- surface.SetDrawColor( 255, 255, 255, 150 )
			-- surface.SetMaterial( frame1Mat )
			-- surface.DrawTexturedRect( 332, 500, 256, 280 )
			
		end
		
	end
	
end
hook.Add("HUDPaint", "project_drone_hud", project_drone_hud)

pjt_drn_hud_interface = function()

	local x, y = ScrW()/2 - 400, ScrH()/2 - 200
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetMaterial( interfaceMat )
	surface.DrawTexturedRectUV( x, y, 800, 600, 0, 0.25, 1, 1 )
	-- surface.DrawTexturedRectUV( x, y - 48, 800, 200, 0, 0, 1, 0.25 )

	draw.SimpleText("Unknown", "pjt_drn_BankGothic", x + 176, y + 107, Color(255, 255, 255, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

end

pjt_drn_hud_body = function(v)

	local x, y = 60, 60
	
	local f_fraction = v:GetFrontFraction()
	local b_fraction = v:GetBackFraction()
	local l_fraction = v:GetLeftFraction()
	local r_fraction = v:GetRightFraction()

	surface.SetDrawColor( 0, 0, 0, 150 )
	surface.DrawRect( x - 8, y - 8, 400, 400 )

	surface.SetDrawColor( 255, 255, 255, 220 )
	surface.SetMaterial( bodyMat )
	surface.DrawTexturedRect( x, y, 384, 384 )

		-- block
		if f_fraction < 0.5 then
			local flicker = math.Clamp(1/f_fraction, 4, 8)
			surface.SetDrawColor( 255, 255, 255, 200 * math.sin(CurTime() * flicker) )
			surface.SetMaterial( blockRMat )
		else
			surface.SetDrawColor( 255, 255, 255, 200 )
			surface.SetMaterial( blockGMat )
		end
		surface.DrawTexturedRect( x + 94, y - 74, 196, 164 )

		if b_fraction < 0.5 then
			local flicker = math.Clamp(1/b_fraction, 4, 8)
			surface.SetDrawColor( 255, 255, 255, 200 * math.sin(CurTime() * flicker) )
			surface.SetMaterial( blockRMat )
		else
			surface.SetDrawColor( 255, 255, 255, 200 )
			surface.SetMaterial( blockGMat )
		end
		surface.DrawTexturedRectRotated( x + 190, y + 376, 196, 164, 180 )

		if l_fraction < 0.5 then
			local flicker = math.Clamp(1/l_fraction, 4, 8)
			surface.SetDrawColor( 255, 255, 255, 200 * math.sin(CurTime() * flicker) )
			surface.SetMaterial( blockRMat )
		else
			surface.SetDrawColor( 255, 255, 255, 200 )
			surface.SetMaterial( blockGMat )
		end
		surface.DrawTexturedRectRotated( x + 28, y + 192, 196, 164, 90 )

		if r_fraction < 0.5 then
			local flicker = math.Clamp(1/r_fraction, 4, 8)
			surface.SetDrawColor( 255, 255, 255, 200 * math.sin(CurTime() * flicker) )
			surface.SetMaterial( blockRMat )
		else
			surface.SetDrawColor( 255, 255, 255, 200 )
			surface.SetMaterial( blockGMat )
		end
		surface.DrawTexturedRectRotated( x + 355, y + 191, 196, 164, -90 )

		-- camera
		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.SetMaterial( cameraMat )
		surface.DrawTexturedRectRotated( x + 192, y + 172, 196, 164, 0 )
		-- surface.DrawTexturedRectRotated( x + 190, y + 172, 196, 164, 180 )

		-- right
		surface.SetDrawColor( 0, 0, 0, 150 )
		surface.DrawRect( x + 400, y - 8, 320, 124 )
		surface.SetDrawColor( 255, 255, 255, 220 )
		surface.SetMaterial( bodyLMat )
		surface.DrawTexturedRect( x + 400, y - 120, 320, 320 )
		
		local dir = v:GetScanDirection()
		local pos = v:GetScanPosition()
		if f_fraction < 0.1 then
			surface.SetDrawColor( 255, 0, 0, 80 * (math.sin(CurTime() * 12) + 1))
			surface.DrawRect( x + 400, y + 42 + pos * 0.7, 8, 4 )
		elseif l_fraction < 0.1 then
			surface.SetDrawColor( 255, 0, 0, 80 * (math.sin(CurTime() * 12) + 1))
			surface.DrawRect( x + 730, y + 42 + pos * 0.7, 8, 4 )
		elseif r_fraction < 0.1 then
			surface.SetDrawColor( 255, 0, 0, 80 * (math.sin(CurTime() * 12) + 1))
			surface.DrawRect( x + 730 + 272, y + 42 + pos * 0.7, 8, 4 )
		end
		
		-- back
		surface.SetDrawColor( 0, 0, 0, 150 )
		surface.DrawRect( x + 730, y - 8, 280, 124 )
		surface.SetDrawColor( 255, 255, 255, 220 )
		surface.SetMaterial( bodyBMat )
		surface.DrawTexturedRect( x + 720, y - 98, 300, 300 )

end

pjt_drn_hud_engine = function(v)

	local x, y = 60, 60
	
	local e = {}
	e[1] = math.Round(v:GetEngine1Value(), 3)
	e[2] = math.Round(v:GetEngine2Value(), 3)
	e[3] = math.Round(v:GetEngine3Value(), 3)
	e[4] = math.Round(v:GetEngine4Value(), 3)

	draw.SimpleTextOutlined("1:  "..e[1], "DermaLarge", x + 25, y + 50, Color(200, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))
	draw.SimpleTextOutlined("2:  "..e[2], "DermaLarge", x + 230, y + 50, Color(200, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))
	draw.SimpleTextOutlined("3:  "..e[3], "DermaLarge", x + 25, y + 300, Color(200, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))
	draw.SimpleTextOutlined("4:  "..e[4], "DermaLarge", x + 230, y + 300, Color(200, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))

		-- visualize
		local back_value = (e[3] + e[4])/2 - 235
		if back_value < -50 then
			surface.SetDrawColor( 255, 0, 0, 80 )
			surface.DrawLine(x + 442 + 118, y - 6, x + 442 + 118 + 117, y - 6)
		elseif back_value > 50 then
			surface.SetDrawColor( 255, 0, 0, 80 )
			surface.DrawLine(x + 442 + 118, y - 6 + 100, x + 442 + 118 + 117, y - 6 + 100)
		end
		back_value = math.Clamp(back_value, -50, 50)
		surface.SetDrawColor( 0, 255, 0, 80 )
		if back_value < 0 then
			surface.DrawRect( x + 559, y + 44 + back_value, 117, -back_value )
		else
			surface.DrawRect( x + 559, y + 44, 117, back_value )
		end
		
		local front_value = (e[1] + e[1])/2 - 235
		if front_value < -50 then
			surface.SetDrawColor( 255, 0, 0, 80 )
			surface.DrawLine(x + 442, y - 6, x + 442 + 117, y - 6)
		elseif front_value > 50 then
			surface.SetDrawColor( 255, 0, 0, 80 )
			surface.DrawLine(x + 442, y - 6 + 100, x + 442 + 117, y - 6 + 100)
		end
		front_value = math.Clamp(front_value, -50, 50)
		surface.SetDrawColor( 0, 255, 0, 80 )
		if front_value < 0 then
			surface.DrawRect( x + 442, y + 44 + front_value, 117, -front_value )
		else
			surface.DrawRect( x + 442, y + 44, 117, front_value )
		end

		local left_value = (e[1] + e[3])/2 - 235
		if left_value < -50 then
			surface.SetDrawColor( 255, 0, 0, 80 )
			surface.DrawLine(x + 778, y - 6, x + 778 + 92, y - 6)
		elseif left_value > 50 then
			surface.SetDrawColor( 255, 0, 0, 80 )
			surface.DrawLine(x + 778, y - 6 + 100, x + 778 + 92, y - 6 + 100)
		end
		left_value = math.Clamp(left_value, -50, 50)
		surface.SetDrawColor( 0, 255, 0, 80 )
		if left_value < 0 then
			surface.DrawRect( x + 778, y + 44 + left_value, 92, -left_value )
		else
			surface.DrawRect( x + 778, y + 44, 92, left_value )
		end

		local right_value = (e[2] + e[4])/2 - 235
		if right_value < -50 then
			surface.SetDrawColor( 255, 0, 0, 80 )
			surface.DrawLine(x + 93 + 778, y - 6, x + 93 + 778 + 92, y - 6)
		elseif right_value > 50 then
			surface.SetDrawColor( 255, 0, 0, 80 )
			surface.DrawLine(x + 93 + 778, y - 6 + 100, x + 93 + 778 + 92, y - 6 + 100)
		end
		right_value = math.Clamp(right_value, -50, 50)
		surface.SetDrawColor( 0, 255, 0, 80 )
		if right_value < 0 then
			surface.DrawRect( x + 870, y + 44 + right_value, 92, -right_value )
		else
			surface.DrawRect( x + 870, y + 44, 92, right_value )
		end
		
		local frontEngAng = v:GetFrontEngineAngle()
		frontEngAng = (math.abs(frontEngAng) >= 0.5) and frontEngAng or 0
		surface.SetDrawColor( 255, 90, 0, 255 )
		
		surface.DrawLine(x + 787, y - 6 + 48, x + 787 + 32, y - 6 + 48 + frontEngAng)
		surface.DrawLine(x + 787 - 32, y - 6 + 48 - frontEngAng, x + 787, y - 6 + 48)
		
		surface.DrawLine(x + 93 + 860, y - 6 + 48, x + 93 + 860 + 32, y - 6 + 48 + frontEngAng)
		surface.DrawLine(x + 93 + 860 - 32, y - 6 + 48 - frontEngAng, x + 93 + 860, y - 6 + 48)

end

pjt_drn_hud_batterie = function(batterie)

	local x, y = 160, ScrH() - 60
	draw.OutlinedBox( x, y, 240, 30, 2, Color( 0, 255, 0, 180 ) )
	surface.SetDrawColor( 0, 255, 0, 180 )
	surface.DrawRect( x + 2, y + 2, 236 * batterie / 10^5, 26 )
	batterie = math.Round(batterie/10^3, 1)
	draw.SimpleTextOutlined("Batterie:", "DermaLarge", x - 110, y, Color(200, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))
	draw.SimpleTextOutlined(batterie, "DermaLarge", x + 4, y, Color(200, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))

end

pjt_drn_hud_meter = function(angZ, angVelZ, angX, angVelX)

	local x, y = ScrW()/2, ScrH()/2

	-- if angX > 0 then
		-- draw.SimpleTextOutlined("X: "..angX, "DermaLarge", x, y, Color(255, 255, 100, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))
	-- else
		-- draw.SimpleTextOutlined("X: "..angX, "DermaLarge", x, y, Color(200, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))
	-- end
	-- if angVelX > 0 then
		-- draw.SimpleTextOutlined("AngVelX: "..angVelX, "DermaLarge", x + 130, y, Color(255, 255, 100, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))
	-- else
		-- draw.SimpleTextOutlined("AngVelX: "..angVelX, "DermaLarge", x + 130, y, Color(200, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))
	-- end

	-- if angZ > 0 then
		-- draw.SimpleTextOutlined("Z:"..angZ, "DermaLarge", x, y + 40, Color(255, 255, 100, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))
	-- else
		-- draw.SimpleTextOutlined("Z:"..angZ, "DermaLarge", x, y + 40, Color(200, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))
	-- end
	-- if angVelZ > 0 then
		-- draw.SimpleTextOutlined("AngVelZ: "..angVelZ, "DermaLarge", x + 130, y + 40, Color(255, 255, 100, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))
	-- else
		-- draw.SimpleTextOutlined("AngVelZ: "..angVelZ, "DermaLarge", x + 130, y + 40, Color(200, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))
	-- end
	
	angZ = math.Clamp(angZ, - 20, 20)
	angVelZ = math.Clamp(angVelZ, - 20, 20)
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetMaterial( pointerZMat )
	surface.DrawTexturedRectRotated( x, y, 800, 800, -angZ * 0.98 )

	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetMaterial( pointerAngZMat )
	surface.DrawTexturedRectRotated( x, y, 800, 800, -angVelZ * 0.98 )

	angX = math.Clamp(angX, - 20, 20)
	angVelX = math.Clamp(angVelX, - 20, 20)
	local triangle = {
		{ x = x - 298 - 4, y = y + angX * 6.4 },
		{ x = x - 298 + 8, y = y + angX * 6.4 - 3 },
		{ x = x - 298 + 8, y = y + angX * 6.4 + 3 }
	}
	surface.SetDrawColor( 255, 255, 255, 255 )
	draw.NoTexture()
	surface.DrawPoly( triangle )

	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetMaterial( pointerAngXMat )
	surface.DrawTexturedRectRotated( x, y + angVelX * 6.4, 800, 800, 0 )
	
end

pjt_drn_hud_altitude = function(altitude, height, offset)

	local x, y = ScrW() - 350, ScrH() - 230
	surface.SetDrawColor( 0, 0, 0, 180 )
	surface.DrawRect( x - 10, y - 10, 46, 220 )

	draw.OutlinedBox( x, y, 10, 200, 2, Color( 0, 255, 0, 200 ) )
	surface.SetDrawColor( 0, 255, 0, 200 )
	local percent = altitude/height
	percent = math.Clamp(percent, 0, 2)
	surface.DrawRect( x, y + 200 - 100 * percent, 8, 100 * percent )
	local triangle = {
		{ x = x + 10, y = y + 100 },
		{ x = x + 14, y = y + 100 - 4 },
		{ x = x + 14, y = y + 100 + 4 }
	}
	surface.SetDrawColor( 0, 255, 0, 200 )
	draw.NoTexture()
	surface.DrawPoly( triangle )
	draw.SimpleTextOutlined(height, "DermaDefault", x + 17, y + 94, Color(200, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 255))
	
	if offset != 0 then
		draw.OutlinedBox( x + 16, y + 95, 20, 13, 1, Color( 255, 0, 0, 255 ) )
	end
	
end

pjt_drn_hud_speed = function(v, VelX, VelY, owner)

	local x1, y1 = ScrW()/2, ScrH()/2
	local vel = v:GetVelocity(), 0, 120

	-- draw.SimpleTextOutlined("Speed:", "DermaLarge", x1, y1 + 30, Color(200, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))
	-- draw.SimpleTextOutlined(vel:Length(), "DermaLarge", x1, y1 + 60, Color(200, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))

	surface.SetDrawColor( 0, 150, 220, 120 )
	surface.DrawRect( x1 - 224, y1 + 102, math.Clamp(vel:Length() * 1.5, 0, 200), 15 )
	
	if owner and owner:InVehicle() then
		local velOwner = owner:GetVehicle():GetVelocity(), 0, 120
		draw.OutlinedBox( x1 - 224, y1 + 102, math.Clamp(velOwner:Length() * 1.5, 0, 200), 15, 1, Color( 255, 0, 0, 180 ) )
	end

	surface.SetDrawColor( 255, 255, 0, 100 )
	surface.DrawRect( x1 + 96, y1 + 102, 120, 15 )

	surface.SetDrawColor( 0, 255, 0, 100 )
	surface.DrawRect( x1 + 96, y1 + 71, 120, 15 )
	
	local VelZ = vel * v:GetUp()
	VelZ = math.Round(VelZ.z, 3)
	
	draw.SimpleText(VelX, "pjt_drn_BankGothic", x1 - 254, y1 - 148, Color(0, 150, 220, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(VelY, "pjt_drn_BankGothic", x1 - 137, y1 - 148, Color(0, 150, 220, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(VelZ, "pjt_drn_BankGothic", x1 - 20, y1 - 148, Color(0, 150, 220, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	-- vector
	local x2, y2 = 30, 468
	local multi = 1.35
	local factor = owner:InVehicle() and 1 or 2
	surface.SetDrawColor( 0, 0, 0, 180 )
	surface.DrawRect( x2 + 18 * multi, y2 + 18 * multi, 220 * multi, 220 * multi )

	local color_vx = math.abs(VelX/factor) >= 100 and Color(255, 0, 0, 255) or Color(0, 200, 255, 200)
	local color_vy = math.abs(VelY/factor) >= 100 and Color(255, 0, 0, 255) or Color(0, 200, 255, 200)
	VelX = math.Clamp(VelX/factor, -110, 110)
	VelY = math.Clamp(VelY/factor, -110, 110)
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetMaterial( vectorMat )
	surface.DrawTexturedRect( x2, y2, 256 * multi, 256 * multi )
	local triangle1 = {
		{ x = x2 + 128 * multi - 5, y = y2 + 128 * multi - 5 - VelX * multi },
		{ x = x2 + 128 * multi, y = y2 + 128 * multi - VelX * multi },
		{ x = x2 + 128 * multi - 5, y = y2 + 128 * multi + 5 - VelX * multi }
	}
	if VelY < 0 then
		triangle1 = {
			{ x = x2 + 128 * multi, y = y2 + 128 * multi - VelX * multi },
			{ x = x2 + 128 * multi + 5, y = y2 + 128 * multi - 5 - VelX * multi },
			{ x = x2 + 128 * multi + 5, y = y2 + 128 * multi + 5 - VelX * multi }
		}
	end
	surface.SetDrawColor(color_vx)
	draw.NoTexture()
	surface.DrawPoly( triangle1 )
	local add = 0
	if (VelX < 0 and VelY > 0) then
		add = 1
	end
	surface.DrawLine( x2 + 128 * multi, y2 + 128 * multi - VelX * multi, x2 + 128 * multi + VelY * multi + add, y2 + 128 * multi - VelX * multi )
	local triangle2 = {
		{ x = x2 + 128 * multi - 5 + VelY * multi, y = y2 + 128 * multi + 5 },
		{ x = x2 + 128 * multi + VelY * multi, y = y2 + 128 * multi },
		{ x = x2 + 128 * multi + 5 + VelY * multi, y = y2 + 128 * multi + 5 }
	}
	if VelX < 0 then
		triangle2 = {
			{ x = x2 + 128 * multi + VelY * multi, y = y2 + 128 * multi },
			{ x = x2 + 128 * multi - 5 + VelY * multi, y = y2 + 128 * multi - 5 },
			{ x = x2 + 128 * multi + 5 + VelY * multi, y = y2 + 128 * multi - 5 }
		}
	end
	surface.SetDrawColor(color_vy)
	draw.NoTexture()
	surface.DrawPoly( triangle2 )
	surface.DrawLine( x2 + 128 * multi + VelY * multi, y2 + 128 * multi, x2 + 128 * multi + VelY * multi, y2 + 128 * multi - VelX * multi + add )
	
end

pjt_drn_hud_direction = function(angY, owner)

	local x, y = ScrW()/2 - 128, ScrH() - 390
	
	surface.SetDrawColor( 255, 255, 255, 200 )
	surface.SetMaterial( meter2Mat )
	surface.DrawTexturedRect( x, y, 256, 256 )
	if owner:InVehicle() then
		if angY > 30 then
			local triangle = {
				{ x = x, y = y + 130 },
				{ x = x + 5, y = y + 130 - 16 },
				{ x = x + 5, y = y + 130 + 16 }
			}
			surface.SetDrawColor( 255, 0, 0, 200 )
			draw.NoTexture()
			surface.DrawPoly( triangle )
		elseif angY < -30 then
			local triangle = {
				{ x = x + 256, y = y + 130 - 16 },
				{ x = x + 256 + 5, y = y + 130 },
				{ x = x + 256, y = y + 130 + 16 }
			}
			surface.SetDrawColor( 255, 0, 0, 200 )
			draw.NoTexture()
			surface.DrawPoly( triangle )
		else
			local triangle = {
				{ x = x + 128 - 4 - angY * 4.1, y = y + 152 },
				{ x = x + 128 - angY * 4.1, y = y + 142 },
				{ x = x + 128 + 4 - angY * 4.1, y = y + 152 }
			}
			surface.SetDrawColor( 0, 200, 255, 200 )
			draw.NoTexture()
			surface.DrawPoly( triangle )
		end
	end
	
end

pjt_drn_hud_position = function(v, angY, owner, newPositon)

	local x, y = ScrW() - 160, ScrH() - 160
	surface.SetDrawColor( 0, 0, 0, 200 )
	surface.DrawRect( x - 140, y - 140, 280, 280 )
	local pos = owner:InVehicle() and owner:GetVehicle():WorldToLocal(v:GetPos()) or v:GetPos()
	if owner:InVehicle() then
		pos = Vector(pos.y, -pos.x, 0)
	end
	pos = pos/8
	local posx = math.Round(pos.x, 3)
	local posy = math.Round(pos.y, 3)
	draw.SimpleTextOutlined("x:"..posx * 8, "pjt_drn_BankGothic", x - 134, y - 136, Color(200, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))
	draw.SimpleTextOutlined("y:"..posy * 8, "pjt_drn_BankGothic", x + 2, y - 136, Color(200, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 255))

	surface.SetDrawColor( 255, 255, 0, 100 )
	surface.DrawRect( x - 6 + newPositon.y/8, y - 3 + newPositon.x/8, 12, 4 )
	surface.DrawRect( x - 2 + newPositon.y/8, y - 7 + newPositon.x/8, 4, 12 )
	surface.SetDrawColor( 255, 255, 0, 10 )
	surface.DrawLine( x - 140, y - 2, x + 140, y - 2 )
	surface.DrawLine( x, y - 140, x, y + 140 )

	if math.abs(posx * 8) <= 1024 and math.abs(posy * 8) <= 1024 then
		surface.SetDrawColor( 255, 255, 255, 220 )
		surface.SetMaterial( positionMat )
		surface.DrawTexturedRectRotated( x - posy + 1, y - posx, 28, 28, angY )
	elseif math.abs(posx * 8) > 1024 and math.abs(posy * 8) <= 1024 then
		if posx * 8 > 1024 then
			local triangle = {
				{ x = x - 12 - posy, y = y + 3 - 136 },
				{ x = x - posy, y = y - 3 - 136 },
				{ x = x + 12 - posy, y = y + 3 - 136 }
			}
			surface.SetDrawColor( 255, 0, 0, 200 )
			draw.NoTexture()
			surface.DrawPoly( triangle )
		else
			local triangle = {
				{ x = x - posy, y = y + 3 + 136 },
				{ x = x - 12 - posy, y = y - 3 + 136 },
				{ x = x + 12 - posy, y = y - 3 + 136 }
			}
			surface.SetDrawColor( 255, 0, 0, 200 )
			draw.NoTexture()
			surface.DrawPoly( triangle )
		end
	else
		posx = math.Clamp(posx, -128, 128)
		if posy * 8 > 1024 then
			local triangle = {
				{ x = x - 3 - 136, y = y - posx },
				{ x = x + 3 - 136, y = y - 12 - posx },
				{ x = x + 3 - 136, y = y+ 12 - posx }
			}
			surface.SetDrawColor( 255, 0, 0, 200 )
			draw.NoTexture()
			surface.DrawPoly( triangle )
		else
			local triangle = {
				{ x = x - 3 + 136, y = y - 12 - posx },
				{ x = x + 3 + 136, y = y - posx },
				{ x = x - 3 + 136, y = y+ 12 - posx }
			}
			surface.SetDrawColor( 255, 0, 0, 200 )
			draw.NoTexture()
			surface.DrawPoly( triangle )
		end
	end
	
end

pjt_drn_hud_status = function(lwstat, tvstat)

	local x, y = ScrW()/2 - 300, ScrH() - 260
	-- surface.SetDrawColor( 0, 0, 0, 150 )
	-- surface.DrawRect( x + 50, y + 110, 650, 180 )
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetMaterial( statMat )
	surface.DrawTexturedRectUV( x, y, 700, 350, 0, 0, 1, 0.5 )
	local lw = table.KeyFromValue( statTable, lwstat )
	if lw <= 2 then
		lw = 2
	end
	lw = lw == 7 and 1 or lw
	local tv = table.KeyFromValue( statTable, tvstat )
	if tv <= 2 then
		tv = 2
	end
	tv = tv == 7 and 1 or tv
	surface.DrawTexturedRectUV( x + 58 + (lw - 1) * 73, y - 46, 350, 350, 0.5, 0.5, 1, 1 )
	surface.DrawTexturedRectUV( x + 58 + (tv - 1) * 73, y + 12, 350, 350, 0.5, 0.5, 1, 1 )
	
end

pjt_drn_hud_screen = function(v)

	local mat = Material("models/project_drone/screen")
	local x0, y0 = ScrW(), ScrH()
	local x, y = ScrW() - 460, 70
	local In = true

	local old = render.GetRenderTarget()
	
	local p, a = v:GetAttachment(att).Pos, v:GetAttachment(att).Ang
	p = p - v:GetUp() * 8

	local CamData = {}
		CamData.x = 0
		CamData.y = 0
		CamData.w = 512
		CamData.h = 512
		CamData.type = "2D"
		CamData.origin = p
		CamData.angles = a

	camRT = GetRenderTarget("project_drone_rt", 512, 512, true)

	//-------- start rt
	render.SetRenderTarget(camRT)
	render.Clear( 0, 0, 0, 255 )
	render.SetViewPort(0, 0, 512, 512)
	if In then
		render.RenderView(CamData)
		In = false
	end
	
	//-------- back to normal screen
	render.SetRenderTarget(old)
	render.SetViewPort(0, 0, x0, y0)

	mat:SetTexture("$basetexture", camRT)

	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetMaterial( mat )
	surface.DrawTexturedRectUV( x, y, 400, 225, 0, 0.21875, 1, 0.78125 )
	
	surface.SetDrawColor( 255, 255, 255, 150 )
	surface.SetMaterial( camHUDMat )
	surface.DrawTexturedRect( x + 40, y - 40, 320, 320 )
	
	draw.SimpleText("1 x", "Default", x + 139, y + 62, Color(255, 255, 255, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	local getColor = render.GetSurfaceColor( v:GetPos() - v:GetUp() * 8, v:GetPos() - v:GetUp() * 8 + v:GetForward() * 33000 )
	draw.SimpleText(math.Round(getColor.x, 3), "Default", x + 222, y + 155, Color(255, 255, 255, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(math.Round(getColor.y, 3), "Default", x + 252, y + 155, Color(255, 255, 255, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(math.Round(getColor.z, 3), "Default", x + 282, y + 155, Color(255, 255, 255, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetMaterial( screenMat )
	surface.DrawTexturedRect( x - 55, y - 142, 510, 510 )

end

pjt_drn_hud_voice = function(v)

	local x, y = ScrW() - 360, 460
	local amp = 50
	
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetMaterial( vcBackgroundMat )
	surface.DrawTexturedRect(x - 30, y - 138, 360, 360)
	
	surface.SetDrawColor( 255, 255, 255, 150 )
	for i = 1, length do
		local pos = n - i - 1 >= 0 and n - i - 1 or n - i - 1 + 100
		surface.SetMaterial( ampMat )
		surface.DrawTexturedRect(x + 3 * pos, y - volume[i] + 1, 3, volume[i])
		surface.SetMaterial( ampInvertMat )
		surface.DrawTexturedRect(x + 3 * pos, y + 1, 3, volume[i])
		surface.SetDrawColor( 0, 65, 255, 120 )
		surface.DrawLine( x, y, x + 3 * length, y )
	end
	if CurTime() > nextUpdateVol then
		if CurTime() > nextVC then
			volume[n] = LocalPlayer():VoiceVolume() * amp
		else
			for i = 1, 100 do
				volume[i] = 0
			end
		end
		if n == 100 then
			n = 1
			for i = 1, 100 do
				volume[i] = 0
			end
		else
			n = n + 1
		end
		nextUpdateVol = CurTime() + 0.02
	end
	
	surface.SetDrawColor( 255, 255, 255, 150 )
	surface.SetMaterial( vcMat )
	surface.DrawTexturedRect(x - 30, y - 138, 360, 360)
	
	surface.SetMaterial( vcTextMat )
	if LocalPlayer():KeyDown(IN_WALK) then
		surface.DrawTexturedRectUV(x - 30, y - 110, 360, 72, 0, 0.2, 1, 0.4 )
	else
		surface.DrawTexturedRectUV(x - 30, y - 137, 360, 72, 0, 0, 1, 0.2 )
	end
	
	surface.SetDrawColor( 255, 0, 0, 150 )
	surface.DrawLine(x + 3 * n, y - 67, x + 3 * n, y + 70)
	
	local section = { false, false, false, false, false }
	for i = 1, 5 do
		local count = 0
		for n = (i - 1) * 20 + 1, i * 20 do
			if volume[n] > 5 then
				count = count + 1
			end
		end
		if count >= 3 then
			section[i] = true
		end
	end
	
	if LocalPlayer():KeyDown(IN_WALK) then
		if section[1] and section[2] then
			vcToServer("left")
			sect = 1
			v:EmitSound("buttons/button24.wav", 150)
		elseif section[1] and section[3] then
			vcToServer("right")
			sect = 2
			v:EmitSound("buttons/button24.wav", 150)
		elseif section[1] and section[4] then
			att = 1
			nextVC = CurTime() + 1
			sect = 3
			v:EmitSound("buttons/button24.wav", 150)
		elseif section[1] and section[5] then
			att = 7
			nextVC = CurTime() + 1
			sect = 4
			v:EmitSound("buttons/button24.wav", 150)
		end
	else
		if section[1] and section[2] then
			vcToServer("forward")
			sect = 1
			v:EmitSound("buttons/button24.wav", 150)
		elseif section[1] and section[3] then
			vcToServer("back")
			sect = 2
			v:EmitSound("buttons/button24.wav", 150)
		elseif section[1] and section[4] then
			vcToServer("up")
			sect = 3
			v:EmitSound("buttons/button24.wav", 150)
		elseif section[1] and section[5] then
			vcToServer("down")
			sect = 4
			v:EmitSound("buttons/button24.wav", 150)
		end
	end
	
	if CurTime() - nextVC < 0 then
		surface.SetDrawColor( 255, 255, 255, 255 * math.sin(CurTime() * 45) )
		surface.SetMaterial( vcConfirmMat )
		surface.DrawTexturedRect(x - 30 + (sect - 1) * 54, y - 138, 360, 360)
	end
	
end

vcToServer = function( str )

	net.Start( "pjt_drn_vc" )
		net.WriteString( str )
	net.SendToServer()
	
	nextVC = CurTime() + 1

end

function draw.OutlinedBox( x, y, w, h, thickness, color )

	surface.SetDrawColor( color )
	for i = 0, thickness - 1 do
		surface.DrawOutlinedRect( x + i, y + i, w - i * 2, h - i * 2 )
	end
	
end


local hide = {
	CHudHealth = true,
	CHudBattery = true,
}

hook.Add( "HUDShouldDraw", "pjt_drn_HideHUD", function( name )

	if ( hide[ name ] ) then return false end

	-- Don't return anything here, it may break other addons that rely on this hook.
end )

