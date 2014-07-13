-- Customization settings

GAME_NAME		= "red" -- Only currently supported option
RESET_FOR_TIME	= true	-- Set to false if you just want to see the bot finish a run

local CUSTOM_SEED	= nil -- Set to a known seed to replay it, or leave nil for random ones
local PAINT_ON		= true -- Displays contextual information while the bot runs

-- Start code (hard hats on)

local START_WAIT = 99
local VERSION = "1.0"

local battle = require "action.battle"
local textbox = require "action.textbox"
local walk = require "action.walk"

local combat = require "ai.combat"
local control = require "ai.control"
local strategies = require "ai.strategies"

local bridge = require "util.bridge"
local input = require "util.input"
local memory = require "util.memory"
local menu = require "util.menu"
local paint = require "util.paint"
local utils = require "util.utils"
local settings = require "util.settings"

local pokemon = require "storage.pokemon"

local YELLOW = GAME_NAME == "yellow"

local hasAlreadyStartedPlaying = false
local inBattle, oldSecs
local running = true
local previousPartySize = 0
local lastHP
local criticaled = false

local function startNewAdventure()
	local startMenu, withBattleStyle
	if (YELLOW) then
		startMenu = memory.raw(0x0F95) == 0
		withBattleStyle = "battle_style"
	else
		startMenu = memory.value("player", "name") ~= 0
	end
	if (startMenu and menu.getCol() ~= 0) then
		if (settings.set("text_speed", "battle_animation", withBattleStyle)) then
			menu.select(0)
		end
	elseif (math.random(0, START_WAIT) == 0) then
		input.press("Start")
	end
end

local function choosePlayerNames()
	local name
	if (memory.value("player", "name2") == 80) then
		name = "W"
	else
		name = "B"
	end
	textbox.name(name, true)
end

local function pollForResponse()
	local response = bridge.process()
	if (response) then
		bridge.polling = false
		textbox.setName(tonumber(response))
	end
end

local function resetAll()
	strategies.softReset()
	combat.reset()
	control.reset()
	walk.reset()
	paint.reset()
	bridge.reset()
	oldSecs = 0
	running = false
	previousPartySize = 0
	-- client.speedmode = 200
	if (CUSTOM_SEED) then
		strategies.seed = CUSTOM_SEED
		print("RUNNING WITH A FIXED SEED ("..strategies.seed.."), every run will play out identically!")
	else
		strategies.seed = os.time()
	end
	math.randomseed(strategies.seed)
end

-- Execute

print("Welcome to PokeBot "..GAME_NAME.." version "..VERSION)
local productionMode = not walk.init() and false
if (CUSTOM_SEED) then
	client.reboot_core()
else
	hasAlreadyStartedPlaying = utils.ingame()
end

strategies.init(hasAlreadyStartedPlaying)
if (RESET_FOR_TIME and hasAlreadyStartedPlaying) then
	RESET_FOR_TIME = false
	print("Disabling time-limit resets as the game is already running. Please reset the emulator and restart the script if you'd like to go for a fast time.")
end
if (productionMode) then
	bridge.init()
else
	input.setDebug(true)
end

local previousMap

while true do
	local currentMap = memory.value("game", "map")
	if (currentMap ~= previousMap) then
		input.clear()
		previousMap = currentMap
	end
	if (not input.update()) then
		if (not utils.ingame()) then
			if (currentMap == 0) then
				if (running) then
					if (not hasAlreadyStartedPlaying) then
						client.reboot_core()
						hasAlreadyStartedPlaying = true
					else
						resetAll()
					end
				else
					startNewAdventure()
				end
			else
				if (not running) then
					bridge.liveSplit()
					running = true
				end
				choosePlayerNames()
			end
		else
			local battleState = memory.value("game", "battle")
			if (battleState > 0) then
				if (battleState == 1) then
					if (not inBattle) then
						control.wildEncounter()
						if (strategies.moonEncounters) then
							strategies.moonEncounters = strategies.moonEncounters + 1
						end
						inBattle = true
					end
				end
				local isCritical
				local battleMenu = memory.value("battle", "menu")
				if (battleMenu == 94) then
					isCritical = false
				elseif (memory.double("battle", "our_hp") == 0) then
					if (memory.value("battle", "critical") == 1) then
						isCritical = true
					end
				end
				if (isCritical ~= nil and isCritical ~= criticaled) then
					criticaled = isCritical
					strategies.criticaled = criticaled
				end
			else
				inBattle = false
			end
			local currentHP = pokemon.index(0, "hp")
			if (currentHP == 0 and not strategies.canDie and pokemon.index(0) > 0) then
				strategies.death(currentMap)
			elseif (walk.strategy) then
				if (strategies.execute(walk.strategy)) then
					walk.traverse(currentMap)
				end
			elseif (battleState > 0) then
				if (not control.shouldCatch(partySize)) then
					battle.automate()
				end
			elseif (textbox.handle()) then
				walk.traverse(currentMap)
			end
		end
	end

	if (PAINT_ON) then
		paint.draw(currentMap)
	end

	input.advance()
	emu.frameadvance()
end

bridge.close()
