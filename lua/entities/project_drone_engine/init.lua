

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")


function ENT:Initialize()

	self.Entity:SetModel("models/hunter/blocks/cube025x025x025.mdl")
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	self.Entity:DrawShadow(false)
	-- self.Entity:SetCollisionGroup(COLLISION_GROUP_NONE)

	local phys = self.Entity:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
	end

end

function ENT:SetForce(value)

	self.Force = value
	
end

function ENT:PhysicsUpdate(phys)

	if self.Force != nil then
		local engAng = self.Entity:GetAngles()
		local rotateAng = self.RotateAngle
		engAng:RotateAroundAxis(self.Entity:GetForward(), rotateAng)
		local up = engAng:Up()
		phys:ApplyForceCenter( up * self.Force )
		self:SetForceNum(self.Force)
	end

end

function ENT:Think()

	local pitch = self.Force or 1

	if self.LoopSound then
		if pitch == 0 then
			self.LoopSound:ChangeVolume(0, 0.5)
			self.LoopSound:ChangePitch( 50 * GetConVarNumber("host_timescale") )
		else
			self.LoopSound:ChangeVolume(0.5, 0)
			self.LoopSound:ChangePitch( 100 * GetConVarNumber("host_timescale") * 1 + math.Clamp((pitch - 250)/10, -0.2, 0.2) )
		end
	else
		self.LoopSound = CreateSound(self.Entity, Sound("project_drone/motor.wav"))
		self.LoopSound:Play()
	end
	
	self.Entity:NextThink(CurTime())
	
	return true
	
end

function ENT:Use(activator)
end

function ENT:OnRemove()

	if self.LoopSound then
		self.LoopSound:Stop()
		self.LoopSound = nil
	end
	
end

