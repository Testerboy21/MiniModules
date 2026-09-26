--[[
	Time:
		Manages simple conversion of base numbers to their respective timeframes.
]]

local m = {}

function m:SecondsToMinutes(seconds)
	assert(type(seconds) == "number", "Time.SecondsToMinutes | seconds must be a number")

	return seconds / 60
end

function m:SecondsToHours(seconds)
	assert(type(seconds) == "number", "Time.SecondsToHours | seconds must be a number")

	return self:SecondsToMinutes(seconds) / 60
end

function m:SecondsToDays(seconds)
	assert(type(seconds) == "number", "Time.SecondsToDays | seconds must be a number")

	return self:SecondsToHours(seconds) / 24
end

function m:MinutesToSeconds(minutes)
	assert(type(minutes) == "number", "Time.MinutesToSeconds | minutes must be a number")

	return minutes * 60
end

function m:HoursToSeconds(hours)
	assert(type(hours) == "number", "Time.HoursToSeconds | hours must be a number")

	return self:MinutesToSeconds(hours * 60)
end

function m:DaysToSeconds(days)
	assert(type(days) == "number", "Time.DaysToSeconds | days must be a number")

	return self:HoursToSeconds(days * 24)
end

return m
