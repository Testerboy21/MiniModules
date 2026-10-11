--[[
	Collisions:
		Manages adding, removing, or controlling the collision state of groups and objects
]]

local CONSTS = {
	DefaultGroup = "Default",
	Constraint = "Collisions.Constraint"
}

local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constraints = require(ReplicatedStorage.Modules.Constraints)

local m = {
	Groups = {}
}

function m:DisableForGroup(name, enabled)
	assert(type(name) == "string", "Collisions.DisableForGroup | name must be a string")
	
	return self:DisableForGroups(name, name, enabled)
end

function m:InGroup(object, name)
	assert(typeof(object) == "Instance" and (object:IsA("BasePart") or object:IsA("Model")), "Collisions.InGroup | object must be a BasePart or a Model")
	assert(type(name) == "string", "Collisions.InGroup | name must be a string")

	local group = self.Groups[name]
	if not group then
		return false
	end

	return table.find(group, object) ~= nil
end

function m:Register(name)
	assert(type(name) == "string", "Collisions.Register | name must be a string")

	if PhysicsService:IsCollisionGroupRegistered(name) or #PhysicsService:GetRegisteredCollisionGroups() >= PhysicsService:GetMaxCollisionGroups() then
		return
	end
	
	return PhysicsService:RegisterCollisionGroup(name)
end

function m:DisableForObject(object, enabled)
	assert(typeof(object) == "Instance" and (object:IsA("BasePart") or object:IsA("Model")), "Collisions.DisableForObject | object must be a BasePart or a Model")

	if object:IsA("Model") then
		for _, obj in object:GetDescendants() do
			if not obj:IsA("BasePart") then
				continue
			end

			self:DisableForObject(obj, enabled)
		end

		return
	end

	object.CanCollide = not enabled
end

function m:DisableForGroups(a, b, enabled)
	assert(type(a) == "string", "Collisions.DisableForGroups | a must be a string")
	assert(type(b) == "string", "Collisions.DisableForGroups | b must be a string")

	local firstRegistered = PhysicsService:IsCollisionGroupRegistered(a)
	local secondRegistered = PhysicsService:IsCollisionGroupRegistered(b)

	if not firstRegistered or not secondRegistered then
		return
	end

	local canCollide = PhysicsService:CollisionGroupsAreCollidable(a, b)
	if enabled then
		if canCollide then
			PhysicsService:CollisionGroupSetCollidable(a, b, false)
		end
	else
		if not canCollide then
			PhysicsService:CollisionGroupSetCollidable(a, b, true)
		end
	end
end

function m:DisableForParts(a, b, enabled)
	assert(typeof(a) == "Instance" and a:IsA("BasePart"), "Collisions.DisableForParts | a must be a BasePart")
	assert(typeof(b) == "Instance" and b:IsA("BasePart"), "Collisions.DisableForParts | b must be a BasePart")

	if not a.CanCollide or not b.CanCollide then
		return
	end

	local constraint = a:FindFirstChild(CONSTS.Constraint)
	if not enabled and not constraint then
		return
	end

	constraint = Constraints:Add(a, "NoCollisionConstraint", {
		Part0 = a,
		Part1 = b
	}, {
		Name = CONSTS.Constraint
	})

	if enabled then
		if not constraint.Enabled then
			constraint.Enabled = true
		end
	else
		constraint:Destroy()
		constraint = nil
	end
end

function m:RemoveFromGroup(object, name, fromModel)
	assert(typeof(object) == "Instance" and (object:IsA("BasePart") or object:IsA("Model")), "Collisions.RemoveFromGroup | object must be a BasePart or a Model")
	assert(type(name) == "string", "Collisions.RemoveFromGroup | name must be a string")

	-- verify
	local group = self.Groups[name]
	local found = group and table.find(group, object)

	if not group or (not fromModel and not found) then
		return
	end

	-- reset
	if object:IsA("Model") then
		for _, obj in object:GetDescendants() do
			if not obj:IsA("BasePart") then
				continue
			end

			self:RemoveFromGroup(obj, name, true)
		end
	else
		object.CollisionGroup = CONSTS.DefaultGroup
	end

	-- unregister
	if not fromModel then
		table.remove(group, found)

		if not next(group) then
			PhysicsService:UnregisterCollisionGroup(name)
			self.Groups[name] = nil
		end
	end
end

function m:AddToGroup(object, name, fromModel)
	assert(typeof(object) == "Instance" and (object:IsA("BasePart") or object:IsA("Model")), "Collisions.AddToGroup | object must be a BasePart or a Model")
	assert(type(name) == "string", "Collisions.AddToGroup | name must be a string")

	-- verify
	if not PhysicsService:IsCollisionGroupRegistered(name) or name == CONSTS.DefaultGroup then
		return
	end
	
	local group = self.Groups[name]
	if not group then
		group = {}
		self.Groups[name] = group
	end

	if not fromModel and table.find(group, object) then
		return
	end

	-- set
	if object:IsA("Model") then
		for _, obj in object:GetDescendants() do
			if not obj:IsA("BasePart") then
				continue
			end

			self:AddToGroup(obj, name, true)
		end
	else
		object.CollisionGroup = name
	end

	if not fromModel then
		table.insert(group, object)
	end
end

return m


]]
