--[[
	Geometry:
		Manages in-experience constructive solid geometry (CSG)
]]

local GeometryService = game:GetService("GeometryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constraints = require(ReplicatedStorage.Modules.Constraints)

local m = {}

local function perform(operation, on, from, options)
	local f = GeometryService[`{operation}Async`]
	if not f then
		return nil
	end

	local parts = from
	if typeof(from) == "Instance" then
		parts = { from }
	else
		for index, part in parts do
			if typeof(part) == "Instance" and (part:IsA("Part") or part:IsA("PartOperation")) then
				continue
			end

			parts[index] = nil
		end

		if not next(parts) then
			return nil
		end
	end

	local success, operations = pcall(function()
		return f(GeometryService, on, parts, options)
	end)

	if not success then
		warn(`Geometry.perform | attempt to {operation} {on} and {from} failed: {operations}`)
	end
	
	return (success and next(operations) and operations) or nil
end

function m:AdjustConstraints(from, to, options)
	assert(typeof(from) == "Instance" and from:IsA("Part"), "Geometry.AdjustConstraints | from must be a Part")
	assert(typeof(to) == "Instance" and to:IsA("PartOperation") or type(to) == "table", "Geometry.AdjustConstraints | to must be a PartOperation or table")
	assert(type(options) == "table" or options == nil, "Geometry.AdjustConstraints | options must be a table")

	local parts = to
	if typeof(from) == "Instance" then
		parts = { to }
	else
		for index, part in parts do
			if typeof(part) == "Instance" and (part:IsA("Part") or part:IsA("PartOperation")) then
				continue
			end

			parts[index] = nil
		end

		if not next(parts) then
			return
		end	
	end
	
	for _, info in GeometryService:CalculateConstraintsToPreserve(from, parts) do
		if info.Attachment then
			info.Attachment.Parent = info.AttachmentParent

			if info.Constraint then
				info.Constraint.Parent = info.ConstraintParent
			end

		elseif info.WeldConstraint then
			local hasParent = info.WeldConstraintParent

			if not hasParent then
				info.WeldConstraint.Parent = nil
			else
				Constraints:Add(hasParent, "WeldConstraint", {
					Part0 = info.WeldConstraintPart0,
					Part1 = info.WeldConstraintPart1
				})
			end

		elseif info.NoCollisionConstraint then
			local hasParent = info.NoCollisionParent

			if not hasParent then
				info.NoCollisionConstraint.Parent = nil
			else
				Constraints:Add(hasParent, "NoCollisionConstraint", {
					Part0 = info.NoCollisionPart0,
					Part1 = info.NoCollisionPart1
				})
			end
		end
	end
end

function m:Union(part, from, options)
	assert(typeof(part) == "Instance" and (part:IsA("Part") or part:IsA("PartOperation")), "Geometry.Union | part must be a Part or PartOperation")
	assert(typeof(from) == "Instance" and (from:IsA("Part") or from:IsA("PartOperation")) or type(from) == "table", "Geometry.Union | from must be a Part or a PartOperation or table")
	assert(type(options) == "table" or options == nil, "Geometry.Union | options must be a table")

	return perform("Union", part, from, options)
end

function m:Subtract(part, from, options)
	assert(typeof(part) == "Instance" and (part:IsA("Part") or part:IsA("PartOperation")), "Geometry.Subtract | part must be a Part or PartOperation")
	assert(typeof(from) == "Instance" and (from:IsA("Part") or from:IsA("PartOperation")) or type(from) == "table", "Geometry.Subtract | from must be a Part or a PartOperation or table")
	assert(type(options) == "table" or options == nil, "Geometry.Subtract | options must be a table")

	return perform("Subtract", part, from, options)
end

function m:Intersect(part, from, options)
	assert(typeof(part) == "Instance" and (part:IsA("Part") or part:IsA("PartOperation")), "Geometry.Intersect | part must be a Part or PartOperation")
	assert(typeof(from) == "Instance" and (from:IsA("Part") or from:IsA("PartOperation")) or type(from) == "table", "Geometry.Intersect | from must be a Part or a PartOperation or table")
	assert(type(options) == "table" or options == nil, "Geometry.Intersect | options must be a table")

	return perform("Intersect", part, from, options)
end

return m
