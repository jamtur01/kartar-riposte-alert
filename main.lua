
-- initialize alert frame and all subframes
local function initAlert()

	--create base frame
	KRAAlertFrame = CreateFrame("Frame", nil, UIParent)
	KRAAlertFrame:SetSize(50, 50)

	--init DummyFrame (used to move frame later)
	DummyFrame = CreateFrame("Frame", nil, UIParent)
	
	-- set initial position on first log on
	if POSX == nil or POSY == nil then
		KRAAlertFrame:SetPoint("CENTER",100, 0)
		_, _, _, POSX, POSY = KRAAlertFrame:GetPoint()		
	else -- if not first log in, load saved position from SavedVariables: POSX and POSY
		KRAAlertFrame:SetPoint("CENTER",POSX, POSY)
	end
	
	-- the base alert frame is just a black square which will work as a background
	KRAAlertFrame.texture = KRAAlertFrame:CreateTexture()
	KRAAlertFrame.texture:SetAllPoints()
	KRAAlertFrame.texture:SetColorTexture(0.0, 0.0, 0.0, 1)
	
	-- create riposte icon frame
	KRAAlertFrameIcon = CreateFrame("StatusBar", nil, KRAAlertFrame)
	KRAAlertFrameIcon:SetSize(50, 50)
	KRAAlertFrameIcon:SetPoint("TOP", 0, 0)
	KRAAlertFrameIcon.texture = KRAAlertFrameIcon:CreateTexture()
	KRAAlertFrameIcon.texture:SetAllPoints(true)	
	KRAAlertFrameIcon.texture:SetTexture("Interface\\Icons\\ability_warrior_challange")
	
	-- this is the frame used to create the cooldown swipe / fade out animation
	KRAAlertFrameFade = CreateFrame("StatusBar", nil, KRAAlertFrameIcon)
	KRAAlertFrameFade:SetSize(50, 50)
	KRAAlertFrameFade:SetPoint("TOP", 0, 0)
	KRAAlertFrameFade.texture = KRAAlertFrameFade:CreateTexture()
	KRAAlertFrameFade.texture:SetAllPoints(true)	
	KRAAlertFrameFade.texture:SetColorTexture(0.0, 0.0, 0.0, 0.5)
	
	-- this is the text that shows the remaning time on the current riposte window
	timerText = KRAAlertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	timerText:SetPoint("CENTER",0,-25-5)
	timerText:SetText("")

	KRAAlertFrame:Hide() -- hide the frame after done initializing
end


local function unlock()
	
	-- create dummy frame to position alert frame (initialized in init func)	
	DummyFrame:Show()
	DummyFrame:SetSize(50, 50)
	DummyFrame:SetPoint("CENTER",POSX, POSY)
	DummyFrame.texture = DummyFrame:CreateTexture()
	DummyFrame.texture:SetAllPoints()
	DummyFrame.texture:SetTexture("Interface\\Icons\\ability_warrior_challange")

	-- make DummyFrame moveable and save its position
	DummyFrame:SetMovable(true)
	DummyFrame:EnableMouse(true)
	DummyFrame:RegisterForDrag("LeftButton")
	DummyFrame:SetScript("OnDragStart", DummyFrame.StartMoving)	
	function setFramePos()
		DummyFrame:StopMovingOrSizing()
		_, _, _, POSX, POSY = DummyFrame:GetPoint() -- saves points POSX and POSY to saved variables
		
	end
	DummyFrame:SetScript("OnDragStop",setFramePos)


	-- create text to help user
	moveText = DummyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	moveText:SetPoint("TOP",0,12)
	moveText:SetText("Move me!")

	lockText = DummyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	lockText:SetPoint("BOTTOM",0,-12)
	lockText:SetText("'/kra lock' to lock")

end

local function lock()
	DummyFrame:EnableMouse(false)
	DummyFrame:Hide()
end

-- The event that is triggered after an attack is parried
local function triggerAlert()

	lock()
	KRAAlertFrame:SetPoint("CENTER",POSX, POSY)

	-- show the frame
	KRAAlertFrame:Show()
	
	-- set a few useful variables
	local START = 0
	local END = 6
	local timer = 0
	KRAAlertFrameFade:SetMinMaxValues(START, END)

	--this is the script for the timer
	KRAAlertFrameFade:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed -- add the amount of time elapsed since last update to current timer
		percDone = timer / END -- get percentage of total time elapsed 
		KRAAlertFrameFade:SetSize(50, 50*percDone) -- update the fade frame to reflect time remaining
		timerText:SetText(string.format("%.1f", END - timer)) --update the timer below the alert
		
		-- when timer has reached the desired value, as defined by END (seconds), restart it by setting it to 0, as defined by START
		if timer >= END then
			timer = START -- reset timer to 0			
			KRAAlertFrame:Hide() -- hide the frame since completed
		end
	end)
	
end

-- combat log function
local function OnEvent(self, event)
	if(GetSpellInfo(NAME_RIPOSTE)) then -- only load if player knows the spell
		local timestamp, eventType, hideCaster,
		srcGUID, srcName, srcFlags, srcFlags2,
		dstGUID, dstName, dstFlags, dstFlags2,
		arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 = CombatLogGetCurrentEventInfo()

		-- read thru player's combat log
		if srcName == UnitName("player") then
		  if(action=="SPELL_CAST_SUCCESS" and arg2==NAME_RIPOSTE) then 
			KRAAlertFrame:Hide()
		  end
		end

		if dstName == UnitName("player") then
			-- below works on both swings and spells
			if eventType == "SWING_MISSED" or eventType == "SPELL_MISSED" then
				local missedType
				if eventType == "SWING_MISSED" then
					missedType = arg1
				elseif eventType == "SPELL_MISSED" then
					missedType = arg4
				end
				if missedType == "PARRY" then
					triggerAlert()	
				end
			end
		end
		
		-- this code fades out riposte alert when riposte is still on cd
		local start, duration, enabled, _ = GetSpellCooldown(NAME_RIPOSTE)
		local rpCD = start + duration - GetTime()
			if(rpCD > 1.5) then
			KRAAlertFrame:SetAlpha(.2)
		else
			KRAAlertFrame:SetAlpha(1)
		end
	end
end

-- create a /command to test the alert
SLASH_KRA_TEST1 = "/kra"
SlashCmdList["KRA_TEST"] = function(msg)

	if(msg=="test" or msg=="t") then
		triggerAlert()
		
	elseif(msg=="unlock" or msg=="u" or msg=="ul") then
		print("Unlocking frame.")
		unlock()
	elseif(msg=="lock" or msg=="l") then
		print("Locking frame.")
		lock()
	elseif(msg=="reset") then
		print("Resetting position.")
		POSX = 100
		POSY = 0
	else 
		print("-- Kartar's Riposte Alert --")
		print("Commands:")
		print("   '/kra unlock' - Unlocks frame to be moved")
		print("   '/kra lock'   - Locks frame in place")
		print("   '/kra reset'  - Reset the position of the alert frame")
		print("   '/kra test'   - Test the alert")
	end
   	
end 

-- created hidden frame, register it to look at combat log events, on each combat log event load OnEvent() function
local f = CreateFrame("Frame")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:SetScript("OnEvent", OnEvent)

NAME_RIPOSTE = GetSpellInfo(14251)

initAlert() -- initialize the alert frame
print("Kartar Riposte Alert loaded.")