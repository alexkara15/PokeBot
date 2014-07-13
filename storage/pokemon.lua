local pokemon = {}

local bridge = require "util.bridge"
local input = require "util.input"
local memory = require "util.memory"
local menu = require "util.menu"
local utils = require "util.utils"

local pokeIDs = {
	rhydon = 1,
	kangaskhan = 2,
	nidoran = 3,
	spearow = 5,
	voltorb = 6,
	nidoking = 7,
	ivysaur = 9,
	gengar = 14,
	nidoranf = 15,
	nidoqueen = 16,
	cubone = 17,
	rhyhorn = 18,
	gyarados = 22,
	growlithe = 33,
	onix = 34,
	pidgey = 36,
	jinx = 72,
	meowth = 77,
	pikachu = 84,
	zubat = 107,
	ekans = 108,
	paras = 109,
	weedle = 112,
	kakuna = 113,
	dewgong = 120,
	caterpie = 123,
	metapod = 124,
	hypno = 129,
	weezing = 143,
	alakazam = 149,
	pidgeotto = 150,
	pidgeot = 151,
	rattata = 165,
	raticate = 166,
	nidorino = 167,
	geodude = 169,
	squirtle = 177,
	oddish = 185,
}

local moveList = {
	cut = 15,
	fly = 19,
	sand_attack = 28,
	horn_attack = 30,
	horn_drill = 32,
	tackle = 33,
	thrash = 37,
	tail_whip = 39,
	poison_sting = 40,
	leer = 43,
	growl = 45,
	water_gun = 55,
	surf = 57,
	ice_beam = 58,
	bubblebeam = 61,
	strength = 70,
	thunderbolt = 85,
	earthquake = 89,
	dig = 91,
	rock_slide = 157,
}

local data = {
	hp = {1, true},
	status = {4},
	moves = {8},
	level = {33},
	max_hp = {34, true},

	attack = {36, true},
	defense = {38, true},
	speed = {40, true},
	special = {42, true},
}

local function getAddress(index)
	return 0xD16B + index * 0x2C
end

local function index(index, offset)
	local double
	if (not offset) then
		offset = 0
	else
		local dataTable = data[offset]
		offset = dataTable[1]
		double = dataTable[2]
	end
	local address = getAddress(index) + offset
	local value = memory.raw(address)
	if (double) then
		value = value + memory.raw(address + 1)
	end
	return value
end
pokemon.index = index

local function indexOf(...)
	for ni,name in ipairs(arg) do
		local pid = pokeIDs[name]
		for i=0,5 do
			local atIdx = index(i)
			if (atIdx == pid) then
				return i
			end
		end
	end
	return -1
end
pokemon.indexOf = indexOf

-- Table functions

function pokemon.battleMove(name)
	local mid = moveList[name]
	for i=1,4 do
		if (mid == memory.raw(0xD01B + i)) then
			return i
		end
	end
end

function pokemon.moveIndex(move, pokemon)
	local pokemonIdx
	if (pokemon) then
		pokemonIdx = indexOf(pokemon)
	else
		pokemonIdx = 0
	end
	local address = getAddress(pokemonIdx) + 7
	local mid = moveList[move]
	for i=1,4 do
		if (mid == memory.raw(address + i)) then
			return i
		end
	end
end

function pokemon.info(name, offset)
	return index(indexOf(name), offset)
end

function pokemon.getID(name)
	return pokeIDs[name]
end

function pokemon.getName(id)
	for name,pid in pairs(pokeIDs) do
		if (pid == id) then
			return name
		end
	end
end

function pokemon.inParty(...)
	for i,name in ipairs(arg) do
		if (indexOf(name) ~= -1) then
			return name
		end
	end
end

function pokemon.forMove(move)
	local moveID = moveList[move]
	for i=0,5 do
		local address = getAddress(i)
		for j=8,11 do
			if (memory.raw(address + j) == moveID) then
				return i
			end
		end
	end
	return -1
end

function pokemon.hasMove(move)
	return pokemon.forMove(move) ~= -1
end

function pokemon.updateParty()
	local partySize = memory.value("player", "party_size")
	if (partySize ~= previousPartySize) then
		local poke = pokemon.inParty("oddish", "paras", "spearow", "pidgey", "nidoran", "squirtle")
		if (poke) then
			bridge.caught(poke)
			previousPartySize = partySize
		end
	end
end

-- General

function pokemon.isOpponent(...)
	local oid = memory.value("battle", "opponent_id")
	for i,name in ipairs(arg) do
		if (oid == pokeIDs[name]) then
			return name
		end
	end
end

function pokemon.isDeployed(...)
	for i,name in ipairs(arg) do
		if (memory.value("battle", "our_id") == pokeIDs[name]) then
			return name
		end
	end
end

function pokemon.isEvolving()
	return memory.value("menu", "pokemon") == 144
end

function pokemon.getExp()
	return memory.raw(0xD17A) * 256 + memory.raw(0xD17B)
end

function pokemon.inRedBar()
	local curr_hp, max_hp = index(0, "hp"), index(0, "max_hp")
	return curr_hp / max_hp <= 0.2
end

function pokemon.use(move)
	local main = memory.value("menu", "main")
	local pokeName = pokemon.forMove(move)
	if (main == 141) then
		input.press("A")
	elseif (main == 128) then
		local column = menu.getCol()
		if (column == 11) then
			menu.select(1, true)
		elseif (column == 10 or column == 12) then
			local midx = 0
			local menuSize = memory.value("menu", "size")
			if (menuSize == 4) then
				if (move == "dig") then
					midx = 1
				elseif (move == "surf") then
					if (pokemon.inParty("paras")) then
						midx = 1
					end
				end
			elseif (menuSize == 5) then
				if (move == "dig") then
					midx = 2
				elseif (move == "surf") then
					midx = 1
				end
			end
			menu.select(midx, true)
		else
			input.press("B")
		end
	elseif (main == 103) then
		menu.select(pokeName, true)
	elseif (main == 228) then
		input.press("B")
	else
		return false
	end
	return true
end

return pokemon
