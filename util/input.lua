local input = {}

local bridge = require "util.bridge"
local memory = require "util.memory"

local lastSend
local currentButton, remainingFrames, setForFrame
local debug
local bCancel = true

local function bridgeButton(btn)
	if (btn ~= lastSend) then
		lastSend = btn
		bridge.input(btn)
	end
end

local function sendButton(button, ab)
	local inputTable = {[button] = true}
	joypad.set(inputTable)
	if (debug) then
		gui.text(0, 7, button.." "..remainingFrames)
	end
	if (ab) then
		button = "AB"
	end
	bridgeButton(button)
	setForFrame = button
end

function input.press(button, frames)
	if (setForFrame) then
		print("ERR: Reassigning "..setForFrame.." to "..button)
		return
	end
	if (frames == nil or frames > 0) then
		if (button == currentButton) then
			return
		end
		if (not frames) then
			frames = 1
		end
		currentButton = button
		remainingFrames = frames
	else
		remainingFrames = 0
	end
	bCancel = button ~= "B"
	sendButton(button)
end

function input.cancel(accept)
	if (accept and memory.value("menu", "shop_current") == 20) then
		input.press(accept)
	else
		local button
		if (bCancel) then
			button = "B"
		else
			button = "A"
		end
		remainingFrames = 0
		sendButton(button, true)
		bCancel = not bCancel
	end
end

function input.escape()
	local inputTable = {Right=true, Down=true}
	joypad.set(inputTable)
	bridgeButton("Escape")
end

function input.clear()
	currentButton = nil
	remainingFrames = -1
end

function input.update()
	if (currentButton) then
		remainingFrames = remainingFrames - 1
		if (remainingFrames >= 0) then
			if (remainingFrames > 0) then
				sendButton(currentButton)
				return true
			end
		else
			currentButton = nil
		end
	end
	setForFrame = nil
end

function input.advance()
	if (not setForFrame) then
		bridgeButton("e")
		-- print("e")
	end
end

function input.setDebug(enabled)
	debug = enabled
end

function input.test(fn, completes)
	while (true) do
		if (not input.update()) then
			if (fn() and completes) then
				break
			end
		end
		emu.frameadvance()
	end
	if (completes) then
		print(completes.." complete!")
	end
end

return input
