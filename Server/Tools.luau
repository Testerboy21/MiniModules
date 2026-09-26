--[[
	Tools:
		Manages serversided tools
]]

local FOLDER = "Tools"

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local STORAGE = ServerStorage:FindFirstChild(FOLDER)

local Service = require(ServerScriptService.Modules.Service)
local AgentCleanup = require(ServerScriptService.Modules.AgentCleanup)

local m = {
	Mapped = {},
	AgentInfo = {}
}

-- private
local function setupPlayer(player)
	AgentCleanup:Add(player, function() -- cleanup
		if not m.AgentInfo[player] then
			return
		end

		m.AgentInfo[player] = nil
	end)

	m.AgentInfo[player] = {}
end

-- public
function m:GetInfo(player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Tools.GetInfo | player must be a Player")

	return self.AgentInfo[player]
end

function m:Unmap(name)
	assert(type(name) == "string", "Tools.Unmap | name must be a string")

	if not self.Mapped[name] then
		return
	end

	self.Mapped[name] = nil
end

function m:Map(name, callback)
	assert(type(name) == "string", "Tools.Map | name must be a string")
	assert(type(callback) == "function", "Tools.Map | callback must be a function")

	if self.Mapped[name] then
		return
	end

	self.Mapped[name] = callback
end

function m:Remove(player, name)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Tools.Remove | player must be a Player")
	assert(type(name) == "string", "Tools.Remove | name must be a string")

	local tools = self:GetInfo(player)
	local tool = tools and tools[name]

	if not tool then
		return
	end

	tool:Destroy()
	tools[name] = nil

	if not next(tools) then
		self.AgentInfo[player] = nil
	end
end

function m:Give(player, name)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Tools.Give | player must be a Player")
	assert(type(name) == "string", "Tools.Give | name must be a string")

	local tool = STORAGE and STORAGE:FindFirstChild(name)
	local toolName = tool and tool.Name

	if not self.Mapped[toolName] then
		return
	end

	local backpack = player:FindFirstChild("Backpack")
	if not backpack or not backpack:IsA("Backpack") then
		return
	end

	local clone = nil
	local tools = self:GetInfo(player)

	if not tools or tools[name] then
		return
	end

	clone = tool:Clone()

	tools[name] = clone
	clone.Parent = backpack
end

function m:Main()
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end

    Players.PlayerAdded:Connect(function(player)
		setupPlayer(player)
	end)
end

-- setup
local service = Service.new(m)

service.Share("Use", function(self, player, name)
	local callback = self.Server.Mapped[name]
	if not callback then
		return nil
	end

	local tools = self.Server:GetInfo(player)
	local owned = tools and tools[name]

	if not owned then
		return nil
	end

	return callback(player)
end)

return service
