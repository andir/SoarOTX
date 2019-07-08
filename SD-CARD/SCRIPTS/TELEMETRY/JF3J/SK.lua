-- JF F3J Timing and score keeping, loadable part
-- Timestamp: 2019-07-07
-- Created by Jesper Frickmann
-- Telemetry script for timing and keeping scores for F3J.

local sbFile = "/SCRIPTS/TELEMETRY/JF3J/SB.lua" -- Score browser user interface file
local wt -- Window timer
local ft -- Flight timer

local Draw -- Draw() function is defined for specific transmitter

-- Transmitter specific
if LCD_W == 128 then
	function Draw()
		local fmNbr, fmName = getFlightMode()
		DrawMenu(fmName)	

		lcd.drawText(0, 20, "Landing")
		lcd.drawText(0, 42, "Start")

		if sk.state == sk.STATE_INITIAL then
			lcd.drawText(72, 20, "Tgt")
		elseif sk.state <= sk.STATE_WINDOW then
			lcd.drawText(72, 20, "Rem")
		else
			lcd.drawText(72, 20, "Win")
		end

		if sk.state == sk.STATE_INITIAL then
			lcd.drawTimer(128, 16, wt.value, MIDSIZE + RIGHT + BLINK + INVERS)
		else
			lcd.drawTimer(128, 16, wt.value, MIDSIZE + RIGHT)
		end

		lcd.drawText(72, 42, "Flt")

		if sk.state == sk.STATE_TIME then
			lcd.drawTimer(128, 38, ft.value, MIDSIZE + RIGHT + BLINK + INVERS)
		else
			lcd.drawTimer(128, 38, ft.value, MIDSIZE + RIGHT)
		end

		if sk.state < sk.STATE_LANDINGPTS then
			lcd.drawText(60, 16, "--", MIDSIZE + RIGHT)
		elseif sk.state == sk.STATE_LANDINGPTS then
			lcd.drawNumber(60, 16, sk.landingPts, MIDSIZE + RIGHT + BLINK + INVERS)
		else
			lcd.drawNumber(60, 16, sk.landingPts, MIDSIZE + RIGHT)
		end

		if sk.state < sk.STATE_LANDINGPTS then
			lcd.drawText(60, 38, "---", MIDSIZE + RIGHT)
		elseif sk.state == sk.STATE_STARTHEIGHT then
			lcd.drawNumber(60, 38, sk.startHeight * 10, PREC1 + MIDSIZE + RIGHT + BLINK + INVERS)
		else
			lcd.drawNumber(60, 38, sk.startHeight * 10, PREC1 + MIDSIZE + RIGHT)
		end
	end -- Draw()
else
	function Draw()
		local fmNbr, fmName = getFlightMode()
		DrawMenu(" " .. fmName .. " ")	

		lcd.drawText(0, 20, "Landing", MIDSIZE)
		lcd.drawText(0, 42, "Start", MIDSIZE)

		if sk.state == sk.STATE_INITIAL then
			lcd.drawText(110, 20, "Target", MIDSIZE)
		elseif sk.state <= sk.STATE_WINDOW then
			lcd.drawText(110, 20, "Remain", MIDSIZE)
		else
			lcd.drawText(110, 20, "Window", MIDSIZE)
		end

		if sk.state == sk.STATE_INITIAL then
			lcd.drawTimer(212, 16, wt.value, DBLSIZE + RIGHT + BLINK + INVERS)
		else
			lcd.drawTimer(212, 16, wt.value, DBLSIZE + RIGHT)
		end

		lcd.drawText(110, 42, "Flight", MIDSIZE)

		if sk.state == sk.STATE_TIME then
			lcd.drawTimer(212, 38, ft.value, DBLSIZE + RIGHT + BLINK + INVERS)
		else
			lcd.drawTimer(212, 38, ft.value, DBLSIZE + RIGHT)
		end

		if sk.state < sk.STATE_LANDINGPTS then
			lcd.drawText(95, 16, "--", DBLSIZE + RIGHT)
		elseif sk.state == sk.STATE_LANDINGPTS then
			lcd.drawNumber(95, 16, sk.landingPts, DBLSIZE + RIGHT + BLINK + INVERS)
		else
			lcd.drawNumber(95, 16, sk.landingPts, DBLSIZE + RIGHT)
		end

		if sk.state < sk.STATE_LANDINGPTS then
			lcd.drawText(95, 38, "---", DBLSIZE + RIGHT)
		elseif sk.state == sk.STATE_STARTHEIGHT then
			lcd.drawNumber(95, 38, sk.startHeight * 10, PREC1 + DBLSIZE + RIGHT + BLINK + INVERS)
		else
			lcd.drawNumber(95, 38, sk.startHeight * 10, PREC1 + DBLSIZE + RIGHT)
		end
	end  --  Draw()
end

local function run(event)
	wt = model.getTimer(0)
	ft = model.getTimer(1)
	
	if sk.state == sk.STATE_INITIAL then -- Set flight time before the flight
		local dt = 0
		
		-- Show score browser
		if event == EVT_MENU_BREAK then
			sk.myFile = sbFile
		end
	
		if event == EVT_PLUS_BREAK or event == EVT_ROT_RIGHT or event == EVT_PLUS_REPT or event == EVT_RIGHT_BREAK then
			dt = 60
		end
		
		if event == EVT_MINUS_BREAK or event == EVT_ROT_LEFT or event == EVT_MINUS_REPT or event == EVT_LEFT_BREAK then
			dt = -60
		end
		
		local tgt = wt.start + dt
		if tgt < 60 then
			tgt = 5940
		elseif tgt > 5940 then
			tgt = 60
		end
		model.setTimer(0, {start = tgt, value = tgt})
	elseif sk.state == sk.STATE_LANDINGPTS then -- Landed, input landing points 
		local dpts = 0
		
		if event == EVT_PLUS_BREAK or event == EVT_ROT_RIGHT or event == EVT_PLUS_REPT or event == EVT_RIGHT_BREAK then
			if sk.landingPts >= 90 then
				dpts = 1
			elseif sk.landingPts >= 30 then
				dpts = 5
			else
				dpts = 30
			end
		end
		
		if event == EVT_MINUS_BREAK or event == EVT_ROT_LEFT or event == EVT_MINUS_REPT or event == EVT_LEFT_BREAK then
			if sk.landingPts > 90 then
				dpts = -1
			elseif sk.landingPts > 30 then
				dpts = -5
			else
				dpts = -30
			end
		end
		
		sk.landingPts = sk.landingPts + dpts
		if sk.landingPts < 0 then
			sk.landingPts = 100
		elseif sk.landingPts  > 100 then
			sk.landingPts = 0
		end
		
		if event == EVT_ENTER_BREAK then
			sk.state = sk.STATE_TIME
		end
	elseif sk.state == sk.STATE_TIME then -- Input flight time
		local dt = 0
		
		if event == EVT_PLUS_BREAK or event == EVT_ROT_RIGHT or event == EVT_PLUS_REPT or event == EVT_RIGHT_BREAK then
			dt = 1
		end
		
		if event == EVT_MINUS_BREAK or event == EVT_ROT_LEFT or event == EVT_MINUS_REPT or event == EVT_LEFT_BREAK then
			dt = -1
		end
		
		if dt ~= 0 then
			ft.value = ft.value + dt
			model.setTimer(1, ft)
		end
		
		if event == EVT_ENTER_BREAK then
			sk.state = sk.STATE_SAVE
		elseif event == EVT_MENU_BREAK or event == EVT_UP_BREAK then
			sk.state = sk.STATE_LANDINGPTS
		end
	elseif sk.state == sk.STATE_SAVE then
		if event == EVT_ENTER_BREAK then -- Record scores if user pressed ENTER
			local logFile = io.open("/LOGS/JF F3J Scores.csv", "a")
			if logFile then
				local nameStr = model.getInfo().name

				local now = getDateTime()
				local dateStr = string.format("%04d-%02d-%02d", now.year, now.mon, now.day)
				local timeStr = string.format("%02d:%02d", now.hour, now.min)

				io.write(logFile, string.format("%s,%s,%s,", nameStr, dateStr, timeStr))
				io.write(logFile, string.format("%s,%4.1f,", sk.landingPts, sk.startHeight))
				io.write(logFile, string.format("%s,%s,%s\n", wt.start, wt.value, ft.value))

				io.close(logFile)
			end
			
			sk.state = sk.STATE_INITIAL
		elseif event == EVT_MENU_BREAK or event == EVT_UP_BREAK then
			sk.state = sk.STATE_TIME
		elseif event == EVT_EXIT_BREAK then -- Do not record scores if user pressed EXIT
			sk.state = sk.STATE_INITIAL
		end
	end
	
	Draw()

	if sk.state == sk.STATE_SAVE then
		lcd.drawText(4, LCD_H - 10, "EXIT", SMLSIZE + BLINK)
		lcd.drawText(LCD_W - 3, LCD_H - 10, "SAVE", SMLSIZE + BLINK + RIGHT)
	end
end  --  run()

return {run = run}