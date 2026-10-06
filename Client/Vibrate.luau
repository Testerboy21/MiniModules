--[[
	Vibrate:
		Handles shaking objects in local space.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LockStep = require(ReplicatedStorage.Modules.LockStep)

local Rand = Random.new()

local m = {
	Running = {}
}

export type VibrationProperties = {
	Offset: number | Vector3,
	Dampening: number?,
	FadeIn: number?,
	FadeOut: number?,
	Length: number?,
	SourceProperty: string?
}

function m:Stop(object: Instance)
	local info = self.Running[object]
	if not info then
		return
	end

	local source, property = table.unpack(info.Source)

	if property and object[property] then
		object[property] = source
	elseif object:IsA("PVInstance") then
		object:PivotTo(source)
	end

	self.Running[object] = nil
end

function m:Start(object: Instance, properties: VibrationProperties)
	if self.Running[object] then
		return
	end

	local property = properties.SourceProperty
	local source = property and object[property] or object:IsA("PVInstance") and object:GetPivot()

	if not source then
		return
	end

	local isVector, isMatrix = typeof(source) == "Vector3", typeof(source) == "CFrame"
	if not (isVector or isMatrix) then
		return
	end

	local length, fadeIn, fadeOut = properties.Length or 0, properties.FadeIn or 0, properties.FadeOut or 0
	local dampening = properties.Dampening or 0.1

	local offset = properties.Offset
	local new = type(offset) == "number" and Vector3.one * offset

	if typeof(offset) ~= "Vector3" and not new then
		return
	end

	local guid = HttpService:GenerateGUID()
	local bind = `{guid}.Vibrate`

	local newSource, oldOffset = source, new
	local eTick = tick()

	self.Running[object] = {
		Name = bind,
		Source = { source, property }
	}

	LockStep:Connect(function(lock)
		if not self.Running[object] then
			lock:Disconnect()
			return
		end

		local elapsed = tick() - eTick
		if elapsed >= length then
			new *= (0.99 - (math.min(math.abs(dampening), (10) - 0.1) / 10))

			if newSource ~= source and newSource:FuzzyEq(source, 1e-3) then
				self:Stop(object)
			end
		else
			local fadeOutStart = length - fadeOut
			local fI, fO = math.min(elapsed, fadeIn), math.max(elapsed, fadeOutStart)

			local progress = 1
			local startVector, endVector = Vector3.zero, oldOffset

			if elapsed == fI then
				progress = elapsed / fadeIn
			elseif elapsed == fO then
				startVector, endVector = oldOffset, Vector3.zero
				progress = (elapsed - fadeOutStart) / fadeOut
			end

			new = startVector:Lerp(endVector, math.clamp(progress, 0, 1))
		end

		if isVector then
			newSource = source + Vector3.new(
				new.X * (Rand:NextInteger(0, 1) == 0 and -1 or 1),
				new.Y * (Rand:NextInteger(0, 1) == 0 and -1 or 1),
				new.Z * (Rand:NextInteger(0, 1) == 0 and -1 or 1)
			)
		else
			newSource = source * CFrame.new(
				new.X * (Rand:NextInteger(0, 1) == 0 and -1 or 1),
				new.Y * (Rand:NextInteger(0, 1) == 0 and -1 or 1),
				new.Z * (Rand:NextInteger(0, 1) == 0 and -1 or 1)
			)
		end

		if property and object[property] then
			object[property] = newSource
		elseif object:IsA("PVInstance") then
			object:PivotTo(newSource)
		end

	end, 60, false, true)
end

return m
