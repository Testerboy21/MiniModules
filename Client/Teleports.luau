local TeleportService = game:GetService("TeleportService")

local m = {}

function m:SetScreen(gui: ScreenGui)
	return TeleportService:SetTeleportGui(gui)
end

function m:GetGlobalMetadata()
	return TeleportService:GetLocalPlayerTeleportData()
end

function m:GetLocalMetadata(name: string)
	return TeleportService:GetTeleportSetting(name)
end

function m:SetLocalMetadata(name: string, value: string | number | boolean | ({[string]: any} | {[number]: any}))
	return TeleportService:SetTeleportSetting(name, value)
end

return m
