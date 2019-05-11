-- Timing and score keeping, loadable plugin for practice tasks
-- Timestamp: 2019-05-11
-- Created by Jesper Frickmann

local TASK_DEUCES = 3

-- If no task is selected, then return name and task list to the menu
if sk.task == 0 then
	local name = "Practice"

	local tasks = {
		"Just Fly!",
		"Quick Relaunch!",
		"Deuces"
	}

	return name, tasks
end

-- Setup task definition. Only if we are still in STATE_IDLE
if sk.state == sk.STATE_IDLE then
	local targetType
	
	--  Variables shared between task def. and UI must be added to own list
	plugin = { }
	plugin.totalScore = 0

	do -- Discard from memory after use
		local taskData = {
			{ 0, -1, 8, false, 0, false }, -- Just fly
			{ 0, -1, 8, false, 1, true }, -- QR
			{ 600, 2, 2, true, 2, false } -- Deuces
		}
		
		sk.taskWindow = taskData[sk.task][1]
		sk.launches = taskData[sk.task][2]
		sk.taskScores = taskData[sk.task][3]
		sk.finalScores = taskData[sk.task][4]
		targetType = taskData[sk.task][5]
		sk.quickRelaunch = taskData[sk.task][6]
	end

	if targetType == 1 then -- Adjustable
		sk.TargetTime = function()
			local m = math.floor((1024 + getValue(sk.set1id)) / 205)
			local s = math.floor((1024 + getValue(sk.set2id)) / 34.2)

			return math.max(5, 60 * m + s)
		end
		
	elseif targetType == 2 then -- Deuces
		sk.TargetTime = function()
			if #sk.scores == 0 then
				return math.max(0, math.floor(sk.winTimer / 2))
			elseif #sk.scores == 1 then
				return math.max(0, math.min(sk.winTimer, sk.scores[1]))
			else
				return 0
			end
		end
		
	else -- TargetTime = targetType
		sk.TargetTime = function() 
			return targetType
		end
	end
	
	sk.Score = function()
		local n = #sk.scores
		
		if n >= sk.taskScores then
			-- List is full; move other scores one up to make room for the latest at the end
			for j = 1, n - 1 do
				sk.scores[j] = sk.scores[j + 1]
			end
		else
			-- List can grow; add to the end of the list
			n = n + 1
		end
		
		sk.scores[n] = sk.flightTime
		
		plugin.totalScore = 0
		
		if sk.task == TASK_DEUCES then
			if #sk.scores < 2 then
				plugin.totalScore = 0
			else
				plugin.totalScore = math.min(sk.scores[1], sk.scores[2])
			end
		else
			for i = 1, #sk.scores do
				plugin.totalScore = plugin.totalScore + sk.scores[i]
			end
		end
	end

end -- Setup task definition.

-- Load the user interface
sk.run = "/SCRIPTS/TELEMETRY/JF3K/SK.lua"