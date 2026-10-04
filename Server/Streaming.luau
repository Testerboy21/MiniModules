--[[
	Streaming:
		Manages player-oriented instance streaming
]]

local ServerScriptService = game:GetService("ServerScriptService")

local AgentCleanup = require(ServerScriptService.Modules.AgentCleanup)

local m = {
	Loaded = {}
}

function m:HasPersistence(player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Streaming.HasPersistence | player must be a Player")

	return table.find(self.Loaded, player) ~= nil
end

function m:GetPersistentPlayersFrom(model)
	assert(typeof(model) == "Instance" and model:IsA("Model"), "Streaming.GetPersistentPlayersFrom | model must be a Model")

	return model:GetPersistentPlayers()
end

function m:SetPrimaryFocus(player, focus)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Streaming.SetPrimaryFocus | player must be a Player")
	assert(typeof(focus) == "Instance" and (focus:IsA("BasePart") or focus == nil), "Streaming.SetPrimaryFocus | focus must be a BasePart or nil")

	player.ReplicationFocus = focus
end

function m:Request(player, position)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Streaming.Request | player must be a Player")
	assert(typeof(position) == "Vector3", "Streaming.Request | position must be a Vector3")

	player:RequestStreamAroundAsync(position)
end

function m:AddFocusPoint(player, focus)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Streaming.AddFocusPoint | player must be a Player")
	assert(typeof(focus) == "Instance" and focus:IsA("BasePart"), "Streaming.AddFocusPoint | focus must be a BasePart")

	player:AddReplicationFocus(focus)
end

function m:RemoveFocusPoint(player, focus)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Streaming.RemoveFocusPoint | player must be a Player")
	assert(typeof(focus) == "Instance" and focus:IsA("BasePart"), "Streaming.RemoveFocusPoint | focus must be a BasePart")

	player:RemoveReplicationFocus(focus)
end

function m:MakePersistent(model, player, enabled)
	assert(typeof(model) == "Instance" and model:IsA("Model"), "Streaming.MakePersistent | model must be a Model")
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Streaming.MakePersistent | player must be a Player")

	if not self:HasPersistence(player) then
		return false
	end

	if enabled then
		model:AddPersistentPlayer(player)
	else
		model:RemovePersistentPlayer(player)
	end

	return true
end

workspace.PersistentLoaded:Connect(function(player)
	local loaded = m.Loaded
	local found = table.find(loaded, player)

	if not found then
		table.insert(loaded, player)
	end

	AgentCleanup:Add(player, function()
		found = table.find(loaded, player)

		if found then
			table.remove(loaded, found)
		end
	end)
end)

return m
