

surface.CreateFont( "pjt_drn_BankGothic", {
	font = "BankGothic Md BT",
	extended = false,
	size = 20,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

include("shared.lua")

local matFlareR = Material( "sprites/drn_flare_r" )
local matFlareG = Material( "sprites/drn_flare_g" )

function ENT:Draw()

	self.Entity:DrawModel()
	
	-- self:Display()
	-- self:Scan()
	self:Operate()
	self:Indicator()
	
end

function ENT:Indicator()

	local size = 1
	local forward = self.Entity:GetForward()
	local up = self.Entity:GetUp()
	local mA = self.Entity:GetBoneMatrix( 4 )
	local posA = mA:GetTranslation()
	local mB = self.Entity:GetBoneMatrix( 2 )
	local posB = mB:GetTranslation()
	local mC = self.Entity:GetBoneMatrix( 0 )
	local posC = mC:GetTranslation()
	render.SetColorMaterial()
	render.DrawBox( posA - Vector(0, 0, 4), self.Entity:GetAngles(), Vector(-size, -size, -size), Vector(size, 2 * size, size), Color( 255, 0, 0, 255 * math.sin(CurTime() * 4) ) )
	render.DrawBox( posB - Vector(0, 0, 4), self.Entity:GetAngles(), Vector(-size, -2 * size, -size), Vector(size, size, size), Color( 255, 0, 0, 255 ) )
	render.DrawBox( posC - forward * 6 - up * 5,self.Entity:GetAngles(), Vector(-size, -size, -size), Vector(size, size, size), Color( 0, 255, 0, 255 ) )
	
end

function ENT:Operate()

	if util.NetworkStringToID( "pjt_drn" ) != 0 then
	
		net.Start("pjt_drn")
			net.WriteBool(input.IsKeyDown( KEY_PAD_8 ))
			net.WriteBool(input.IsKeyDown( KEY_PAD_2 ))
			net.WriteBool(input.IsKeyDown( KEY_PAD_4 ))
			net.WriteBool(input.IsKeyDown( KEY_PAD_6 ))
			net.WriteBool(input.IsKeyDown( KEY_PAD_7 ))
			net.WriteBool(input.IsKeyDown( KEY_PAD_9 ))
		net.SendToServer()
		
	end
	
end

local scan = 0
local flip = 1

function ENT:Scan()

	scan = scan + flip
	if scan >= 64 then
		flip = -1
	elseif scan <= -64 then
		flip = 1
	end
	
	local pos = self.Entity:GetPos()
	local ang = self.Entity:GetAngles()
	local detDir = 0
	if self:GetLeftFraction() < 0.08 then
		detDir = 90
	elseif self:GetRightFraction() < 0.08 then
		detDir = -90
	end
	
	ang:RotateAroundAxis(self.Entity:GetUp(), detDir)
	local dir = ang:Forward()

	local td = {}
		td.start = pos
		td.endpos = pos + dir * 64 + self.Entity:GetUp() * scan
		td.filter = { self.Entity  }
	local tr = util.TraceLine(td)
	
	render.SetMaterial(Material("cable/red"))
	render.DrawBeam(pos, tr.HitPos, 1, 0, 1, Color(255, 255, 255, 255))
	
end

function ENT:Display()

	local pos = self.Entity:GetPos()
	local ang = self.Entity:GetAngles()
	
	local ang_y = EyeAngles().y - 90
	local ang_x = ang.x
	local ang_z = ang.z
	local display_ang = Angle(ang_x, ang_y, ang_z + 60)
	
	-- cam.Start3D2D(pos + Vector(0, 0, 32), display_ang, 0.4)
		-- draw.SimpleText(self.Entity:GetAngles(), "DermaDefaultBold", 0, 0, Color(255, 255, 255, 255), 1, 1)
	-- cam.End3D2D()
	
	local td = {}
		td.start = pos + self.Entity:GetForward() * 32
		td.endpos = pos + self.Entity:GetForward() * 128
		td.filter = { self.Entity  }
	local tr = util.TraceLine(td)
	
	render.SetMaterial(Material("cable/red"))
	render.DrawBeam(pos, tr.HitPos, 1, 0, 1, Color(255, 255, 255, 255))
	
	local td2 = {}
		td2.start = pos + self.Entity:GetUp() * 32
		td2.endpos = pos + self.Entity:GetUp() * 128
		td2.filter = { self.Entity  }
	local tr2 = util.TraceLine(td2)
	
	render.SetMaterial(Material("cable/blue"))
	render.DrawBeam(pos, tr2.HitPos, 1, 0, 1, Color(255, 255, 255, 255))
	
	local td3 = {}
		td3.start = pos + self.Entity:GetRight() * 32
		td3.endpos = pos + self.Entity:GetRight() * 128
		td3.filter = { self.Entity }
	local tr3 = util.TraceLine(td3)
	
	render.SetMaterial(Material("cable/green"))
	render.DrawBeam(pos, tr3.HitPos, 1, 0, 1, Color(255, 255, 255, 255))
	
end

