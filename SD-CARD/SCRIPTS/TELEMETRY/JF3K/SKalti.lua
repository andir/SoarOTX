-- Timing and score keeping, loadable user interface for altimeter based tasks
-- Timestamp: 2019-09-02
-- Created by Jesper Frickmann

local 	exitTask = 0 -- Prompt to save task before EXIT
local stopWindow = 0 -- Prompt to stop flight timer first
local yScaleMax = 50 -- For plotting

local GREY
if LCD_W == 128 then
	GREY = 0
else
	GREY = GREY_DEFAULT
end

local Draw -- Function to draw the screen for specific transmitter

-- Convert time to minutes and seconds
local function MinSec(t)
	local m = math.floor(t / 60)
	return m, t - 60 * m
end -- MinSec()

local function DrawGraph(dot)
	local xx1
	local xx2
	local xMax = sk.taskWindow / plugin.heightInt + 1
	
	local yy1
	local yy2
	local m

	-- Rescale if necessary
	if plugin.ceiling >= yScaleMax then
		yScaleMax = math.ceil(plugin.ceiling / 25) * 25
	end
	
	if sk.task == plugin.TASK_THROW_LOW then
		yScaleMax = math.max(100, yScaleMax)
	end
	
	-- Find linear transformation from Y to screen pixel
	m = (12 - LCD_H) / yScaleMax
	
	-- Horizontal grid lines
	for i = 25, yScaleMax, 25 do
		yy1 = m * i + LCD_H - 1
		lcd.drawLine(0, yy1, xMax, yy1, DOTTED, GREY)
		lcd.drawNumber(xMax + 1, yy1 - 3, i, SMLSIZE)
	end
	
	-- Vertical grid lines
	for i = 0, sk.taskWindow, 60 do
		xx1 = i / plugin.heightInt
		lcd.drawLine(xx1, LCD_H, xx1, 8, DOTTED, GREY)
	end

	-- Plot the graph
	for i = 1, #plugin.heights - 1 do
		yy1 = m * plugin.heights[i] + LCD_H - 1
		yy2 = m * plugin.heights[i + 1] + LCD_H - 1
		lcd.drawLine(i - 1, yy1, i, yy2, SOLID, FORCE)
		
		-- Rescale if necessary
		if plugin.heights[i] >= yScaleMax then
			yScaleMax = math.ceil(plugin.heights[i] / 25) * 25
		end
	end

	-- Line through zero
	lcd.drawLine(0, LCD_H - 1, xMax, LCD_H - 1, SOLID, FORCE)

	-- Draw lines to illustrate scores for recorded flights
	for i = 1, #sk.scores do
		xx1 = (sk.scores[i].start + 10) / plugin.heightInt
		xx2 = (sk.scores[i].start + sk.scores[i].time) / plugin.heightInt
		yy1 = m * sk.scores[i].launch + LCD_H - 1

		if sk.task == plugin.TASK_HEIGHT_GAIN or sk.task == plugin.TASK_HEIGHT_POKER then
			-- Launch height
			lcd.drawLine(xx1, yy1, xx2, yy1, dot, FORCE)

			-- Max height
			xx1 = sk.scores[i].maxTime / plugin.heightInt
			yy2 = m * sk.scores[i].maxHeight + LCD_H - 1
			lcd.drawLine(xx1, yy1, xx1, yy2, dot, FORCE)			
		elseif sk.task == plugin.TASK_THROW_LOW then
			-- Launch height
			yy2 = m * 100 + LCD_H - 1
			lcd.drawLine(xx1, yy1, xx1, yy2, dot, FORCE)
			lcd.drawLine(xx1 - 2, yy1, xx1 + 2, yy1, dot, FORCE)
			lcd.drawLine(xx1 - 2, yy2, xx1 + 2, yy2, dot, FORCE)
		end
		
		-- Flight time
		if sk.task == plugin.TASK_CEILING then
			xx1 = sk.scores[i].start / plugin.heightInt
			yy2 = m * plugin.ceiling + LCD_H - 1
			lcd.drawLine(xx1, LCD_H - 1, xx1, yy2, dot, FORCE)
			lcd.drawLine(xx2, LCD_H - 1, xx2, yy2, dot, FORCE)
		end
	end

	-- Ceiling
	yy1 = m * plugin.ceiling + LCD_H - 1
	if sk.task == plugin.TASK_CEILING then
		lcd.drawLine(0, yy1, xMax, yy1, dot, FORCE)
	end
		
	-- Draw lines to illustrate scores for current flight
	if sk.state >=sk.STATE_FLYING and plugin.launchHeight > 0 then
		xx1 = plugin.flightStart / plugin.heightInt
		if model.getTimer(0).start == 0 then
			xx2 = sk.taskWindow / plugin.heightInt
		else
			xx2 = (plugin.flightStart + model.getTimer(0).start) / plugin.heightInt
		end
		
		if sk.task == plugin.TASK_CEILING then
			-- Flight time
			lcd.drawLine(xx1, LCD_H - 1, xx1, yy1, dot, FORCE)
			lcd.drawLine(xx2, LCD_H - 1, xx2, yy1, dot, FORCE)
		elseif sk.task == plugin.TASK_HEIGHT_GAIN or sk.task == plugin.TASK_HEIGHT_POKER then
			-- Ceiling
			lcd.drawLine(xx1, yy1, xx2, yy1, dot, FORCE)
			
			-- Launch height
			xx1 = (plugin.flightStart + 10) / plugin.heightInt
			yy1 = m * plugin.launchHeight + LCD_H - 1
			lcd.drawLine(xx1, yy1, xx2, yy1, dot, FORCE)
		else
			-- Launch height
			xx1 = (plugin.flightStart + 10) / plugin.heightInt
			yy1 = m * plugin.launchHeight + LCD_H - 1
			yy2 = m * 100 + LCD_H - 1
			lcd.drawLine(xx1, yy1, xx1, yy2, dot, FORCE)
			lcd.drawLine(xx1 - 2, yy1, xx1 + 2, yy1, dot, FORCE)
			lcd.drawLine(xx1 - 2, yy2, xx1 + 2, yy2, dot, FORCE)
		end
	end

	-- In height poker, show call
	if sk.task == plugin.TASK_HEIGHT_POKER and sk.state <= sk.STATE_WINDOW then
		local att = 0
		
		if plugin.pokerCalled then att = att + BLINK + INVERS end
		lcd.drawText(2, 55, string.format("Call: %im", plugin.targetGain), att)
	end

	-- Show ceiling
	if sk.task == plugin.TASK_CEILING and sk.state == sk.STATE_IDLE then
		lcd.drawText(2, 55, string.format("Ceiling: %im", plugin.ceiling))
	end
end -- DrawGraph()

if LCD_W == 128 then
	function Draw()
		local att
		
		DrawMenu(sk.taskName)
		DrawGraph(SOLID)
		
		-- Timers
		if sk.flightTimer < 0 then
			att = BLINK + INVERS
		else
			att = 0
		end
		
		lcd.drawTimer(LCD_W, 12, sk.flightTimer, MIDSIZE + RIGHT + att)

		if sk.state == sk.STATE_FINISHED then
			att = BLINK + INVERS
		else
			att = 0
		end
		
		lcd.drawTimer(LCD_W, 30, sk.winTimer,  MIDSIZE + RIGHT + att)

		-- QR and EoW
		if sk.eowTimerStop then
			lcd.drawText(LCD_W - 18, 48, "EoW", SMLSIZE + INVERS)
		end
		
		if sk.quickRelaunch then
			lcd.drawText(LCD_W - 33, 48, "QR", SMLSIZE + INVERS)
		end

		if plugin.launchHeight > 0 then
			lcd.drawText(73, 58, string.format("Launch %i m", plugin.launchHeight), SMLSIZE)
		end
		
		-- Scores
		for i = 1, sk.taskScores do
			local dy = 14
			
			if i > #sk.scores then
				lcd.drawText(73, dy * i, "- - -", SMLSIZE)
			elseif plugin.unit == "s" then
				lcd.drawText(73, dy * i, string.format("%02i:%02i", MinSec(sk.scores[i].time)), SMLSIZE)
			else
				lcd.drawText(73, dy * i, string.format("%4i%s", sk.scores[i].gain, plugin.unit), SMLSIZE)
			end
		end
	end  --  Draw()
else
	function Draw()
		local att
		
		DrawMenu(sk.taskName)
		DrawGraph(DOTTED)
		
		-- Timers
		lcd.drawText(LCD_W - 46, 15, "F")
		
		if sk.flightTimer < 0 then
			att = BLINK + INVERS
		else
			att = 0
		end
		
		lcd.drawTimer(LCD_W, 12, sk.flightTimer, MIDSIZE + RIGHT + att)

		lcd.drawText(LCD_W - 46, 33, "W")
		
		if sk.state == sk.STATE_FINISHED then
			att = BLINK + INVERS
		else
			att = 0
		end
		
		lcd.drawTimer(LCD_W, 30, sk.winTimer,  MIDSIZE  + RIGHT + att)

		-- QR and EoW
		if sk.eowTimerStop then
			lcd.drawText(LCD_W - 18, 48, "EoW", SMLSIZE + INVERS)
		end
		
		if sk.quickRelaunch then
			lcd.drawText(LCD_W - 33, 48, "QR", SMLSIZE + INVERS)
		end

		if plugin.launchHeight > 0 then
			lcd.drawText(126, 56, string.format("Launch %i m", plugin.launchHeight))
		end
		
		-- Scores
		for i = 1, sk.taskScores do
			local dy = 14
			
			if i > #sk.scores then
				lcd.drawText(126, dy * i, string.format("%i. - - -", i))
			elseif plugin.unit == "s" then
				lcd.drawText(126, dy * i, string.format("%i. %02i:%02i", i, MinSec(sk.scores[i].time)))
			else
				lcd.drawText(126, dy * i, string.format("%i. %4i%s", i, sk.scores[i].gain, plugin.unit))
			end
		end
	end  --  Draw()
end

local function run(event)
	-- Do we have an altimeter?
	if not plugin.altId then
		lcd.clear()
		lcd.drawText(10,10,"Altimeter", DBLSIZE)
		lcd.drawText(10,30,"not found", DBLSIZE)
		
		if event ~= 0 then
			sk.run = sk.menu
		end

	elseif exitTask == -1 then -- Save scores?
		if LCD_W == 128 then
			DrawMenu(sk.taskName)
			lcd.drawText(8, 15, "Save scores?", MIDSIZE)
			lcd.drawText(8, 35, "ENTER = SAVE")
			lcd.drawText(8, 45, "EXIT = DON'T")
		else
			DrawMenu(" " .. sk.taskName .. " ")
			lcd.drawText(38, 15, "Save scores?", DBLSIZE)
			lcd.drawText(4, LCD_H - 16, "EXIT", MIDSIZE + BLINK)
			lcd.drawText(LCD_W - 3, LCD_H - 16, "SAVE", MIDSIZE + BLINK + RIGHT)
		end

		-- Record scores if user pressed ENTER
		if event == EVT_ENTER_BREAK then
			local logFile = io.open("/LOGS/JF F3K Scores.csv", "a")
			if logFile then
				io.write(logFile, string.format("%s,%s", model.getInfo().name, sk.taskName))

				local now = getDateTime()				
				io.write(logFile, string.format(",%04i-%02i-%02i", now.year, now.mon, now.day))
				io.write(logFile, string.format(",%02i:%02i", now.hour, now.min))
				
				io.write(logFile, string.format(",%s,%i", plugin.unit, sk.taskScores))
				
				local what = "gain"
				if plugin.unit == "s" then
					what = "time"
				end
				
				local totalScore = 0
				for i = 1, #sk.scores do
					totalScore = totalScore + sk.scores[i][what]
				end
				io.write(logFile, string.format(",%i", totalScore))
				
				for i = 1, #sk.scores do
					io.write(logFile, string.format(",%i", sk.scores[i][what]))
				end
				
				io.write(logFile, "\n")
				io.close(logFile)
			end
			sk.run = sk.menu
		elseif event == EVT_EXIT_BREAK then
			sk.run = sk.menu
		end

	elseif exitTask > 0 then
		if getTime() > exitTask then
			exitTask = 0
		else
			if LCD_W == 128 then
				DrawMenu(sk.taskName)
				lcd.drawText(8, 15, "Stop window", MIDSIZE)
				lcd.drawText(8, 30, "timer before", MIDSIZE)
				lcd.drawText(8, 45, "leaving task.", MIDSIZE)
			else
				DrawMenu(" " .. sk.taskName .. " ")
				lcd.drawText(38, 18, "Stop window timer", MIDSIZE)
				lcd.drawText(38, 40, "before leaving task.", MIDSIZE)
			end
		end
	
	elseif stopWindow > 0 then
		if getTime() > stopWindow then
			stopWindow = 0
		else
			if LCD_W == 128 then
				DrawMenu(sk.taskName)
				lcd.drawText(8, 15, "Stop the flight", MIDSIZE)
				lcd.drawText(8, 30, "timer before", MIDSIZE)
				lcd.drawText(8, 45, "pausing window.", MIDSIZE)
			else
				DrawMenu(" " .. sk.taskName .. " ")
				lcd.drawText(30, 18, "Stop the flight timer", MIDSIZE)
				lcd.drawText(30, 40, "before pausing window.", MIDSIZE)
			end
		end
	
	else
		Draw()

		-- Toggle quick relaunch QR
		if event == EVT_PLUS_BREAK or event == EVT_ROT_RIGHT or event == EVT_UP_BREAK then
			sk.quickRelaunch = not sk.quickRelaunch
			playTone(1760, 100, PLAY_NOW)
		end
		
		-- Toggle end of window timer stop EoW
		if event == EVT_MINUS_BREAK or event == EVT_ROT_LEFT or event == EVT_DOWN_BREAK then
			sk.eowTimerStop = not sk.eowTimerStop
			playTone(1760, 100, PLAY_NOW)
		end

		if event == EVT_ENTER_BREAK then
			if sk.state <= sk.STATE_PAUSE then
				-- Start task window
				sk.state = sk.STATE_WINDOW
			elseif sk.state == sk.STATE_WINDOW then
				-- Pause task window
				sk.state = sk.STATE_PAUSE
			elseif sk.state >= sk.STATE_READY then
				stopWindow = getTime() + 100
			end
			
			playTone(1760, 100, PLAY_NOW)
		end
		
		if (event == EVT_MENU_LONG or event == EVT_SHIFT_LONG) 
		and (sk.state == sk.STATE_COMMITTED or sk.state == sk.STATE_FREEZE) then
			-- Record a zero score!
			sk.Score(true)
			
			-- Change state
			if sk.winTimer <= 0 or (sk.finalScores and #sk.scores == sk.taskScores) or sk.launches == 0 then
				sk.state = sk.STATE_FINISHED
			else
				sk.state = sk.STATE_WINDOW
			end

			playTone(440, 333, PLAY_NOW)
		end

		if event == EVT_EXIT_BREAK then
			-- Quit task
			if sk.state == sk.STATE_IDLE then
				sk.run = sk.menu
			elseif sk.state == sk.STATE_PAUSE or sk.state == sk.STATE_FINISHED then
				exitTask = -1
			else
				exitTask = getTime() + 100
			end
		end
	end
end  --  run()

return {run = run}