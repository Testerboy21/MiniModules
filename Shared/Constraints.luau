local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()
local IS_CLIENT = RunService:IsClient()

local signal = IS_SERVER and Instance.new("RemoteEvent") or script:FindFirstChild("RemoteEvent")

local m = {}

local function onLocal(assembly, name, properties, attributes)
	return m:Add(assembly, name, properties, attributes)
end

function m:Add(assembly, name, properties, attributes, onClient)
	assert(typeof(assembly) == "Instance" and (assembly:IsA("BasePart") or assembly:IsA("Model")), "Constraints.Add | assembly must be a BasePart or Model")
	assert(type(name) == "string", "Constraints.Add | name must be a string")
	assert(type(properties) == "table", "Constraints.Add | properties must be a table")
	assert(type(attributes) == "table" or attributes == nil, "Constraints.Add | attributes must be a table or nil")

	if IS_SERVER and onClient then
		if type(onClient) == "boolean" and onClient then
			signal:FireAllClients(assembly, name, properties, attributes)

		elseif typeof(onClient) == "Instance" and onClient:IsA("Player") then
			signal:FireClient(onClient, assembly, name, properties, attributes)
		end

		return nil
	end

	-- verify
	local attrs = attributes or {}
	local parent, override = assembly, attrs.Parent

	if typeof(override) == "Instance" and override:IsA("PVInstance") and override:IsDescendantOf(assembly) then
		parent = override
	end

	local success, new = pcall(Instance.new, name)
	if not success or not (new:IsA("Constraint") or name:find("Constraint") or new:IsA("BodyMover")) then
		return nil
	end

	local constraint = new
	local tag = attrs.Name or `Constraints.{name}`

	-- properties
	for key, value in properties do
		if key == "Attachment0" then
			continue
		end

		pcall(function()
			constraint[key] = value
		end)
	end

	local toAttachment = false
	local attachment = Instance.new("Attachment")

	toAttachment = pcall(function()
		constraint.Attachment0 = attachment
	end)

	if toAttachment then
		if parent ~= override and assembly:IsA("Model") then
			parent = assembly.PrimaryPart

			if not parent then
				attachment:Destroy()
				attachment = nil

				constraint:Destroy()
				constraint = nil

				return nil
			end
		end

		constraint.Parent = attachment

		attachment.Name = tag
		attachment.Parent = parent

		if attrs.ApplyAtCenterOfMass then
			attachment.WorldPosition = parent.AssemblyCenterOfMass
		end
	else
		attachment:Destroy()
		attachment = nil

		constraint.Name = tag
		constraint.Parent = parent
	end

	return attachment or constraint
end

if IS_SERVER then
	signal.Parent = script
elseif IS_CLIENT and signal then
	signal.OnClientEvent:Connect(onLocal)
end

return m
