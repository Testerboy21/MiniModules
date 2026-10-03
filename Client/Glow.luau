--[[
	Glow:
		Manages world highlights
]]

local m = {
	Glowing = {}
}

local function isUnderGlow(object: PVInstance)
	local isUnder = false

	for glow, _ in m.Glowing do
		isUnder = object:IsDescendantOf(glow)
		if isUnder then
			break
		end
	end

	return isUnder
end

function m:Get(object: PVInstance)
	local info = self.Glowing[object]
	if not info then
		return nil
	end

	return info.Glow
end

function m:Remove(object: PVInstance)
	local info = self.Glowing[object]
	if not info then
		return
	end

	if info.Glow then
		info.Glow:Destroy()
	end

	if info.Connection then
		info.Connection:Disconnect()
	end

	self.Glowing[object] = nil
end

function m:Modify(object: PVInstance, properties: { [string]: any })
	local glow = self:Get(object)
	if not glow then
		return
	end

	for key, value in properties do
		if key == "Adornee" then
			continue
		end

		pcall(function()
			glow[key] = value
		end)
	end
end

function m:Apply(object: PVInstance, properties: { [string]: any })
	if isUnderGlow(object) then
		return nil
	end

	local info = self.Glowing[object]
	if info then
		return info.Glow
	end

	local glow = Instance.new("Highlight")
	for key, value in properties do
		if key == "Adornee" then
			continue
		end

		pcall(function()
			glow[key] = value
		end)
	end

	info = {}
	info.Glow = glow

	info.Connection = object.AncestryChanged:Connect(function(child, parent)
		if parent == nil or not glow then
			return
		end

		if isUnderGlow(child) then
			glow.Parent = nil
		elseif glow.Parent ~= child then
			glow.Parent = child
		end
	end)

	glow.Parent = object
	self.Glowing[object] = info

	return glow
end

return m
