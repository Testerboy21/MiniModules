local CONSTS = {
	Occlusion = "Camera_CanClip",

	MinThirdPersonZoom = 15
}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerScripts = Player.PlayerScripts

local Controller = require(PlayerScripts.Modules.Controller)
local Vibrate = require(PlayerScripts.Modules.Vibrate)

local Camera = Workspace.CurrentCamera
local MouseLockController = PlayerScripts.PlayerModule.CameraModule.MouseLockController

local MouseLockSet, MouseLockState = nil, nil

local m = {
	PreviousZoom = {
		Min = nil,
		Max = nil
	},

	MouseLocked = false,
	
	PreviousCameraMode = nil,
	MouseLockChanged = nil
}

function m:IsShiftLocked()
	return self.MouseLocked
end

function m:DisableMouseLock()
	self:SetMouseLock(false, true)
end

function m:EnableMouseLock()
	self:SetMouseLock(self.MouseLocked, false)
end

function m:InFirstPerson()
	return Player:DistanceFromCharacter(Camera.CFrame.Position) <= 1
end

function m:IsMouseBehaviorLocked()
	return UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default
end

function m:SetMouseLock(enabled: boolean, isPermanent: boolean?)
	if not MouseLockSet then
		return
	end

	MouseLockSet:Fire(enabled, isPermanent)
end

function m:SetPartClippable(part: BasePart, enabled: boolean)
	local tag = CONSTS.Occlusion
	local hasTag = part:GetAttribute(tag)

	if not enabled then
		if hasTag then
			part:SetAttribute(tag, nil)
		end
	else
		if not hasTag then
			part:SetAttribute(tag, true)
		end
	end
end

function m:Shake(properties: Vibrate.VibrationProperties)
	local character = Player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")

	if not humanoid or type(properties) ~= "table" then
		return
	end

	properties.SourceProperty = "CameraOffset"
	Vibrate:Start(humanoid, properties)
end

function m:ResetZoom()
	if not self.PreviousZoom.Min or not self.PreviousZoom.Max then
		return
	end

	Player.CameraMinZoomDistance = self.PreviousZoom.Min
	Player.CameraMaxZoomDistance = self.PreviousZoom.Max

	self.PreviousZoom.Min = nil
	self.PreviousZoom.Max = nil
end

function m:LockThirdPerson(enabled: boolean)
	if not enabled then
		self:ResetZoom()
	else
		self:LockZoom({
			Min = CONSTS.MinThirdPersonZoom,
			Max = Player.CameraMaxZoomDistance
		})
	end
end

function m:LockFirstPerson(enabled: boolean)
	if enabled then
		local mode = Player.CameraMode
		local new = Enum.CameraMode.LockFirstPerson
		
		if mode ~= new then
			if not self.PreviousCameraMode then
				self.PreviousCameraMode = Player.CameraMode
			end

			Player.CameraMode = new
		end
	else
		local previous = self.PreviousCameraMode
		if not previous then
			return
		end

		Player.CameraMode = previous
		self.PreviousCameraMode = nil
	end
end

function m:LockZoom(amount: number | { Min: number, Max: number })
	local currentMin = Player.CameraMinZoomDistance
	local currentMax = Player.CameraMaxZoomDistance

	local min, max = amount, amount
	if type(amount) == "table" then
		min, max = amount.Min, amount.Max
	end

	if min == currentMin and max == currentMax then
		return
	end

	self.PreviousZoom.Min = currentMin
	self.PreviousZoom.Max = currentMax

	Player.CameraMinZoomDistance = min
	Player.CameraMaxZoomDistance = max
end

function m:Main()
	if MouseLockController then
		if not MouseLockSet then
			MouseLockSet = MouseLockController:WaitForChild("mouseLockSet", 1)
		end

		if not MouseLockState then
			MouseLockState = MouseLockController:WaitForChild("mouseLockState", 1)
			
			if MouseLockState then
				MouseLockState.Changed:Connect(function(value)
					self.MouseLocked = value
					self.MouseLockChanged:Fire(value)
				end)
			end
		end
	end
end

local controller = Controller.new(m)

controller.CreateSignal("MouseLockChanged")

return controller
