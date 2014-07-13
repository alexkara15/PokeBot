local memory = {}

local memoryNames = {
	setting = {
		text_speed = 0x0D3D,
		battle_animation = 0x0D3E,
		battle_style = 0x0D3F,
		yellow_bitmask = 0x1354,
	},
	menu = {
		settings_row = 0x0C24,
		column = 0x0C25,
		row = 0x0C26,
		current = 0x1FFC,
		main_current = 0x0C27,
		input_row = 0x0C2A,
		size = 0x0C28,
		pokemon = 0x0C51,
		shop_current = 0x0C52,
		transaction_current = 0x0F8B,
		selection = 0x0C30,
		selection_mode = 0x0C35,
		scroll_offset = 0x0C36,
		text_input = 0x04B6,
		text_length = 0x0EE9,
		main = 0x1FF5,
	},
	player = {
		name = 0xD158,
		name2 = 0xD159,
		moving = 0x1528,
		x = 0xD362,
		y = 0xD361,
		facing = 0x152A,
		repel = 0x10DB,
		party_size = 0xD163,
	},
	game = {
		map = 0xD35E,
		frames = 0xDA45,
		battle = 0xD057,
		textbox = 0x0FC4,
	},
	shop = {
		transaction_amount = 0x0F96,
	},
	progress = {
		trashcans = 0x1773,
	},
	pokemon = {
		exp1 = 0xD179,
		exp2 = 0xD17A,
		exp3 = 0xD17B,
	},
	battle = {
		confused = 0x106B,
		turns = 0x1067,
		text = 0x1125,
		menu = 0x0C50,
		accuracy = 0x0D1E,
		x_accuracy = 0x1063,
		disabled = 0x0CEE,
		paralyzed = 0x1018,

		opponent_move = 0x0FEE,
		critical = 0x105E,

		opponent_bide = 0x106F,
		opponent_id = 0xCFE5,
		opponent_level = 0xCFF3,
		opponent_type1 = 0xCFEA,
		opponent_type2 = 0xCFEB,

		our_id = 0xD014,
		our_status = 0xD018,
		our_level = 0xD022,
		our_type1 = 0xD019,
		our_type2 = 0xD01A,
	},
}

local doubleNames = {
	pokemon = {
		attack = 0xD17E,
		defense = 0xD181,
		speed = 0xD183,
		special = 0xD185,
	},
	battle = {
		opponent_hp = 0xCFE6,
		opponent_max_hp = 0xCFF4,
		opponent_attack = 0xCFF6,
		opponent_defense = 0xCFF8,
		opponent_speed = 0xCFFA,
		opponent_special = 0xCFFC,

		our_hp = 0xD015,
		our_max_hp = 0xD023,
		our_attack = 0xD025,
		our_defense = 0xD027,
		our_speed = 0xD029,
		our_special = 0xD02B,
	},
}

local function raw(value)
	return mainmemory.readbyte(value)
end
memory.raw = raw

function memory.string(first, last)
	local a = "ABCDEFGHIJKLMNOPQRSTUVWXYZ():;[]abcdefghijklmnopqrstuvwxyz?????????????????????????????????????????-???!.????????*?/.?0123456789"
	local str = ""
	while first <= last do
		local v = raw(first) - 127
		if v < 1 then
			return str
		end
		str = str..string.sub(a, v, v)
		first = first + 1
	end
	return str
end

function memory.double(section, key)
	local first = doubleNames[section][key]
	return raw(first) + raw(first + 1)
end

function memory.value(section, key)
	local memoryAddress = memoryNames[section]
	if (key) then
		memoryAddress = memoryAddress[key]
	end
	return raw(memoryAddress)
end

return memory
