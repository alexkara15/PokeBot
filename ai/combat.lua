local combat = {}

local movelist = require "data.movelist"
local opponents = require "data.opponents"

local memory = require "util.memory"
local utils = require "util.utils"

local damageMultiplier = { -- http://bulbapedia.bulbagarden.net/wiki/Type_chart#Generation_I
	normal   = {normal=1.0, fighting=1.0, flying=1.0, poison=1.0, ground=1.0, rock=0.5, bug=1.0, ghost=0.0, fire=1.0, water=1.0, grass=1.0, electric=1.0, psychic=1.0, ice=1.0, dragon=1.0, },
	fighting = {normal=2.0, fighting=1.0, flying=0.5, poison=0.5, ground=1.0, rock=2.0, bug=0.5, ghost=0.0, fire=1.0, water=1.0, grass=1.0, electric=1.0, psychic=0.5, ice=2.0, dragon=1.0, },
	flying   = {normal=1.0, fighting=2.0, flying=1.0, poison=1.0, ground=1.0, rock=0.5, bug=2.0, ghost=1.0, fire=1.0, water=1.0, grass=2.0, electric=0.5, psychic=1.0, ice=1.0, dragon=1.0, },
	poison   = {normal=1.0, fighting=1.0, flying=1.0, poison=0.5, ground=0.5, rock=0.5, bug=2.0, ghost=0.5, fire=1.0, water=1.0, grass=2.0, electric=1.0, psychic=1.0, ice=1.0, dragon=1.0, },
	ground   = {normal=1.0, fighting=1.0, flying=0.0, poison=2.0, ground=1.0, rock=2.0, bug=0.5, ghost=1.0, fire=2.0, water=1.0, grass=0.5, electric=2.0, psychic=1.0, ice=1.0, dragon=1.0, },
	rock     = {normal=1.0, fighting=0.5, flying=2.0, poison=1.0, ground=0.5, rock=1.0, bug=2.0, ghost=1.0, fire=2.0, water=1.0, grass=1.0, electric=1.0, psychic=1.0, ice=2.0, dragon=1.0, },
	bug      = {normal=1.0, fighting=0.5, flying=0.5, poison=2.0, ground=1.0, rock=1.0, bug=1.0, ghost=0.5, fire=0.5, water=1.0, grass=2.0, electric=1.0, psychic=2.0, ice=1.0, dragon=1.0, },
	ghost    = {normal=0.0, fighting=1.0, flying=1.0, poison=1.0, ground=1.0, rock=1.0, bug=1.0, ghost=2.0, fire=1.0, water=1.0, grass=1.0, electric=1.0, psychic=0.0, ice=1.0, dragon=1.0, },
	fire     = {normal=1.0, fighting=1.0, flying=1.0, poison=1.0, ground=1.0, rock=0.5, bug=2.0, ghost=1.0, fire=0.5, water=0.5, grass=2.0, electric=1.0, psychic=1.0, ice=2.0, dragon=0.5, },
	water    = {normal=1.0, fighting=1.0, flying=1.0, poison=1.0, ground=2.0, rock=2.0, bug=1.0, ghost=1.0, fire=2.0, water=0.5, grass=0.5, electric=1.0, psychic=1.0, ice=1.0, dragon=0.5, },
	grass    = {normal=1.0, fighting=1.0, flying=0.5, poison=0.5, ground=2.0, rock=2.0, bug=0.5, ghost=1.0, fire=0.5, water=2.0, grass=0.5, electric=1.0, psychic=1.0, ice=1.0, dragon=0.5, },
	electric = {normal=1.0, fighting=1.0, flying=2.0, poison=1.0, ground=0.0, rock=1.0, bug=1.0, ghost=1.0, fire=1.0, water=2.0, grass=0.5, electric=0.5, psychic=1.0, ice=1.0, dragon=0.5, },
	psychic  = {normal=1.0, fighting=2.0, flying=1.0, poison=2.0, ground=1.0, rock=1.0, bug=1.0, ghost=1.0, fire=1.0, water=1.0, grass=1.0, electric=1.0, psychic=0.5, ice=1.0, dragon=1.0, },
	ice      = {normal=1.0, fighting=1.0, flying=2.0, poison=1.0, ground=2.0, rock=1.0, bug=1.0, ghost=1.0, fire=1.0, water=0.5, grass=2.0, electric=1.0, psychic=1.0, ice=0.5, dragon=2.0, },
	dragon   = {normal=1.0, fighting=1.0, flying=1.0, poison=1.0, ground=1.0, rock=1.0, bug=1.0, ghost=1.0, fire=1.0, water=1.0, grass=1.0, electric=1.0, psychic=1.0, ice=1.0, dragon=2.0, },
}

local types = {}
types[0]  = "normal"
types[1]  = "fighting"
types[2]  = "flying"
types[3]  = "poison"
types[4]  = "ground"
types[5]  = "rock"
types[7]  = "bug"
types[8]  = "ghost"
types[20] = "fire"
types[21] = "water"
types[22] = "grass"
types[23] = "electric"
types[24] = "psychic"
types[25] = "ice"
types[26] = "dragon"

local savedEncounters = {}
local enablePP = false

local floor = math.floor

local function isDisabled(mid)
	return mid == memory.value("battle", "disabled")
end
combat.isDisabled = isDisabled

local function calcDamage(move, attacker, defender, rng)
	if (move.fixed) then
		return move.fixed, move.fixed
	end
	if (move.power == 0 or isDisabled(move.id)) then
		return 0, 0
	end
	if (move.power > 9000) then
		local oid = defender.id
		if (oid ~= 14 and oid ~= 147 and oid ~= 171 and (oidd ~= 151 or memory.value("game", "map") == 120)) then -- ???
			if (memory.value("battle", "x_accuracy") == 1 and defender.speed < attacker.speed) then
				return 9001, 9001
			end
		end
		return 0, 0
	end
	if (move.name == "Thrash" and combat.disableThrash) then
		return 0, 0
	end

	local attFactor, defFactor
	if move.special then
		attFactor, defFactor = attacker.spec, defender.spec
	else
		attFactor, defFactor = attacker.att, defender.def
	end
	local damage = floor(floor(floor(2 * attacker.level / 5 + 2) * math.max(1, attFactor) * move.power / math.max(1, defFactor)) / 50) + 2

	if (move.move_type == attacker.type1 or move.move_type == attacker.type2) then
		damage = floor(damage * 1.5) -- STAB
	end

	local dmp = damageMultiplier[move.move_type]
	local typeEffect1, typeEffect2 = dmp[defender.type1], dmp[defender.type2]
	if (defender.type1 == defender.type2) then
		typeEffect2 = 1
	end
	damage = floor(damage * typeEffect1 * typeEffect2)
	if (rng) then
		return damage, damage
	end
	return floor(damage * 217 / 255), damage
end

local function getOpponentType(ty)
	local t1= types[memory.value("battle", "opponent_type1")]
	if ty~=0 then
		t1 = types[memory.value("battle", "opponent_type2")]
		if not t1 then
			return memory.value("battle", "opponent_type2")
		end
	end
	if t1 then
		return t1
	end
	return memory.value("battle", "opponent_type1")
end
combat.getOpponentType = getOpponentType

function getOurType(ty)
	local t1 = types[memory.value("battle", "our_type1")]
	if (ty ~= 0) then
		t1 = types[memory.value("battle", "our_type2")]
		if (not t1) then
			return memory.value("battle", "opponent_type2")
		end
	end
	if t1 then
		return t1
	end
	return memory.value("battle", "opponent_type1")
end
combat.getOurType = getOurType

local function getMoves(who)--Get the moveset of us [0] or them [1]
	local moves = {}
	local base
	if (who == 1) then
		base = 0xCFED
	else
		base = 0xD01C
	end
	for idx=0, 3 do
		local val = memory.raw(base + idx)
		if (val > 0) then
			local moveTable = movelist.get(val)
			if (who == 0) then
				moveTable.pp = memory.raw(0xD02D + idx)
			end
			moves[idx + 1] = moveTable
		end
	end
	return moves
end
combat.getMoves = getMoves

local function modPlayerStats(user, enemy, move)
	local effect = move.effects
	if (effect) then
		local diff = effect.diff
		local hitThem = diff < 0
		local stat = effect.stat
		if (hitThem) then
			enemy[stat] = math.max(2, enemy[stat] + diff)
		else
			user[stat] = user[stat] + diff
		end
	end
	return user, enemy
end

local function calcBestHit(attacker, defender, ours, rng)
	local bestTurns, bestMinTurns = 9999, 9999
	local bestDmg = -1
	local ourMaxHit
	local ret = nil
	for idx,move in ipairs(attacker.moves) do
		if (not move.pp or move.pp > 0) then
			local minDmg, maxDmg = calcDamage(move, attacker, defender, rng)
			if (maxDmg) then
				local minTurns, maxTurns
				if (maxDmg <= 0) then
					minTurns, maxTurns = 9999, 9999
				else
					minTurns = math.ceil(defender.hp / maxDmg)
					maxTurns = math.ceil(defender.hp / minDmg)
				end
				if (ours) then
					local replaces
					if (not ret or minTurns < bestMinTurns or maxTurns < bestTurns) then
						replaces = true
					elseif (maxTurns == bestTurns and move.name == "Thrash") then
						replaces = defender.hp == memory.double("battle", "opponent_max_hp")
					elseif (maxTurns == bestTurns and ret.name == "Thrash") then
						replaces = defender.hp ~= memory.double("battle", "opponent_max_hp")
					elseif (move.fast and not ret.fast) then
						replaces = maxTurns <= bestTurns
					elseif (ret.fast) then
						replaces = maxTurns < bestTurns
					elseif (enablePP) then
						if (maxTurns < 2 or maxTurns == bestMaxTurns) then
							if (ret.name == "Earthquake" and (move.name == "Ice-Beam" or move.name == "Thunderbolt")) then
								replaces = true
							elseif (move.pp > ret.pp) then
								if (ret.name == "Horn-Drill") then
									replaces = true
								elseif (move.name ~= "Earthquake") then
									replaces = true
								end
							end
						end
					elseif (minDmg > bestDmg) then
						replaces = true
					end
					if (replaces) then
						ret = move
						bestMinTurns = minTurns
						bestTurns = maxTurns
						bestDmg = minDmg
						ourMaxHit = maxDmg
					end
				elseif (maxDmg > bestDmg) then -- Opponents automatically hit max
					ret = move
					bestTurns = minTurns
					bestDmg = maxDmg
				end
			end
		end
	end
	if (ret) then
		ret.damage = bestDmg
		ret.maxDamage = ourMaxHit
		ret.minTurns = bestMinTurns
		return ret, bestTurns
	end
end

local function getBestMove(ours, enemy, draw)
	if (enemy.hp < 1) then
		return
	end
	local bm, bestUs = calcBestHit(ours, enemy, true)
	local jj, bestEnemy = calcBestHit(enemy, ours, false)
	if (not bm) then
		return
	end
	if draw and bm.midx then
		gui.text(0, 35, ''..bm.midx.." "..bm.name)
	end
	return bm, bestUs, bestEnemy
end

local function activePokemon(preset)
	local ours = {
		id = memory.value("battle", "our_id"),
		level = memory.value("battle", "our_level"),
		hp = memory.double("battle", "our_hp"),
		att = memory.double("battle", "our_attack"),
		def = memory.double("battle", "our_defense"),
		spec = memory.double("battle", "our_special"),
		speed = memory.double("battle", "our_speed"),
		type1 = getOurType(0),
		type2 = getOurType(1),
		moves = getMoves(0),
	}

	local enemy
	if (preset) then
		enemy = opponents[preset]
		local toBoost = enemy.boost
		if (toBoost) then
			local currSpec = ours.spec
			local booster = toBoost.mp
			if ((currSpec < 140) == (booster > 1)) then
				ours.spec = math.floor(currSpec * booster)
			end
		end
	else
		enemy = {
			id = memory.value("battle", "opponent_id"),
			level = memory.value("battle", "opponent_level"),
			hp = memory.double("battle", "opponent_hp"),
			att = memory.double("battle", "opponent_attack"),
			def = memory.double("battle", "opponent_defense"),
			spec = memory.double("battle", "opponent_special"),
			speed = memory.double("battle", "opponent_speed"),
			type1 = getOpponentType(0),
			type2 = getOpponentType(1),
			moves = getMoves(1),
		}
	end
	return ours, enemy
end
combat.activePokemon = activePokemon

local function isSleeping()
	return memory.raw(0xD16F) > 1
end
combat.isSleeping = isSleeping

-- Combat AI functions

function combat.factorPP(enabled)
	enablePP = enabled
end

function combat.reset()
	enablePP = false
end

function combat.healthFor(opponent)
	local ours, enemy = activePokemon(opponent)
	local enemyAttack, turnsToDie = calcBestHit(enemy, ours, false)
	return enemyAttack.damage
end

function combat.inKillRange(draw)
	local ours, enemy = activePokemon()
	local enemyAttack, __ = calcBestHit(enemy, ours, false)
	local __, turnsToKill = calcBestHit(ours, enemy, true)
	if (not turnsToKill or not enemyAttack) then
		return false
	end
	if (draw) then
		gui.text(0, 21, ours.speed.." "..enemy.speed)
		gui.text(0, 28, turnsToDie.." "..ours.hp.." | "..turnsToKill.." "..enemy.hp)
	end
	local hpReq = enemyAttack.damage
	local isConfused = memory.value("battle", "confused") > 0
	if (isConfused) then
		hpReq = hpReq + math.floor(ours.hp * 0.2)
	end
	if (ours.hp < hpReq) then
		local outspeed = enemyAttack.outspeed
		if (outspeed and outspeed ~= true) then
			outspeed = memory.value("battle", "turns") > 0
		end
		if (outspeed or isConfused or turnsToKill > 1 or ours.speed <= enemy.speed or isSleeping()) then
			return ours, hpReq
		end
	end
end

local function getBattlePokemon()
	local ours, enemy = activePokemon()
	if (enemy.hp == 0) then
		return
	end
	for idx=1,4 do
		local move = ours.moves[idx]
		if (move) then
			move.midx = idx
		end
	end
	return ours, enemy
end

function combat.nonKill()
	local ours, enemy = getBattlePokemon()
	if (not enemy) then
		return
	end
	local bestDmg = -1
	local ret = nil
	for idx,move in ipairs(ours.moves) do
		if (not move.pp or move.pp > 0) then
			local __, maxDmg = calcDamage(move, ours, enemy, true)
			local threshold = maxDmg * 0.95
			if (threshold and threshold < enemy.hp and threshold > bestDmg) then
				ret = move
				bestDmg = threshold
			end
		end
	end
	return ret
end

function combat.bestMove()
	local ours, enemy = getBattlePokemon()
	if (enemy) then
		return getBestMove(ours, enemy)
	end
end

function combat.enemyAttack()
	local ours, enemy = activePokemon()
	if (enemy.hp == 0) then
		return
	end
	return calcBestHit(enemy, ours, false)
end

return combat
