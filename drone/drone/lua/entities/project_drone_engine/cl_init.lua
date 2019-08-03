

include("shared.lua")

function ENT:Draw()

	-- self.Entity:DrawModel()
	
	-- self:Display()
	
end

function ENT:Display()

	local pos = self.Entity:GetPos()
	local ang = self.Entity:GetAngles()
	
	local ang_y = EyeAngles().y - 90
	local ang_x = ang.x
	local ang_z = ang.z
	local display_ang = Angle(ang_x, ang_y, ang_z + 60)
	
	cam.Start3D2D(pos + Vector(0, 0, 136), display_ang, 0.4)
		draw.SimpleText(self:GetForceNum(), "DermaDefaultBold", 0, 0, Color(255, 255, 255, 255), 1, 1)
	cam.End3D2D()
	
	local td = {}
		td.start = pos + self.Entity:GetUp() * 32
		td.endpos = pos + self.Entity:GetUp() * 128
		td.filter = { self.Entity  }
	local tr = util.TraceLine(td)
	
	render.SetMaterial(Material("cable/blue"))
	render.DrawBeam(pos, tr.HitPos, 1, 0, 1, Color(255, 255, 255, 255))
	
end

