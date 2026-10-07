--[[
	Selective:
		Selectively replicates objects to an intended player or group of players: https://anaminus.github.io/blog/exclusive-replication/
]]

local FOLDER = "Selective"

local HttpService = game:GetService("HttpService")

local m = {}

function m:RemoveFromPlayers(players, name)
	assert(typeof(players) == "table", "Selective.RemoveFromPlayers | players must be a table")
	assert(type(name) == "string", "Selective.RemoveFromPlayers | name must be a string")

	for _, player in players do
		if typeof(player) ~= "Instance" or not player:IsA("Player") then
			continue
		end

		self:RemoveFrom(player, name)
	end
end

function m:ReplicateToPlayers(players, name, data)
	assert(typeof(players) == "table", "Selective.ReplicateToPlayers | players must be a table")
	assert(type(name) == "string", "Selective.ReplicateToPlayers | name must be a string")

	local objects = {}
	for _, player in players do
		if typeof(player) ~= "Instance" or not player:IsA("Player") then
			continue
		end

		local new = data
		if typeof(data) == "Instance" then
			new = data:Clone()
		end

		objects[player] = self:ReplicateTo(player, name, new)
	end

	return objects
end

function m:RemoveFrom(player, name)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Selective.RemoveFrom | player must be a Player")
	assert(type(name) == "string", "Selective.RemoveFrom | name must be a string")

	local playerGui = player:FindFirstChild("PlayerGui")
	local folder = playerGui and playerGui:FindFirstChild(FOLDER)

	if not folder then
		return
	end

	local object = folder:FindFirstChild(name)
	if object then
		object:Destroy()
		object = nil
	end

	if not next(folder:GetChildren()) then
		folder:Destroy()
		folder = nil
	end
end

function m:ReplicateTo(player, name, data)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Selective.ReplicateTo | player must be a Player")
	assert(type(name) == "string", "Selective.ReplicateTo | name must be a string")

	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		return nil
	end

	local folder = playerGui:FindFirstChild(FOLDER)
	if not folder then
		folder = Instance.new("Folder")

		folder.Name = FOLDER
		folder.Parent = playerGui
	end

	local baseValue = nil
	local dataType = typeof(data)
	local value = folder:FindFirstChild(name)

	if dataType == "Instance" and data ~= value then
		if value then
			value:Destroy()
			value = nil
		end

		data.Name = name
		data.Parent = folder
	else
		if value and typeof(value.Value) ~= dataType then
			value:Destroy()
			value = nil
		end

		if not value then
			if dataType == "string" or dataType == "table" then
				baseValue = "StringValue"
			elseif dataType == "number" then
				baseValue = "NumberValue"
			elseif dataType == "boolean" then
				baseValue = "BooleanValue"
			else
				local success, instance = pcall(Instance.new, `{dataType}Value`)
				if not success then
					return nil
				end

				value = instance
			end

			value = value or Instance.new(baseValue)
			value.Name = name
		end

		if dataType == "table" then
			data = HttpService:JSONEncode(data)
			value:SetAttribute("Decode", true)
		end

		value.Value = data
		value.Parent = folder
	end

	return value or data
end

return m
