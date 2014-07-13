local shop = {}

local textbox = require "action.textbox"

local input = require "util.input"
local memory = require "util.memory"
local menu = require "util.menu"
local player = require "util.player"

local inventory = require "storage.inventory"

function shop.transaction(options)
	local item, itemMenu, menuIdx, quantityMenu
	if (options.sell) then
		menuIdx = 1
		itemMenu = 29
		quantityMenu = 158
		for i,sit in ipairs(options.sell) do
			local idx = inventory.indexOf(sit.name)
			if (idx ~= -1) then
				item = sit
				item.index = idx
				item.amount = inventory.count(sit.name)
				break
			end
		end
	end
	if (not item and options.buy) then
		menuIdx = 0
		itemMenu = 123
		quantityMenu = 161
		for i,bit in ipairs(options.buy) do
			local needed = (bit.amount or 1) - inventory.count(bit.name)
			if (needed > 0) then
				item = bit
				item.amount = needed
				break
			end
		end
	end
	if (not item) then
		if (not textbox.isActive()) then
			return true
		end
		input.press("B")
	elseif (player.isFacing(options.direction or "Left")) then
		if (textbox.isActive()) then
			if (menu.isCurrently(32, "shop")) then
				menu.select(menuIdx, true, false, "shop")
			elseif (menu.getCol() == 15) then
				input.press("A")
			elseif (menu.isCurrently(itemMenu, "transaction")) then
				if (menu.select(item.index, "accelerate", true, "transaction", true)) then
					if (menu.isCurrently(quantityMenu, "shop")) then
						local currAmount = memory.value("shop", "transaction_amount")
						if (menu.balance(currAmount, item.amount, false, 99, true)) then
							input.press("A")
						end
					else
						input.press("A")
					end
				end
			else
				input.press("B")
			end
		else
			input.press("A", 2)
		end
	else
		player.interact(options.direction or "Left")
	end
	return false
end

function shop.vend(options)
	local item
	menuIdx = 0
	for i,bit in ipairs(options.buy) do
		local needed = (bit.amount or 1) - inventory.count(bit.name)
		if (needed > 0) then
			item = bit
			item.buy = needed
			break
		end
	end
	if (not item) then
		if (not textbox.isActive()) then
			return true
		end
		input.press("B")
	elseif (player.face(options.direction)) then
		if (textbox.isActive()) then
			if (memory.value("battle", "text") > 1 and memory.value("battle", "menu") ~= 95) then
				menu.select(item.index, true)
			else
				input.press("A")
			end
		else
			input.press("A", 2)
		end
	end
	return false
end

return shop
