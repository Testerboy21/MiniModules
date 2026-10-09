--[[
	Language:
		Manages player and region translations
]]

local UNIVERSE_ID = game.GameId

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")
local ServerScriptService = game:GetService("ServerScriptService")

local IS_SERVER = RunService:IsServer()
local IS_CLIENT = RunService:IsClient()

local Signal = require(ReplicatedStorage.Packages.Signal)

local API, signal = nil, nil

local m = {
	Changed = nil,

	Translators = {},
	Translations = {}
}

-- private
local function getTranslator(source)
	local region = type(source) == "string" and LocalizationService.GetTranslatorForLocaleAsync or LocalizationService.GetTranslatorForPlayerAsync
	local success, translator = pcall(region, LocalizationService, source)

	if not success then
		return nil
	end

	return translator
end

-- public
function m:TranslateStatic(source, text, context)
	assert(type(source) == "string" or typeof(source) == "Instance" and source:IsA("Player"), "Langauge.TranslateStatic | source must be a string or Player")
	assert(type(text) == "string", "Langauge.TranslateStatic | text must be a string")
	assert(typeof(context) == "Instance" or context == nil, "Langauge.TranslateFromLocalization | context must be an Instance or nil")

	local translator = self.Translators[source]
	local ctx = context or game

	if not translator then
		translator = getTranslator(source)
		if not translator then
			return nil
		end

		self.Translators[source] = translator
	end

	return translator:Translate(ctx, text)
end

function m:TranslateStaticFromKey(source, key, formatting)
	assert(type(source) == "string" or typeof(source) == "Instance" and source:IsA("Player"), "Langauge.TranslateStaticFromKey | source must be a string or Player")
	assert(type(key) == "string", "Langauge.TranslateStaticFromKey | key must be a string")
	assert(type(formatting) == "table" or formatting == nil, "Langauge.TranslateStaticFromKey | formatting must be a table or nil")

	local translator = self.Translators[source]

	if not translator then
		translator = getTranslator(source)
		if not translator then
			return nil
		end

		self.Translators[source] = translator
	end

	return translator:FormatByKey(key, formatting)
end

function m:TranslateDynamic(source, text)
	assert(type(source) == "string" or typeof(source) == "Instance" and source:IsA("Player"), "Langauge.TranslateDynamic | source must be a string or Player")
	assert(type(text) == "string", "Langauge.TranslateDynamic | text must be a string")

	if not API then
		return nil
	end

	local src = source
	if typeof(src) == "Instance" then
		src = source.LocaleId
	end

	local region = self.Translations[src]
	local translation = region and region[text]

	if translation then
		return translation
	end

	local body = API:FromCloud("TranslateText", "v2", {
		text = text,
		path = `universes/{UNIVERSE_ID}`,
		targetLanguageCodes = { src }
	}, nil, true)

	if not body or not body.translations then
		return nil
	end

	if not region then
		region = {}
		self.Translations[src] = region
	end

	translation = body.translations[src]
	region[text] = translation

	return translation
end

if IS_SERVER then
	API = require(ServerScriptService.Modules.API)

	Players.PlayerRemoving:Connect(function(player)
		if not m.Translators[player] then
			return
		end

		m.Translators[player] = nil
	end)
	
elseif IS_CLIENT then
	local player = Players.LocalPlayer
	local translator = m.Translators[player]

	signal = Signal.new()
	m.Changed = signal

	if not translator then
		translator = getTranslator(player)
		
		if translator then
			translator:GetPropertyChangedSignal("LocaleId"):Connect(function()
				signal:Fire(translator.LocaleId)
			end)

			m.Translators[player] = translator
		end
	end
end

return m
