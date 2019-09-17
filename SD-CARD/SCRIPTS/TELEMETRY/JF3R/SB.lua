-- JF F3J Score Browser
-- Timestamp: 2019-09-16
-- Created by Jesper Frickmann
-- Telemetry script for browsing scores recorded in the log file.

local LOG_FILE = "/LOGS/JF F3RES Scores.csv"

local logFile -- Log file handle
local lastTime -- Last time that run() was called, used for refreshing
local index -- Index to currently selected line in log file

ui = {} -- List of  variables shared with loadable user interface
ui.indices = {0} -- Vector of indices pointing to start of lines in the log file
ui.lineData = {} -- Array of data fields from a line
local Draw = LoadWxH("JF3R/SB.lua", ui) -- Screen size specific function

-- Read a line of a log file
local function ReadLine(logFile, pos, bts)
	if not bts then bts = 100 end
	if logFile and pos then
		io.seek(logFile, pos)
		local str = io.read(logFile, bts)
		local endPos = string.find(str, "\n")

		if endPos then
			pos = pos + endPos
			str = string.sub(str, 1, endPos - 1)
			return pos, str
		end
	end
	
	-- No "\n" was found; return nothing
	return 0, ""
end  --  ReadLine()

-- Read a line of comma separated fields into lineData
local function ReadLineData(pos)
	local pos, lineStr = ReadLine(logFile, pos, 100)
	ui.lineData = {}

	if pos > 0 then
		-- Make array of comma separated values in line string
		for field in string.gmatch(lineStr, "[^,]+") do
			ui.lineData[#ui.lineData + 1] = field
		end
	end
end  --  ReadLineData()

local function Scan()
	local i = #ui.indices
	local charPos = ui.indices[#ui.indices]
	local done = false

	logFile = io.open(LOG_FILE, "r")

	-- Read lines of the log file and store indices
	repeat
		charPos = ReadLine(logFile, charPos)
		if charPos == 0 then
			done = true
		else
			ui.indices[#ui.indices + 1] = charPos
		end
	until done

	-- If new data then read last full line of the log file as current record
	if #ui.indices > i then
		index = #ui.indices - 1
		ReadLineData(ui.indices[index])
	end
	
	if logFile then io.close(logFile) end
end -- Scan()

local function init()
	lastTime = 0
	index = 1
	ReadLineData(ui.indices[index])
	Scan()
end  --  init()

local function run(event)
	-- Look for new data if inactive for over 1 second
	local thisTime = getTime()
	if thisTime - lastTime > 100 then
		Scan()
	end

	lastTime = thisTime
	
	-- Go to previous record
	if event == EVT_MINUS_BREAK or event == EVT_ROT_LEFT or event == EVT_LEFT_BREAK then
		index = index - 1
		if index <= 0 then
			index = #ui.indices - 1
			playTone(3000, 100, 0, PLAY_NOW)
		end

		logFile = io.open(LOG_FILE, "r")
		ReadLineData(ui.indices[index])
		if logFile then io.close(logFile) end
		killEvents(event)
	end

	 -- Go to next record
	if event == EVT_PLUS_BREAK or event == EVT_ROT_RIGHT or event == EVT_RIGHT_BREAK then
		index = index + 1
		if index >= #ui.indices then
			index = 1
			playTone(3000, 100, 0, PLAY_NOW)
		end

		logFile = io.open(LOG_FILE, "r")
		ReadLineData(ui.indices[index])
		if logFile then io.close(logFile) end
		killEvents(event)
	end

	-- Time to draw the screen
	if #ui.lineData < 7 then
		DrawMenu(" No scores recorded ")
	else
		DrawMenu(ui.lineData[2] .. " " .. ui.lineData[3])
		Draw()
	end
end

return {init = init, run = run}