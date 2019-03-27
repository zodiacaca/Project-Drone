
ENT.Type			= "anim"
ENT.Base			= "base_anim"
ENT.PrintName	= "project_drone"
ENT.Category		= "Project Drone"

ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.AdminOnly = false
ENT.DoNotDuplicate = true
ENT.DisableDuplicator = true


function ENT:SetupDataTables()
	self:NetworkVar( "Float", 1, "Engine1Value" )
	self:NetworkVar( "Float", 2, "Engine2Value" )
	self:NetworkVar( "Float", 3, "Engine3Value" )
	self:NetworkVar( "Float", 4, "Engine4Value" )
	self:NetworkVar( "Float", 5, "AngVelZ" )
	self:NetworkVar( "Float", 6, "AngVelX" )
	self:NetworkVar( "Float", 7, "VelX" )
	self:NetworkVar( "Float", 8, "VelY" )
	self:NetworkVar( "Float", 9, "Altitude" )
	self:NetworkVar( "Float", 10, "HeightValue" )
	self:NetworkVar( "Float", 11, "Batterie" )
	self:NetworkVar( "Float", 12, "EntOwner" )
	self:NetworkVar( "Float", 13, "FrontFraction" )
	self:NetworkVar( "Float", 14, "BackFraction" )
	self:NetworkVar( "Float", 15, "LeftFraction" )
	self:NetworkVar( "Float", 16, "RightFraction" )
	self:NetworkVar( "Float", 17, "FrontEngineAngle" )
	self:NetworkVar( "String", 0, "LWStat" )
	self:NetworkVar( "String", 1, "TVStat" )
	self:NetworkVar( "Vector", 1, "NewPosition" )
	self:NetworkVar( "Int", 1, "ScanDirection" )
	self:NetworkVar( "Int", 2, "ScanPosition" )
	self:NetworkVar( "Int", 3, "TemporaryOffset" )
end