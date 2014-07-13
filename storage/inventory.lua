local inventory = {}

local pokemon = require "storage.pokemon"

local input = require "util.input"
local memory = require "util.memory"
local menu = require "util.menu"
local utils = require "util.utils"

local items = {
	pokeball = 4,
	bicycle = 6,
	moon_stone = 10,
	antidote = 11,
	paralyze_heal = 15,
	full_restore = 16,
	super_potion = 19,
	potion = 20,
	escape_rope = 29,
	carbos = 38,
	repel = 30,

	rare_candy = 40,
	helix_fossil = 42,
	nugget = 49,
	pokedoll = 51,
	super_repel = 56,
	fresh_water = 60,
	soda_pop = 61,
	pokeflute = 73,
	ether = 80,
	max_ether = 81,
	elixer = 82,

	x_accuracy = 46,
	x_speed = 67,
	x_special = 68,

	cut = 196,
	fly = 197,
	surf = 198,
	strength = 199,

	horn_drill = 207,
	bubblebeam = 211,
	water_gun = 212,
	ice_beam = 213,
	thunderbolt = 224,
	earthquake = 226,
	dig = 228,
	tm34 = 234,
	rock_slide = 248,
}

local ITEM_BASE = 0xD31E

-- Data

function inventory.indexOf(name)
	local searchID = items[name]
	for i=0,19 do
		local iidx = ITEM_BASE + i * 2
		if (memory.raw(iidx) == searchID) then
			return i
		end
	end
	return -1
end

function inventory.count(name)
	local index = inventory.indexOf(name)
	if (index ~= -1) then
		return memory.raw(ITEM_BASE + index * 2 + 1)
	end
	return 0
end

function inventory.contains(...)
	for i,name in ipairs(arg) do
		if (inventory.count(name) > 0) then
			return name
		end
	end
end

-- Actions

function inventory.teach(item, poke, replaceIdx, altPoke)
	local main = memory.value("menu", "main")
	local column = menu.getCol()
	if (main == 144) then
		if (column == 5) then
			menu.select(replaceIdx, true)
		else
			input.press("A")
		end
	elseif (main == 128) then
		if (column == 5) then
			menu.select(inventory.indexOf(item), "accelerate", true)
		elseif (column == 11) then
			menu.select(2, true)
		elseif (column == 14) then
			menu.select(0, true)
		end
	elseif (main == 103) then
		input.press("B")
	elseif (main == 64 or main == 96 or main == 192) then
		if (column == 5) then
			menu.select(replaceIdx, true)
		elseif (column == 14) then
			input.press("A")
		elseif (column == 15) then
			menu.select(0, true)
		else
			local idx = 0
			if (poke) then
				idx = pokemon.indexOf(poke, altPoke)
			end
			menu.select(idx, true)
		end
	else
		return false
	end
	return true
end

function inventory.isFull()
	return memory.raw(0xD345) > 0
end

function inventory.use(item, poke, midfight)
	if (midfight) then
		local battleMenu = memory.value("battle", "menu")
		if (battleMenu == 94) then
			local rowSelected = memory.value("menu", "row")
			if (menu.getCol() == 9) then
				if (rowSelected == 0) then
					input.press("Down")
				else
					input.press("A")
				end
			else
				input.press("Left")
			end
		elseif (battleMenu == 233) then
			menu.select(inventory.indexOf(item), "accelerate", true)
		elseif (utils.onPokemonSelect(battleMenu)) then
			if (poke) then
				if (type(poke) == "string") then
					poke = pokemon.indexOf(poke)
				end
				menu.select(poke, true)
			else
				input.press("A")
			end
		else
			input.press("B")
		end
		return
	end

	local main = memory.value("menu", "main")
	local column = menu.getCol()
	if (main == 144) then
		if (memory.value("battle", "menu") == 95) then
			input.press("B")
		else
			local idx = 0
			if (poke) then
				idx = pokemon.indexOf(poke)
			end
			menu.select(idx, true)
		end
	elseif (main == 128 or main == 60) then
		if (column == 5) then
			menu.select(inventory.indexOf(item), "accelerate", true)
		elseif (column == 11) then
			menu.select(2, true)
		elseif (column == 14) then
			menu.select(0, true)
		else
			local index = 0
			if (poke) then
				index = pokemon.indexOf(poke)
			end
			menu.select(index, true)
		end
	elseif (main == 228) then
		if (column == 14 and memory.value("battle", "menu") == 95) then
			input.press("B")
		end
	elseif (main == 103) then
		input.press("B")
	else
		return false
	end
	return true
end

return inventory
