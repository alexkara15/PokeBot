local control = {}

local combat = require "ai.combat"

local bridge = require "util.bridge"
local memory = require "util.memory"
local menu = require "util.menu"
local paint = require "util.paint"
local player = require "util.player"
local utils = require "util.utils"

local inventory = require "storage.inventory"
local pokemon = require "storage.pokemon"

local game_controls

local shouldFight, minExp, skipHiker
local shouldCatch, attackIdx
local encounters = 0, extraEncounter
local potionIn = true
local fightEncounter, caveFights = 0, 0
local maxEncounters
local isYolo, battleYolo

local function battlePotion(enable)
	potionIn = enable
end
control.battlePotion = battlePotion

local controlFunctions = {
	potion = function(data)
		if (data.b ~= nil) then
			battlePotion(data.b)
		end
		battleYolo = data.yolo
	end,

	encounters = function(data)
		if (RESET_FOR_TIME) then
			maxEncounters = data.limit
			extraEncounter = data.extra
		end
	end,

	pp = function(data)
		combat.factorPP(data.on)
	end,

	setThrash = function(data)
		combat.disableThrash = data.disable
	end,

	disableCatch = function()
		shouldCatch = nil
		shouldFight = nil
	end,

-- RED

	viridianExp = function()
		minExp = 210
		shouldFight = {{name="rattata",lvl={2,3}}, {name="pidgey",lvl={2}}}
	end,

	viridianBackupExp = function()
		minExp = 210
		shouldFight = {{name="rattata",lvl={2,3}}, {name="pidgey",lvl={2,3}}}
	end,

	nidoranBackupExp = function()
		minExp = 210
		shouldFight = {{name="rattata"}, {name="pidgey"}, {name="nidoran"}, {name="nidoranf",lvl={2}}}
	end,

	moon1Exp = function()
		if (skipHiker) then
			minExp = 2704
			shouldFight = {{name="zubat",lvl={9,10}}, {name="geodude"}}
			oneHits = true
		end
	end,

	moon2Exp = function()
		if (skipHiker) then
			minExp = 3011
			shouldFight = {{name="zubat"}, {name="geodude"}, {name="paras"}}
		end
	end,

	moon3Exp = function()
		if (skipHiker) then
			minExp = 3798
		end
	end,

	catchNidoran = function()
		shouldCatch = {{name="nidoran",lvl={3,4}}, {name="spearow"}}
	end,

	catchFlier = function()
		shouldCatch = {{name="spearow",alt="pidgey",hp=15}, {name="pidgey",alt="spearow",hp=15}}
	end,

	catchParas = function()
		shouldCatch = {{name="paras",hp=16}}
	end,

	catchOddish = function()
		shouldCatch = {{name="oddish",alt="paras",hp=26}}
	end,

}

-- Combat

local function isNewFight()
	if (fightEncounter < encounters and memory.double("battle", "opponent_hp") == memory.double("battle", "opponent_max_hp")) then
		fightEncounter = encounters
		return true
	end
end


function control.shouldFight()
	if (not shouldFight) then
		return false
	end
	local expTotal = pokemon.getExp()
	if (expTotal < minExp) then
		local oid = memory.value("battle", "opponent_id")
		local olvl = memory.value("battle", "opponent_level")
		for i,p in ipairs(shouldFight) do
			if (oid == pokemon.getID(p.name) and (not p.lvl or utils.match(olvl, p.lvl))) then
				if (oneHits) then
					local move = combat.bestMove()
					if (move and move.maxDamage * 0.925 < memory.double("battle", "opponent_hp")) then
						return false
					end
				end
				return true
			end
		end
	end
end

function control.canCatch(partySize)
	if (not partySize) then
		partySize = memory.value("player", "party_size")
	end
	local pokeballs = inventory.count("pokeball")
	local minimumCount = 4 - partySize
	if (pokeballs < minimumCount) then
		require("ai.strategies").reset("Not enough PokeBalls", pokeballs)
		return false
	end
	return true
end

function control.shouldCatch(partySize)
	if (maxEncounters and encounters > maxEncounters) then
		local extraCount = extraEncounter and pokemon.inParty(extraEncounter)
		if (not extraCount or encounters > maxEncounters + 1) then
			require("ai.strategies").reset("Too many encounters", encounters)
			return false
		end
	end
	if (not shouldCatch) then
		return false
	end
	if (not partySize) then
		partySize = memory.value("player", "party_size")
	end
	if (partySize == 4) then
		shouldCatch = nil
		return false
	end
	if (not control.canCatch(partySize)) then
		return true
	end
	local oid = memory.value("battle", "opponent_id")
	for i,poke in ipairs(shouldCatch) do
		if (oid == pokemon.getID(poke.name) and not pokemon.inParty(poke.name, poke.alt)) then
			if (not poke.lvl or utils.match(memory.value("battle", "opponent_level"), poke.lvl)) then
				local penultimate = poke.hp and memory.double("battle", "opponent_hp") > poke.hp
				if (penultimate) then
					penultimate = combat.nonKill()
				end
				if (penultimate) then
					require("action.battle").fight(penultimate.midx, true)
				else
					inventory.use("pokeball", nil, true)
				end
				return true
			end
		end
	end
end

-- Items

function control.canRecover()
	return potionIn and (not battleYolo or not isYolo)
end

function control.set(data)
	controlFunctions[data.c](data)
end

function control.setYolo(enabled)
	isYolo = enabled
end

function control.setPotion(enabled)
	potionIn = enabled
end

function control.encounters()
	return encounters
end

function control.mtMoonExp()
	print("Skipping Hiker strats")
	skipHiker = true
end

function control.wildEncounter()
	encounters = encounters + 1
	paint.wildEncounters(encounters)
	bridge.encounter()
end

function control.reset()
	oneHits = false
	shouldCatch = nil
	shouldFight = nil
	extraEncounter = nil
	skipHiker = false
	potionIn = true
	encounters = 0
	fightEncounter = 0
	caveFights = 0
	battleYolo = false
	isYolo = false
	maxEncounters = nil
end

return control
