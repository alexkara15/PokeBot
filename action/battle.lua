local battle = {}

local textbox = require "action.textbox"

local combat = require "ai.combat"
local control = require "ai.control"

local memory = require "util.memory"
local menu = require "util.menu"
local input = require "util.input"
local utils = require "util.utils"

local inventory = require "storage.inventory"
local pokemon = require "storage.pokemon"

local function potionsForHit(potion, currHP, maxHP)
	if (not potion) then
		return
	end
	local ours, killAmount = combat.inKillRange()
	if (ours) then
		local potionHP
		if (potion == "full_restore") then
			potionHP = 999
		elseif (potion == "super_potion") then
			potionHP = 50
		else
			potionHP = 20
		end
		if (not currHP) then
			currHP = pokemon.index(0, "hp")
			maxHP = pokemon.index(0, "max_hp")
		end
		return math.min(currHP + potionHP, maxHP) >= killAmount - 2
	end
end
battle.potionsForHit = potionsForHit

local function recover()
	if (control.canRecover()) then
		local currentHP = pokemon.index(0, "hp")
		if (currentHP > 0) then
			local maxHP = pokemon.index(0, "max_hp")
			if (currentHP < maxHP) then
				local first, second
				if (potionIn == "full") then
					first, second = "full_restore", "super_potion"
					if (maxHP - currentHP > 54) then
						first = "full_restore"
						second = "super_potion"
					else
						first = "super_potion"
						second = "full_restore"
					end
				else
					if (maxHP - currentHP > 22) then
						first = "super_potion"
						second = "potion"
					else
						first = "potion"
						second = "super_potion"
					end
				end
				local potion = inventory.contains(first, second)
				if (potionsForHit(potion, currentHP, maxHP)) then
					inventory.use(potion, nil, true)
					return true
				end
			end
		end
	end
	if (memory.value("battle", "paralyzed") == 64) then
		local heals = inventory.contains("paralyze_heal", "full_restore")
		if (heals) then
			inventory.use(heals, nil, true)
			return true
		end
	end
end

local function openBattleMenu()
	if (memory.value("battle", "text") == 1) then
		input.cancel()
		return false
	end
	local battleMenu = memory.value("battle", "menu")
	local col = menu.getCol()
	if (battleMenu == 106 or (battleMenu == 94 and col == 5)) then
		return true
	elseif (battleMenu == 94) then
		local rowSelected = memory.value("menu", "row")
		if (col == 9) then
			if (rowSelected == 1) then
				input.press("Up")
			else
				input.press("A")
			end
		else
			input.press("Left")
		end
	else
		input.press("B")
	end
end

local function attack(attackIndex)
	if (memory.double("battle", "opponent_hp") < 1) then
		input.cancel()
	elseif (openBattleMenu()) then
		menu.select(attackIndex, true, false, false, false, 3)
	end
end

-- Table functions

function battle.swapMove(sidx, fidx)
	if (openBattleMenu()) then
		local selection = memory.value("menu", "selection_mode")
		local swapSelect
		if (selection == sidx) then
			swapSelect = fidx
		else
			swapSelect = sidx
		end
		if (menu.select(swapSelect, false, false, nil, true, 3)) then
			input.press("Select")
		end
	end
end

function battle.isActive()
	return memory.value("game", "battle") > 0
end

function battle.isTrainer()
	local battleType = memory.value("game", "battle")
	if (battleType == 2) then
		return true
	end
	if (battleType == 1) then
		battle.run()
	else
		textbox.handle()
	end
end

function battle.opponent()
	return pokemon.getName(memory.value("battle", "opponent_id"))
end

function battle.run()
	if (memory.double("battle", "opponent_hp") < 1) then
		input.cancel()
	elseif (memory.value("battle", "menu") ~= 94) then
		if (memory.value("menu", "text_length") == 127) then
			input.press("B")
		else
			input.cancel()
		end
	elseif (textbox.handle()) then
		local selected = memory.value("menu", "selection")
		if (selected == 239) then
			input.press("A", 2)
		else
			input.escape()
		end
	end
end

function battle.handleWild()
	if (memory.value("game", "battle") ~= 1) then
		return true
	end
	battle.run()
end

function battle.fight(move, isNumber, skipBuffs)
	if (move) then
		if (not isNumber) then
			move = pokemon.battleMove(move)
		end
		attack(move)
	else
		move = combat.bestMove()
		if (move) then
			attack(move.midx)
		elseif (memory.value("menu", "text_length") == 127) then
			print("Faito B!")
			input.press("B")
		else
			input.cancel()
		end
	end
end

function battle.swap(target)
	local battleMenu = memory.value("battle", "menu")
	if (utils.onPokemonSelect(battleMenu)) then
		if (menu.getCol() == 0) then
			menu.select(pokemon.indexOf(target), true)
		else
			input.press("A")
		end
	elseif (battleMenu == 94) then
		local selected = memory.value("menu", "selection")
		if (selected == 199) then
			input.press("A", 2)
		elseif (menu.getCol() == 9) then
			input.press("Right", 0)
		else
			input.press("Up", 0)
		end
	else
		input.cancel()
	end
end

function movePP(name)
	local midx = pokemon.battleMove(name)
	if (not midx) then
		return 0
	end
	return memory.raw(0xD02C + midx)
end
battle.pp = movePP

function battle.automate(moveName, skipBuffs)
	if (not recover()) then
		local state = memory.value("game", "battle")
		if (state == 0) then
			input.cancel()
		else
			if (moveName and movePP(moveName) == 0) then
				moveName = nil
			end
			if (state == 1) then
				if (control.shouldFight()) then
					battle.fight(moveName, false, skipBuffs)
				else
					battle.run()
				end
			elseif (state == 2) then
				battle.fight(moveName, false, skipBuffs)
			end
		end
	end
end

return battle
