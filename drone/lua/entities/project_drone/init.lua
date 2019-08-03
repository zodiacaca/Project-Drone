

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:SpawnFunction( ply, tr )

	if ( !tr.Hit ) then return end

	local SpawnPos = tr.HitPos + Vector(0, 0, 16)
	local SpawnAng = Angle(0, 0, 0)

	local ent = ents.Create( "project_drone" )
	ent:SetCreator( ply )
	ent:SetPos( SpawnPos )
	ent:SetAngles( SpawnAng )
	ent:Spawn()
	ent:Activate()

	ent:DropToFloor()

	return ent

end

function ENT:Initialize()

	self.Entity:SetModel("models/project_drone/drone001.mdl")
	self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
	self.Entity:SetSolid(SOLID_VPHYSICS)
	self.Entity:DrawShadow(true)
	self.Entity:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	local phys = self.Entity:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
	end

	util.AddNetworkString( "pjt_drn" )
	util.AddNetworkString( "pjt_drn_vc" )

	self.Height = 96
	self.StartTime = CurTime()
	self.Engine = {}
	self:DeployEngines()
	self.Batterie = 10^5
	self.Lengthwise = "Idle"
	self.Transverse = "Idle"

	self.UpDown = false
	self.DownDown = false
	self.LeftDown = false
	self.RightDown = false
	
	self.Scan = 0
	self.NextAvoid = 0
	
	self.ConfluencePosition = Vector(0, 0, 0)
	self.TemporaryOffset = 0
	
	self.CalculatePosition = false
	self.ControledPos = self.Entity:GetPos()

	self.Owner = self.Entity:GetCreator()
	self.Entity:SetUseType(SIMPLE_USE)
	
	game.ConsoleCommand( "voice_loopback 1\n" )

end

function ENT:DeployEngines()

	local pos = self.Entity:GetPos()
	local ang = self.Entity:GetAngles()

	for i = 1, 4 do
		self.Engine[i] = {}
		self.Engine[i].Ent = ents.Create( "project_drone_engine" )
		if ( IsValid( self.Engine[i].Ent ) ) then
			local att = self.Entity:LookupAttachment( "engine"..i )
			local pos = self.Entity:GetAttachment( att ).Pos
			self.Engine[i].Ent:SetPos( pos )
			self.Engine[i].Ent:SetAngles( self.Entity:GetAngles() )
			self.Engine[i].Ent.RotateAngle = 0
			self.Engine[i].Ent:Spawn()
			self.Engine[i].Ent:Activate()
		end
		constraint.Weld( self.Engine[i].Ent, self.Entity, 0, 0, 0, true, true )
	end

end

function ENT:ClampForce(delta, from, to)

	result= from + math.Clamp(to - from, -delta, delta)

	return result

end

local Height, dHeight = 0, 0
local pOffset, pPushAngZ, pAngZ, pPushAngX, pAngX, pAngVelX, pAngY, pPushAngY = 0, 0, 0, 0, 0, 0, 0, 0
local pushAngX, pushAngY, pushAngZ = 0, 0, 0
local selfPos, angZ, angX, angVelX, angVelZ, selfVelX, selfVelY = Vector(0, 0, 0), 0, 0, 0, 0, 0, 0
local rotAng = 0

function ENT:PhysicsUpdate(phys)

	local mg = math.Clamp((CurTime() - self.StartTime)/2 * 250, 0, 250)
	
	if self.Owner:InVehicle() then
		selfPos = self.Owner:GetVehicle():WorldToLocal(self.Entity:GetPos())
		selfPos = Vector(selfPos.y, -selfPos.x, 0) + self.ConfluencePosition
		angY = self.Owner:GetVehicle():WorldToLocalAngles(self.Entity:GetAngles()).y - 90
	else
		self.CalculatePosition = false
		selfPos = WorldToLocal(self.ControledPos, Angle(0, 0, 0), self.Entity:GetPos(), Angle(0, 0, 0))
		selfPos = Vector(selfPos.y, -selfPos.x, 0)
		if self.UpDown or self.DownDown or self.LeftDown or self.RightDown then
			self.CalculatePosition = false
			self.ControledPos = self.Entity:GetPos() + self.Entity:GetForward() * self:GetVelX() * 128 + self.Entity:GetRight() * self:GetVelY() * 128
		end
		angY = self.Entity:GetAngles().y
	end
	angZ = self.Entity:GetAngles().z
	angX = self.Entity:GetAttachment(2).Ang.z
	
	local vel = self.Entity:GetVelocity()
	local selfAngY = self.Entity:GetAngles().y
	selfVelX = vel.x * math.cos(math.rad(selfAngY)) + vel.y * math.sin(math.rad(selfAngY))
	selfVelY = vel.x * math.sin(math.rad(selfAngY)) - vel.y * math.cos(math.rad(selfAngY))

	if math.abs(angZ) > 180 then
		angZ = -(360 - math.abs(angZ))
	end
	if math.abs(angY) > 180 then
		angY = -(360 - math.abs(angY))
	end
	if math.abs(angX) > 180 then
		angX = -(360 - math.abs(angX))
	end

	angVelX = (angX - pAngX)/engine.TickInterval()/7
	if angVelX == 0 then
		angVelX = pAngVelX
	end
	angVelZ = (angZ - pAngZ)/engine.TickInterval()

	local ymul = math.Clamp(math.abs(angY)/3, 1, 5)
 	pushAngY = angY * 0.2
	local angVelY = (angY - pAngY)/engine.TickInterval()
	if angY < 0 and angVelY > 3 * ymul then
		pushAngY = angVelY * 4 * ymul
	end
	if angY > 0 and angVelY < -3 * ymul then
		pushAngY = -angVelY * -4 * ymul
	end
	pushAngY = self:ClampForce(0.5, pPushAngY, pushAngY)
	pushAngY = math.Clamp(pushAngY, -10, 10)
	pPushAngY = pushAngY
	pAngY = angY
	
	if self.Batterie > 0 then
		if self.Owner:InVehicle() then
			rotAng = math.Clamp(pushAngY, -1, 1)
		else
			if self.RLDown then
				rotAng = -1
			elseif self.RRDown then
				rotAng = 1
			else
				rotAng = 0
			end
		end
	else
		rotAng = 0
	end
	for i = 1, 2 do
		self.Engine[i].Ent.RotateAngle = rotAng
	end
	local bone_l = self.Entity:LookupBone("front_l")
	self.Entity:ManipulateBoneAngles( bone_l, Angle(-rotAng, 0, 0) )
	local bone_r = self.Entity:LookupBone("front_r")
	self.Entity:ManipulateBoneAngles( bone_r, Angle(-rotAng, 0, 0) )
	
	-- self:Auto()
	self:Manual()

	local td = {}
		td.start = self.Entity:GetPos()
		td.endpos = self.Entity:GetPos() - self.Entity:GetUp() * 33000
		td.filter = self.Owner:InVehicle() and { self.Entity, self.Owner, self.Owner:GetVehicle() } or { self.Entity, self.Owner }
	local tr = util.TraceLine(td)

	if (CurTime() - self.StartTime) > 2 then
		Height = self.Entity:GetPos().z - tr.HitPos.z
		dHeight = Height - self.Height - self.TemporaryOffset
		dHeight = dHeight * 1
		local upVel = self.Entity:GetVelocity().z
		local clampHeight = math.Clamp(math.abs(dHeight)/2, 1, 10)
		if upVel > 4 * clampHeight then
			dHeight = 50
		elseif upVel < -4 * clampHeight then
			dHeight = -50
		elseif dHeight < 0 and dHeight > -32 and upVel > 2 then
			dHeight = upVel * 3
		elseif dHeight > 0 and dHeight < 32  and upVel < -2 then
			dHeight = -upVel * 3
		end
		dHeight = math.Clamp(dHeight, -50, 50)
		dHeight = self:ClampForce(2, pOffset, dHeight)
		pOffset = dHeight
	else
		dHeight = 0
	end

	if self.Batterie > 0 then
		self.Engine[1].Force = math.Clamp(mg - dHeight + pushAngX - pushAngZ, 0, 300)
		self.Engine[2].Force = math.Clamp(mg - dHeight + pushAngX + pushAngZ, 0, 300)
		self.Engine[3].Force = math.Clamp(mg - dHeight - pushAngX - pushAngZ, 0, 300)
		self.Engine[4].Force = math.Clamp(mg - dHeight - pushAngX + pushAngZ, 0, 300)
	else
		self.Engine[1].Force = 0
		self.Engine[2].Force = 0
		self.Engine[3].Force = 0
		self.Engine[4].Force = 0
	end

	for i = 1, 4 do
		self.Engine[i].Ent:SetForce(self.Engine[i].Force)
	end
	
	if CurTime() - self.NextAvoid > 8 then
		self.TemporaryOffset = 0
	end
	
	self:SetEngine1Value(self.Engine[1].Force)
	self:SetEngine2Value(self.Engine[2].Force)
	self:SetEngine3Value(self.Engine[3].Force)
	self:SetEngine4Value(self.Engine[4].Force)
	self:SetAngVelZ(angVelZ)
	self:SetAngVelX(angVelX)
	self:SetVelX(selfVelX)
	self:SetVelY(selfVelY)
	self:SetAltitude(Height)
	self:SetHeightValue(self.Height + self.TemporaryOffset)
	self:SetTemporaryOffset(self.TemporaryOffset)
	self:SetLWStat(self.Lengthwise)
	self:SetTVStat(self.Transverse)
	self:SetFrontEngineAngle(rotAng)
	self:SetEntOwner(self.Owner:EntIndex())

end

function ENT:Manual()

	local speedLimit = self.Owner:InVehicle() and 80 or 10
	local anitWall = self.Owner:InVehicle() and 1 or 0.5
	local yAng = self.Owner:InVehicle() and angY or 0

	-- // x
	self.Lengthwise = "Idle"
	local xmul = (self.Owner:InVehicle() or self.CalculatePosition)and math.Clamp(math.abs(selfPos.x)/512, 0, 1) or 15
	local clampAngX = math.Clamp((math.abs(angX)^2)/3, 1, 90)
	if angVelX > 3 * clampAngX and !(self.UpDown or self.DownDown) then
		pushAngX = 2
		self.Lengthwise = "Anti-AngVel"
	elseif angVelX < -3 * clampAngX and !(self.UpDown or self.DownDown) then
		pushAngX = -2
		self.Lengthwise = "Anti-AngVel"
	elseif self.DetectFront and self.DetectFront.Fraction < 1 and selfVelX > self.DetectFront.Fraction^1.2 * 80 and !(self.UpDown or self.DownDown) and math.abs(selfVelX) < speedLimit * xmul then
		pushAngX = anitWall
		self.Lengthwise = "Manual"
	elseif self.DetectBack and self.DetectBack.Fraction < 1 and selfVelX < self.DetectBack.Fraction^1.2 * -80 and !(self.UpDown or self.DownDown) and math.abs(selfVelX) < speedLimit * xmul then
		pushAngX = -anitWall
		self.Lengthwise = "Manual"
	elseif math.abs(selfVelX) > speedLimit * xmul and math.abs(angX) < 2 * xmul and math.abs(yAng) < 5 then
		if self.Owner:InVehicle() or self.CalculatePosition then
			pushAngX = 2 * xmul * selfVelX/math.abs(selfVelX)
		else
			pushAngX = 0.2 * selfVelX/math.abs(selfVelX) * math.abs(angX)
		end
		self.Lengthwise = "Anti-Vel"
	elseif self.UpDown and angX < 5 then
		local velX = selfVelX >= 0 and math.Clamp(selfVelX, 20, 200) or 20
		pushAngX = -2 * 20/velX
		self.Lengthwise = "Manual"
	elseif self.DownDown and angX > -5 then
		local velX = selfVelX <= 0 and math.Clamp(math.abs(selfVelX), 20, 200) or 20
		pushAngX = 2 * 20/velX
		self.Lengthwise = "Manual"
	elseif math.abs(selfPos.x) > 128 and math.abs(angX) < 2 * xmul and math.abs(yAng) < 5 and (self.Owner:InVehicle() or self.CalculatePosition) and Height > self.Height then
		pushAngX = 0.8 * xmul * selfPos.x/math.abs(selfPos.x)
		self.Lengthwise = "Proceeding"
	elseif math.abs(selfPos.x) > 8 and math.abs(angX) < 2 * xmul and math.abs(yAng) < 5 and (self.Owner:InVehicle() or self.CalculatePosition) and Height > self.Height then
		pushAngX = 10 * xmul * selfPos.x/math.abs(selfPos.x)
		self.Lengthwise = "Proceeding"
	else
		if angX < 0 and angVelX > 2 and math.abs(selfVelX) < 40 then
			pushAngX = angVelX * 1
			self.Lengthwise = "BalancingAngVel"
		elseif angX > 0 and angVelX < -2 and math.abs(selfVelX) < 40 then
			pushAngX = -angVelX * 1
			self.Lengthwise = "BalancingAngVel"
		else
			pushAngX = angX * 0.5
			self.Lengthwise = "BalancingAng"
		end
		pushAngX = math.Clamp(pushAngX, -3, 3)
	end
	pushAngX = self:ClampForce(1, pPushAngX, pushAngX)
	pPushAngX = pushAngX
	pAngVelX = angVelX
	pAngX = self.Entity:GetAttachment(2).Ang.z
	
	-- // z
	local clampAngZ = math.Clamp((math.abs(angZ)^2)/3, 1, 90)
	local zmul = (self.Owner:InVehicle() or self.CalculatePosition) and math.Clamp(math.abs(selfPos.y)/512, 0, 1) or 15
	if angVelZ > 3 * clampAngZ and !(self.LeftDown or self.RightDown) then
		pushAngZ = 2
		self.Transverse = "Anti-AngVel"
	elseif angVelZ < -3 * clampAngZ and !(self.LeftDown or self.RightDown) then
		pushAngZ = -2
		self.Transverse = "Anti-AngVel"
	elseif self.DetectLeft and self.DetectLeft.Fraction < 1 and selfVelY < self.DetectLeft.Fraction^1.2 * -80 and !(self.LeftDown or self.RightDown) and math.abs(selfVelY) < speedLimit * zmul then
		pushAngZ = -anitWall
		self.Lengthwise = "Manual"
	elseif self.DetectRight and self.DetectRight.Fraction < 1 and selfVelY > self.DetectRight.Fraction^1.2 * 80 and !(self.LeftDown or self.RightDown) and math.abs(selfVelY) < speedLimit * zmul then
		pushAngZ = anitWall
		self.Lengthwise = "Manual"
	elseif math.abs(selfVelY) > speedLimit * zmul and math.abs(angZ) < 2 * zmul and math.abs(yAng) < 5 then
		if self.Owner:InVehicle() or self.CalculatePosition then
			pushAngZ = 2 * zmul * selfVelY/math.abs(selfVelY)
		else
			pushAngZ = 0.2 * selfVelY/math.abs(selfVelY) * math.abs(angZ)
		end
		self.Transverse = "Anti-Vel"
	elseif self.LeftDown and angZ > -5 then
		local velY = selfVelY <= 0 and math.Clamp(math.abs(selfVelY), 20, 200) or 20
		pushAngZ = 1 * 20/velY
		self.Transverse = "Manual"
	elseif self.RightDown and angZ < 5 then
		local velY = selfVelY >= 0 and math.Clamp(selfVelY, 20, 200) or 20
		pushAngZ = -1 * 20/velY
		self.Transverse = "Manual"
	elseif math.abs(selfPos.y) > 128 and math.abs(angZ) < 2 * zmul and math.abs(yAng) < 5 and (self.Owner:InVehicle() or self.CalculatePosition) and Height > self.Height then
		pushAngZ = -0.8 * zmul * selfPos.y/math.abs(selfPos.y)
		self.Transverse = "Proceeding"
	elseif math.abs(selfPos.y) > 8 and math.abs(angZ) < 2 * zmul and math.abs(yAng) < 5 and (self.Owner:InVehicle() or self.CalculatePosition) and Height > self.Height then
		pushAngZ = -10 * zmul * selfPos.y/math.abs(selfPos.y)
		self.Transverse = "Proceeding"
	else
		if angZ < 0 and angVelZ > 2 and math.abs(selfVelY) < 40 then
			pushAngZ = angVelZ * 1
			self.Transverse = "BalancingAngVel"
		elseif angZ > 0 and angVelZ < -2 and math.abs(selfVelY) < 40 then
			pushAngZ = -angVelZ * 1
			self.Transverse = "BalancingAngVel"
		else
			pushAngZ = angZ * 0.5
			self.Transverse = "BalancingAng"
		end
		pushAngZ = math.Clamp(pushAngZ, -3, 3)
	end
	pushAngZ = self:ClampForce(1, pPushAngZ, pushAngZ)
	pPushAngZ = pushAngZ
	pAngZ = self.Entity:GetAngles().z

end

local n = 0

function ENT:Think()

	self:ReceiveManual()
	self:ReceiveVC()
	self:ReceiveVCString()
	self:Simulate()
	-- self:MeterProject()
	self:DetectWall()
	self:DetectRoof()

	self.Entity:NextThink(CurTime())

	return true

end

function ENT:Simulate()

	if self.Batterie > 0 then
		n = n + 10
	end

	for i = 1, 3, 2 do

		local bone = self.Entity:LookupBone("engine"..i)
		self.Entity:ManipulateBoneAngles( bone, Angle(0, n * 10^4, 0) )

	end
	for i = 2, 4, 2 do

		local bone = self.Entity:LookupBone("engine"..i)
		self.Entity:ManipulateBoneAngles( bone, Angle(0, -n * 10^4, 0) )

	end

	self.Batterie = self.Batterie - 1
	self.Batterie = math.Clamp(self.Batterie, 0, 10^5)
	self:SetBatterie(self.Batterie)
	
end

function ENT:ReceiveVCString()

	if self.VCCommand == "forward" then
		self.ConfluencePosition = self.ConfluencePosition + Vector(-64, 0, 0)
		self:SetNewPosition(self.ConfluencePosition)
		self.VCCommand = ""
	elseif self.VCCommand == "back" then
		self.ConfluencePosition = self.ConfluencePosition + Vector(64, 0, 0)
		self:SetNewPosition(self.ConfluencePosition)
		self.VCCommand = ""
	elseif self.VCCommand == "left" then
		self.ConfluencePosition = self.ConfluencePosition + Vector(0, -64, 0)
		self:SetNewPosition(self.ConfluencePosition)
		self.VCCommand = ""
	elseif self.VCCommand == "right" then
		self.ConfluencePosition = self.ConfluencePosition + Vector(0, 64, 0)
		self:SetNewPosition(self.ConfluencePosition)
		self.VCCommand = ""
	elseif self.VCCommand == "up" then
		self.Height = self.Height + 32
		self:SetHeightValue(self.Height)
		self.VCCommand = ""
	elseif self.VCCommand == "down" then
		self.Height = self.Height - 32
		self:SetHeightValue(self.Height)
		self.VCCommand = ""
	end
	
end

function ENT:ReceiveVC()

	net.Receive( "pjt_drn_vc", function()
		self.VCCommand = net.ReadString() 
	end )
	
end

function ENT:ReceiveManual()

	net.Receive( "pjt_drn", function()
		self.UpDown = net.ReadBool()
		self.DownDown = net.ReadBool()
		self.LeftDown = net.ReadBool()
		self.RightDown = net.ReadBool()
		self.RLDown = net.ReadBool()
		self.RRDown = net.ReadBool()
	end )
	
end

local flip = 1
local avoid = {}
for i = 1, 129 do
	avoid[i] = 1
end
pDetDir = 0

function ENT:DetectRoof()

	self.Scan = self.Scan + flip
	if self.Scan >= 64 then
		flip = -1
	elseif self.Scan <= -64 then
		flip = 1
	end
	
	local pos = self.Entity:GetPos()
	local ang = self.Entity:GetAngles()
	local detDir = 0
	if self.DetectLeft.Fraction < 0.08 then
		detDir = 90
	elseif self.DetectRight.Fraction < 0.08 then
		detDir = -90
	end
	if pDetDir != detDir then
		detDir = 90
		for i = 1, 129 do
			avoid[i] = 1
		end
	end
	pDetDir = detDir
	ang:RotateAroundAxis(self.Entity:GetUp(), detDir)
	local dir = ang:Forward()

	local td_scan = {}
		td_scan.start = pos
		td_scan.endpos = pos + dir * 64 + self.Entity:GetUp() * self.Scan
		td_scan.filter = { self.Entity }
	self.DetectScan = util.TraceLine(td_scan)
	
	avoid[self.Scan + 65] = self.DetectScan.Fraction
	
	local avoidToUpper = true
	local avoidToLower = true
	if self.DetectFront.Fraction < 0.1 and selfVelX > 0 then
		self:ProcessAvoid(avoidToUpper, avoidToLower)
	elseif self.DetectLeft.Fraction < 0.1 and selfVelY < 0 then
		self:ProcessAvoid(avoidToUpper, avoidToLower)
	elseif self.DetectRight.Fraction < 0.1 and selfVelY > 0 then
		self:ProcessAvoid(avoidToUpper, avoidToLower)
	end
	
	self:SetScanDirection(detDir)
	self:SetScanPosition(self.Scan)
	
end

function ENT:ProcessAvoid(avoidToUpper, avoidToLower)

	for i = 97, 129 do
		if avoid[i] < 1 then
			avoidToUpper = false
		end
	end
	for i = 1, 32 do
		if avoid[i] < 1 then
			avoidToLower = false
		end
	end
	if CurTime() > self.NextAvoid then
		if avoidToUpper then
			self.TemporaryOffset = self.TemporaryOffset + 72
			self.NextAvoid = CurTime() + 4
			avoidToLower = false
		end
		if avoidToLower then
			if self.Height >= 96 then
				self.TemporaryOffset = self.TemporaryOffset - 72
				self.NextAvoid = CurTime() + 4
			end
		end
	end
	
end

function ENT:DetectWall()

	local td_f = {}
		td_f.start = self.Entity:GetPos()
		td_f.endpos = self.Entity:GetPos() + self.Entity:GetForward() * 1024
		td_f.filter = { self.Entity }
	self.DetectFront = util.TraceLine(td_f)

	self:SetFrontFraction(self.DetectFront.Fraction)
	
	local td_b = {}
		td_b.start = self.Entity:GetPos()
		td_b.endpos = self.Entity:GetPos() - self.Entity:GetForward() * 1024
		td_b.filter = { self.Entity }
	self.DetectBack = util.TraceLine(td_b)

	self:SetBackFraction(self.DetectBack.Fraction)
	
	local td_l = {}
		td_l.start = self.Entity:GetPos()
		td_l.endpos = self.Entity:GetPos() - self.Entity:GetRight() * 1024
		td_l.filter = { self.Entity }
	self.DetectLeft = util.TraceLine(td_l)

	self:SetLeftFraction(self.DetectLeft.Fraction)
	
	local td_r = {}
		td_r.start = self.Entity:GetPos()
		td_r.endpos = self.Entity:GetPos() + self.Entity:GetRight() * 1024
		td_r.filter = { self.Entity }
	self.DetectRight = util.TraceLine(td_r)
	
	self:SetRightFraction(self.DetectRight.Fraction)
	
end

function ENT:MeterProject()

	local bone = self.Entity:LookupBone("meter")

	self.Entity:ManipulateBonePosition( bone, Vector(0, 0, angX * 0.08) )
	self.Entity:ManipulateBoneAngles( bone, Angle(angZ, 0, 0) )

end

function ENT:Use(activator)
end

function ENT:OnRemove()
end

