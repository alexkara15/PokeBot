local walk = {}

local control = require "ai.control"
local paths = require "data.paths"

local input = require "util.input"
local memory = require "util.memory"
local player = require "util.player"
local utils = require "util.utils"

local pokemon = require "storage.pokemon"

local path, stepIdx, currentMap
local pathIdx = 0
local customIdx = 1
local customDir = 1

-- Private functions

local function setPath(index, region)
	pathIdx = index
	stepIdx = 2
	currentMap = region
	path = paths[index]
end

-- Helper functions

function dir(px, py, dx, dy)
	local direction
	if (py > dy) then
		direction = "Up"
	elseif (py < dy) then
		direction = "Down"
	elseif (px > dx) then
		direction = "Left"
	else
		direction = "Right"
	end
	return direction
end
walk.dir = dir

function step(dx, dy)
	local px, py = player.position()
	if (px == dx and py == dy) then
		return true
	end
	input.press(dir(px, py, dx, dy), 0)
end
walk.step = step

local function completeStep(region)
	stepIdx = stepIdx + 1
	return walk.traverse(region)
end

-- Table functions

function walk.reset()
	path = nil
	pathIdx = 0
	customIdx = 1
	customDir = 1
	currentMap = nil
	walk.strategy = nil
end

function walk.init()
	local region = memory.value("game", "map")
	local px, py = player.position()
	if (region == 0 and px == 0 and py == 0) then
		return false
	end
	for tries=1,2 do
		for i,p in ipairs(paths) do
			if (i > 2 and p[1] == region) then
				local origin = p[2]
				if (tries == 2 or (origin[1] == px and origin[2] == py)) then
					setPath(i, region)
					return tries == 1
				end
			end
		end
	end
end

function walk.traverse(region)
	local newIndex
	if (not path or currentMap ~= region) then
		walk.strategy = nil
		setPath(pathIdx + 1, region)
		newIndex = pathIdx
		customIdx = 1
		customDir = 1
	elseif stepIdx > #path then
		return
	end
	local tile = path[stepIdx]
	if (tile.c) then
		control.set(tile)
		return completeStep(region)
	end
	if (tile.s) then
		if (walk.strategy) then
			walk.strategy = nil
			return completeStep(region)
		end
		walk.strategy = tile
	elseif step(tile[1], tile[2]) then
		pokemon.updateParty()
		return completeStep(region)
	end
	return newIndex
end

function walk.canMove()
	return memory.value("player", "moving") == 0 and memory.value("player", "fighting") == 0
end

-- Custom path

function walk.invertCustom(silent)
	if (not silent) then
		customIdx = customIdx + customDir
	end
	customDir = customDir * -1
end

function walk.custom(cpath, increment)
	if (not cpath) then
		customIdx = 1
		customDir = 1
		return
	end
	if (increment) then
		customIdx = customIdx + customDir
	end
	local tile = cpath[customIdx]
	if (not tile) then
		if (customIdx < 1) then
			customIdx = #cpath
		else
			customIdx = 1
		end
		return customIdx
	end
	local t1, t2 = tile[1], tile[2]
	if (t2 == nil) then
		if (player.face(t1)) then
			input.press("A", 2)
		end
		return t1
	end
	if (step(t1, t2)) then
		customIdx = customIdx + customDir
	end
end

return walk
