local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Backpack = Player.Backpack
local PlayerScripts = Player.PlayerScripts

local Controller = require(PlayerScripts.Modules.Controller)

local Tools_Server = nil

local m = {
	Tools = {},

	Updated = nil
}

-- private
local function onToolAdded(child)
	if not child:IsA("Tool") then
		return
	end

	local name = child.Name
	if m.Tools[name] then
		return
	end

	child.Destroying:Once(function()
		m.Tools[name] = nil
	end)

	child.AncestryChanged:Connect(function(_, parent)
		m.Updated:Fire(child, parent)
	end)

	child.Parent = nil
	m.Tools[name] = child
end

-- public
function m:Unequip(name: string)
	local tool = self.Tools[name]
	if not tool then
		return
	end

	if not tool.Parent then
		return
	end

	tool.Parent = nil
end

function m:Equip(name: string)
	local tool = self.Tools[name]
	if not tool then
		return
	end

	if tool.Parent then
		return
	end

	tool.Parent = Backpack
end

function m:Use(name: string)
	local tool = self.Tools[name]
	if not tool then
		return
	end

	if not tool.Parent or tool.Parent ~= Player.Character then
		return
	end

	return Tools_Server:Use(name)
end

function m:Main()
	Tools_Server = Controller.Get({
		"Tools"
	})

	Backpack.ChildAdded:Connect(function(child)
		onToolAdded(child)
	end)
end

-- setup
local controller = Controller.new(m)

controller.CreateSignal("Updated")

return controller
