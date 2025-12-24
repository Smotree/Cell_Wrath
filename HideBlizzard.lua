local _, Cell = ...
local F = Cell.funcs

-- stolen from elvui
local hiddenParent = CreateFrame("Frame", nil, _G.UIParent)
hiddenParent:SetAllPoints()
hiddenParent:Hide()

local function HideFrame(frame)
	if not frame then
		return
	end

	-- On WotLK/Sirus, be more careful to avoid taint
	if Cell.isWrath or Cell.isVanilla then
		-- Just hide without unregistering events or changing parent
		frame:Hide()
	else
		frame:UnregisterAllEvents()
		frame:Hide()
		frame:SetParent(hiddenParent)

		local health = frame.healthBar or frame.healthbar
		if health then
			health:UnregisterAllEvents()
		end

		local power = frame.manabar
		if power then
			power:UnregisterAllEvents()
		end

		local spell = frame.castBar or frame.spellbar
		if spell then
			spell:UnregisterAllEvents()
		end

		local altpowerbar = frame.powerBarAlt
		if altpowerbar then
			altpowerbar:UnregisterAllEvents()
		end

		local buffFrame = frame.BuffFrame
		if buffFrame then
			buffFrame:UnregisterAllEvents()
		end

		local petFrame = frame.PetFrame
		if petFrame then
			petFrame:UnregisterAllEvents()
		end
	end
end

function F.HideBlizzardParty()
	-- Don't unregister UIParent events - this taints the UI and breaks protected actions like World Markers
	-- _G.UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")

	-- On WotLK/Sirus, be very careful to avoid taint
	if Cell.isWrath or Cell.isVanilla then
		-- Just hide frames without touching events
		if _G.CompactPartyFrame then
			_G.CompactPartyFrame:Hide()
		end
		if _G.PartyFrame then
			_G.PartyFrame:Hide()
		else
			for i = 1, 4 do
				if _G["PartyMemberFrame" .. i] then
					_G["PartyMemberFrame" .. i]:Hide()
				end
			end
			if _G.PartyMemberBackground then
				_G.PartyMemberBackground:Hide()
			end
		end
		return
	end

	if _G.CompactPartyFrame then
		_G.CompactPartyFrame:UnregisterAllEvents()
	end

	if _G.PartyFrame then
		_G.PartyFrame:UnregisterAllEvents()
		_G.PartyFrame:SetScript("OnShow", nil)
		for frame in _G.PartyFrame.PartyMemberFramePool:EnumerateActive() do
			HideFrame(frame)
		end
		HideFrame(_G.PartyFrame)
	else
		for i = 1, 4 do
			HideFrame(_G["PartyMemberFrame" .. i])
			HideFrame(_G["CompactPartyMemberFrame" .. i])
		end
		HideFrame(_G.PartyMemberBackground)
	end
end

function F.HideBlizzardRaid()
	-- Don't unregister UIParent events - this taints the UI and breaks protected actions
	-- _G.UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")

	if _G.CompactRaidFrameContainer then
		-- On WotLK/Sirus, be careful not to cause taint that breaks World Markers
		if not (Cell.isWrath or Cell.isVanilla) then
			_G.CompactRaidFrameContainer:UnregisterAllEvents()
			_G.CompactRaidFrameContainer:SetParent(hiddenParent)
		else
			-- Just hide without touching events/parent
			_G.CompactRaidFrameContainer:Hide()
		end
	end
end

function F.HideBlizzardRaidManager()
	-- Don't call CompactRaidFrameManager_SetSetting - it taints the raid manager
	-- and breaks World Markers buttons
	-- if CompactRaidFrameManager_SetSetting then
	--     CompactRaidFrameManager_SetSetting("IsShown", "0")
	-- end

	if _G.CompactRaidFrameManager then
		-- Only hide if user really wants to, but this may cause taint
		-- For WotLK/Sirus, better to just hide visually without touching events
		if not (Cell.isWrath or Cell.isVanilla) then
			_G.CompactRaidFrameManager:UnregisterAllEvents()
			_G.CompactRaidFrameManager:SetParent(hiddenParent)
		else
			-- On WotLK/Sirus, just hide it without causing taint
			_G.CompactRaidFrameManager:Hide()
		end
	end
end
