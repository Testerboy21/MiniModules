--[[
	Moderation:
		Handles everything related to player moderation
]]

local CONSTS = {
	Flags = {
		Manual = 1,
		Automatic = 2
	},

	PermanentBan = -1,
	Message = "You have been banned. If you believe this is a mistake, feel free to contact us on any of our social media!",
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Time = require(ReplicatedStorage.Modules.Time)

local m = {}

function m:Kick(player, message)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Moderation.Kick | player must be a Player")
	assert(type(message) == "string" or message == nil, "Moderation.Kick | message must be a string or nil")

	return player:Kick(message)
end

function m:Unban(id)
	assert(type(id) == "number", "Moderation.Unban | id must be a number")

	local success, msg = pcall(Players.UnbanAsync, Players, { UserIds = { id } })
	if not success then
		warn(`Moderation.Unban | attempt to unban player failed: {msg}`)
	end

	return success
end

function m:Ban(id, reason, length, includeAlts, flag)
	assert(type(id) == "number", "Moderation.Ban | id must be a number")
	assert(type(reason) == "string", "Moderation.Ban | reason must be a string")
	assert(type(length) == "number" or length == nil, "Moderation.Ban | length must be a number or nil")
	assert(type(includeAlts) == "boolean" or includeAlts == nil, "Moderation.Ban | includeAlts must be a boolean or nil")
	assert(type(flag) == "number" or flag == nil, "Moderation.Ban | flag must be a number or nil")

	-- verify
	local valid = false
	for identifier, value in CONSTS.Flags do
		valid = flag == value

		if valid then
			break
		end
	end

	flag = valid and flag or CONSTS.Flags.Manual
	length = length and Time:DaysToSeconds(length) or CONSTS.PermanentBan

	-- execute
	local success, msg = pcall(Players.BanAsync, Players, {
		UserIds = { id },
		Duration = length,
		DisplayReason = CONSTS.Message,
		ExcludeAltAccounts = not includeAlts,
		PrivateReason = reason:match("^%s*$") and tostring(flag) or `{flag} | {reason}`
	})

	if not success then
		warn(`Moderation.Ban | attempt to ban player failed: {msg}`)
	end

	return success
end

function m:GetHistory(id, page)
	assert(type(id) == "number", "Moderation.GetHistory | id must be a UserId")
	assert(type(page) == "number" and page > 0 or page == nil, "Moderation.GetHistory | page must be a positive number or nil")

	local history = pcall(Players.GetBanHistoryAsync, Players, id)
	if not history then
		return nil
	end

	local getAll = not page
	local pages = getAll and {} or nil

	local index = 1

	while true do
		local current = history:GetCurrentPage()
		if pages then
			table.insert(pages, current)
		elseif index == page then
			pages = current
			break
		end

		index += 1

		local finished = history.IsFinished
		local nextPage = pcall(history.AdvanceToNextPageAsync, history)

		if finished or not nextPage then
			break
		end
	end

	return pages
end

return m
