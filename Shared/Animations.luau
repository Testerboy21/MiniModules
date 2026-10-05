--[[
	Test IDs:
		125750702
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local m = {
	Default = {},
	Playing = {}
}

function m:GetTrackFromId(rig, id)
	assert(typeof(rig) == "Instance" and rig:IsA("Model"), "Animations.GetTrackFromId | rig must be a Model")
	assert(type(id) == "number", "Animations.GetTrackFromId | id must be a number")

	local playing = self.Playing[rig]
	if not playing then
		return nil
	end

	return playing[id]
end

function m:Freeze(track, position, percentage)
	assert(typeof(track) == "Instance" and track:IsA("AnimationTrack"), "Animations.Freeze | track must be an AnimationTrack")

	if not track.IsPlaying then
		return
	end

	local new = tonumber(position) or tonumber(percentage)
	if not new then
		return
	end

	if new == percentage then
		new /= 100 * track.Length
	end

	track.TimePosition = new
	self:Modify(track, { Speed = 0 })
end

function m:Modify(track, properties)
	assert(typeof(track) == "Instance" and track:IsA("AnimationTrack"), "Animations.Modify | track must be an AnimationTrack")
	assert(type(properties) == "table", "Animations.Modify | properties must be a table")

	local speed = tonumber(properties.Speed)
	if speed then
		track:AdjustSpeed(speed)
	end

	local weight = properties.Weight
	if weight and type(weight) == "table" then
		track:AdjustWeight(weight.Value, weight.Fade or 1e-1)
	end

	for key, value in properties do
		pcall(function()
			track[key] = value
		end)
	end
end

function m:WaitForMarker(track, name, isPrevious)
	assert(typeof(track) == "Instance" and track:IsA("AnimationTrack"), "Animations.WaitForMarker | track must be an AnimationTrack")
	assert(type(name) == "string", "Animations.WaitForMarker | name must be a string")

	isPrevious = not not isPrevious

	if not track.IsPlaying or (track.TimePosition >= track:GetTimeOfKeyframe(name) and not isPrevious) then
		return false
	end

	local stopped = nil
	local reachedSignal = nil

	local isWaiting = true
	local hasReached = false

	reachedSignal = track:GetMarkerReachedSignal(name):Connect(function()
		reachedSignal:Disconnect()
		reachedSignal = nil

		isWaiting = false
		hasReached = true
	end)

	stopped = track.Stopped:Once(function()
		if reachedSignal then
			reachedSignal:Disconnect()
			reachedSignal = nil
		end

		stopped = nil
		isWaiting = false
	end)

	while isWaiting do
		task.wait()
	end

	return hasReached
end

function m:WaitForTrack(rig, id, maxWait)
	assert(typeof(rig) == "Instance" and rig:IsA("Model"), "Animations.WaitForTrack | rig must be a Model")
	assert(type(id) == "number", "Animations.WaitForTrack | id must be a number")
	assert(type(maxWait) == "number", "Animations.WaitForTrack | maxWait must be a number")

	local humanoid = rig:FindFirstChild("Humanoid")
	local animator = humanoid and humanoid:FindFirstChild("Animator")

	if not animator then
		return nil
	end

	local found = nil
	local asset = tostring(id)

	for _, track in animator:GetPlayingAnimationTracks() do
		if not track.Animation.AnimationId:find(asset) then
			continue
		end

		found = track
		break
	end

	if found then
		return found
	end

	local start = tick()
	local destroying = nil
	local animationPlayed = nil

	local function onCleanup()
		if animationPlayed then
			animationPlayed:Disconnect()
			animationPlayed = nil
		end

		if destroying then
			destroying:Disconnect()
			destroying = nil
		end
	end

	animationPlayed = animator.AnimationPlayed:Connect(function(track)
		if not track.Animation.AnimationId:find(asset) then
			return
		end

		found = track
	end)

	destroying = rig.Destroying:Once(onCleanup)

	while not found and (tick() - start) <= maxWait do
		task.wait()
	end

	onCleanup()

	return found
end

function m:Play(rig, id, properties)
	assert(typeof(rig) == "Instance" and rig:IsA("Model"), "Animations.Play | rig must be a Model")
	assert(type(id) == "number", "Animations.Play | id must be a number")
	assert(type(properties) == "table" or properties == nil, "Animations.Play | properties must be a table or nil")

	local humanoid = rig:FindFirstChild("Humanoid")
	local animator = humanoid and humanoid:FindFirstChild("Animator")

	if not animator then
		return nil
	end

	local playing = self.Playing[rig]
	if not playing then
		playing = {}
		self.Playing[rig] = playing
	end

	local track = playing[id]
	if track and track.IsPlaying then
		track:Stop()
	end

	local stopped = nil
	local animation = Instance.new("Animation")

	animation.AnimationId = `rbxassetid://{id}`

	track = animator:LoadAnimation(animation)
	track:Play()

	playing[id] = track
	track.Priority = Enum.AnimationPriority.Action

	if properties then
		self:Modify(track, properties)
	end

	stopped = track.Stopped:Once(function()
		local t = playing[id]
		if not t then
			return
		end

		t:Destroy()

		t = nil
		stopped = nil
		playing[id] = nil

		if not next(playing) then
			self.Playing[rig] = nil
		end
	end)

	return track
end

function m:SetDefault(rig, new)
	assert(typeof(rig) == "Instance" and rig:IsA("Model"), "Animations.SetDefault | rig must be a Model")
	assert(type(new) == "table", "Animations.SetDefault | new must be a table")

	local animate = rig:FindFirstChild("Animate")
	if not animate then
		return
	end

	-- setup
	local defaults = self.Default[rig]
	if not defaults and next(new) then
		local connection = nil

		connection = rig.AncestryChanged:Connect(function(_child, parent)
			if parent ~= nil then
				return
			end

			connection:Disconnect()
			connection = nil

			self.Default[rig] = nil
		end)

		defaults = {}
		self.Default[rig] = defaults
	end

	for key, value in new do
		if type(key) ~= "string" then
			continue
		end

		-- verify | animation
		local _success, animation = pcall(function()
			return animate[key:lower()]
		end)

		if not animation then
			continue
		end

		-- cache
		local cached = defaults[key]
		if not cached then
			cached = {}
			defaults[key] = cached
		end

		for _, anim in animation:GetChildren() do
			if not anim:IsA("Animation") then
				continue
			end

			if not table.find(cached, anim) then
				table.insert(cached, anim:Clone())
			end

			anim:Destroy()
			anim = nil
		end

		-- verify | values
		local assetId = tonumber(value)
		local isList = type(value) == "table"

		if not (assetId or isList) then
			continue
		end

		-- create & set
		if assetId then
			local anim = Instance.new("Animation")

			anim.Name = `Animations.{key}`
			anim.AnimationId = `rbxassetid://{assetId}`

			anim.Parent = animation
		else
			for index, id in value do
				local anim = Instance.new("Animation")

				anim.Name = `Animations.{key}_{index}`
				anim.AnimationId = `rbxassetid://{id}`

				anim.Parent = animation
			end
		end
	end

	-- reset if applicable
	for name, animations in defaults do
		if new[name] then
			continue
		end

		local key = name:lower()
		local animation = animate[key]

		if not animation then
			continue
		end

		-- clear
		for _, anim in animation:GetChildren() do
			anim:Destroy()
			anim = nil
		end

		-- set
		for _, anim in animations do
			anim.Parent = animation
		end
	end
end

return m
