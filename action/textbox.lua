local textbox = {}

local input = require "util.input"
local memory = require "util.memory"
local menu = require "util.menu"
local utils = require "util.utils"

local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ *():;[]ポモ-?!♂♀/.,"

local nidoName = "A"
local nidoIdx = 1

local function getLetterAt(index)
	return alphabet[index]
end

local function getIndexForLetter(letter)
	return alphabet:find(letter, 1, true)
end

function textbox.name(letter, randomize)
	local inputting = memory.value("menu", "text_input") == 240
	if (inputting) then
		if (memory.value("menu", "text_length") > 0) then
			input.press("Start")
			return true
		end
		local lidx
		if (letter) then
			lidx = getIndexForLetter(letter)
		else
			lidx = nidoIdx
		end

		local crow = memory.value("menu", "input_row")
		local drow = math.ceil(lidx / 9)
		if (menu.balance(crow, drow, true, 6, true)) then
			local ccol = math.floor(memory.value("menu", "column") / 2)
			local dcol = math.fmod(lidx - 1, 9)
			if (menu.sidle(ccol, dcol, 9, true)) then
				input.press("A")
			end
		end
	else
		-- TODO cancel more when menu isn't up
		if (memory.raw(0x10B7) == 3) then
			input.press("A", 2)
		elseif (randomize) then
			input.press("A", math.random(1, 5))
		else
			input.cancel()
		end
	end
end

function textbox.getName()
	return nidoName
end

function textbox.setName(index)
	nidoIdx = index + 1
	nidoName = getLetterAt(index)
end

function textbox.isActive()
	return memory.value("game", "textbox") == 1
end

function textbox.handle()
	if (not textbox.isActive()) then
		return true
	end
	input.cancel()
end


return textbox
