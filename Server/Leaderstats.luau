local CONSTS = {
	Valid = {
		"Number",
		"Int",
		"Bool",
		"String"
	},

	Priority = "Priority",
	Folder = "leaderstats"
}

local Players = game:GetService("Players")

local m = {}

function m:Get(player, name)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Leaderstats.Get | player must be a Player")
	assert(type(name) == "string" or name == nil, "Leaderstats.Get | name must be a string or nil")

	local folder = player:FindFirstChild(CONSTS.Folder)
	if not name then
		return folder
	end

	return folder and folder:FindFirstChild(name)
end

function m:Update(player, name, value)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Leaderstats.Update | player must be a Player")
	assert(type(name) == "string", "Leaderstats.Update | name must be a string")

	local stat = self:Get(player, name)
	if not stat then
		return
	end

	stat.Value = value
end

function m:Remove(player, name)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Leaderstats.Remove | player must be a Player")
	assert(type(name) == "string", "Leaderstats.Remove | name must be a string")

	local stat = self:Get(player, name)
	if not stat then
		return
	end

	stat:Destroy()
	stat = nil
end

function m:SetPriority(player, name, new)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Leaderstats.SetPriority | player must be a Player")
	assert(type(name) == "string", "Leaderstats.SetPriority | name must be a string")
	assert(type(new) == "number", "Leaderstats.SetPriority | new must be a number")

	local stat = self:Get(player, name)
	if not stat then
		return
	end

	local priority = stat:FindFirstChild(CONSTS.Priority)
	if not priority then
		priority = Instance.new("NumberValue")

		priority.Name = CONSTS.Priority
		priority.Parent = stat
	end

	priority.Value = new
end

function m:Add(player, name, valueType)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Leaderstats.Add | player must be a Player")
	assert(type(name) == "string", "Leaderstats.Add | name must be a string")
	assert(type(valueType) == "string", "Leaderstats.Add | valueType must be a string")

	if not table.find(CONSTS.Valid, valueType) then
		return
	end

	local folder = self:Get(player)
	if not folder then
		folder = Instance.new("Folder")

		folder.Name = CONSTS.Folder
		folder.Parent =  player
	end

	local stat = folder:FindFirstChild(name)
	if stat then
		return
	end

	stat = Instance.new(`{valueType}Value`)
	stat.Name = name
	stat.Parent = folder
end

return m
