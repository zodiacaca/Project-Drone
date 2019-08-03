
ENT.Type			= "anim"
ENT.Base			= "base_anim"
ENT.PrintName	= "project_drone"
ENT.Category		= "Project Drone"

ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.AdminOnly = false
ENT.DoNotDuplicate = true
ENT.DisableDuplicator = true


function ENT:SetupDataTables()
	self:NetworkVar( "Float", 1, "ForceNum" )
end

