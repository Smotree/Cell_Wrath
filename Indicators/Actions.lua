local _, Cell = ...
local L = Cell.L
---@type CellFuncs
local F = Cell.funcs
---@class CellIndicatorFuncs
local I = Cell.iFuncs

local orientation, speed

-------------------------------------------------
-- events
-------------------------------------------------
-- CLEU: subevent, source, target, spellId, spellName
-- [15:10] SPELL_HEAL 秋静葉 秋静葉 6262 治疗石
-- [15:10] SPELL_CAST_SUCCESS 秋静葉 nil 6262 治疗石
-- [15:13] SPELL_HEAL 秋静葉 秋静葉 307192 灵魂治疗药水
-- [15:13] SPELL_CAST_SUCCESS 秋静葉 nil 307192 灵魂治疗药水

-- UNIT_SPELLCAST_SUCCEEDED
-- unit, castGUID, spellID

local function Display(b, ...)
	b.indicators.actions:Display(...)
end

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(self, event, unit, arg2, arg3)
	-- filter out players not in your group
	if not (UnitInRaid(unit) or UnitInParty(unit) or unit == "player" or unit == "pet") then
		return
	end

	local spellID

	if Cell.isRetail then
		-- Retail: unit, castGUID, spellID
		spellID = arg3

		if Cell.vars.actionsDebugModeEnabled then
			local name = F.GetSpellInfo(spellID)
			print(
				"|cFFFF3030[Cell]|r |cFFB2B2B2" .. event .. ":|r",
				unit,
				"|cFF00FF00" .. (spellID or "nil") .. "|r",
				name
			)
		end
	else
		-- WotLK/Cata/Vanilla: unit, spellName, rank
		local spellName = arg2
		-- Try to resolve spellID by matching name against configured actions
		if Cell.vars.actions then
			for id, _ in pairs(Cell.vars.actions) do
				local name = GetSpellInfo(id)
				if name and name == spellName then
					spellID = id
					break
				end
			end
		end

		if Cell.vars.actionsDebugModeEnabled then
			print(
				"|cFFFF3030[Cell]|r |cFFB2B2B2" .. event .. ":|r",
				unit,
				"|cFF00FF00" .. (spellName or "nil") .. "|r",
				"-> ID:",
				spellID or "Not Found"
			)
		end
	end

	if spellID and Cell.vars.actions[spellID] then
		F.HandleUnitButton("unit", unit, Display, unpack(Cell.vars.actions[spellID]))
	end
end)

-- local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
-- eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
-- eventFrame:SetScript("OnEvent", function()
--     local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName = CombatLogGetCurrentEventInfo()
--     print(subevent, sourceName, destName, spellId, spellName)
-- end)

-------------------------------------------------
-- pool
-------------------------------------------------
local animationPool = {}

local function ResetterFunc(_, canvas)
	canvas:Hide()
end

-------------------------------------------------
-- animation: A
-------------------------------------------------
local function CreateAnimationGroup_TypeA()
	-- Use ScrollFrame for clipping in WotLK (masks don't work)
	local canvas = CreateFrame("ScrollFrame")
	canvas:EnableMouse(false)

	-- ScrollChild to hold the animated content
	local scrollChild = CreateFrame("Frame")
	canvas:SetScrollChild(scrollChild)
	scrollChild:EnableMouse(false)

	-- frame
	local f = CreateFrame("Frame", nil, scrollChild)

	-- texture
	local tex = f:CreateTexture(nil, "ARTWORK")
	tex:SetAllPoints(f)
	tex:SetTexture(Cell.vars.whiteTexture)

	f:EnableMouse(false)

	-- animation
	local ag = f:CreateAnimationGroup()
	canvas.ag = ag

	local a1 = ag:CreateAnimation("Alpha")
	a1.duration = 0.6
	a1:SetFromAlpha(0)
	a1:SetToAlpha(1)
	a1:SetOrder(1)
	a1:SetDuration(a1.duration)
	a1:SetSmoothing("OUT")

	local t1 = ag:CreateAnimation("Translation")
	t1.duration = 0.6
	t1:SetOrder(1)
	t1:SetSmoothing("OUT")
	t1:SetDuration(t1.duration)

	local a2 = ag:CreateAnimation("Alpha")
	a2.duration = 0.5
	a2:SetFromAlpha(1)
	a2:SetToAlpha(0)
	a2:SetDuration(a2.duration)
	a2:SetOrder(2)
	-- a2:SetSmoothing("IN")

	ag:SetScript("OnPlay", function()
		canvas:Show()
	end)

	ag:SetScript("OnFinished", function()
		animationPool.A:Release(canvas)
	end)

	function ag:Display(parent, r, g, b)
		canvas:SetParent(parent)
		canvas:SetAllPoints(parent)
		scrollChild:SetSize(parent:GetWidth(), parent:GetHeight())

		if parent.orientation == "horizontal" then
			f:ClearAllPoints()
			f:SetPoint("TOPRIGHT", scrollChild, "TOPLEFT")
			f:SetPoint("BOTTOMRIGHT", scrollChild, "BOTTOMLEFT")
			f:SetWidth(15)

			t1:SetOffset(canvas:GetWidth(), 0)
			tex:SetVertexColor(r, g, b, 1)
		else
			f:ClearAllPoints()
			f:SetPoint("TOPLEFT", scrollChild, "BOTTOMLEFT")
			f:SetPoint("TOPRIGHT", scrollChild, "BOTTOMRIGHT")
			f:SetHeight(15)

			t1:SetOffset(0, canvas:GetHeight())
			tex:SetVertexColor(r, g, b, 1)
		end

		a1:SetDuration(a1.duration / parent.speed)
		t1:SetDuration(t1.duration / parent.speed)
		a2:SetDuration(a2.duration / parent.speed)

		if ag:IsPlaying() then
			ag:Restart()
		else
			ag:Play()
		end
	end

	return canvas
end

animationPool.A = CreateObjectPool(CreateAnimationGroup_TypeA, ResetterFunc)

-------------------------------------------------
-- animation: B
-------------------------------------------------
local function CreateAnimationGroup_TypeB()
	local WIDTH = 20

	-- Use ScrollFrame for clipping in WotLK (masks don't work)
	local canvas = CreateFrame("ScrollFrame")
	canvas:EnableMouse(false)

	-- ScrollChild to hold the animated content
	local scrollChild = CreateFrame("Frame")
	canvas:SetScrollChild(scrollChild)
	scrollChild:EnableMouse(false)

	-- frame
	local f = CreateFrame("Frame", nil, scrollChild)
	f:SetPoint("TOPRIGHT", scrollChild, "TOPLEFT")
	f:SetPoint("BOTTOMRIGHT", scrollChild, "BOTTOMLEFT")
	f:SetWidth(WIDTH)

	-- texture
	local tex = f:CreateTexture(nil, "ARTWORK")
	tex:SetPoint("BOTTOMRIGHT")
	tex:SetWidth(WIDTH)
	if tex.SetRotation then
		tex:SetRotation(45 * math.pi / 180)
	end

	f:EnableMouse(false)

	-- animation
	local ag = f:CreateAnimationGroup()
	canvas.ag = ag

	local a1 = ag:CreateAnimation("Alpha")
	a1.duration = 0.35
	a1:SetFromAlpha(0)
	a1:SetToAlpha(0.7)
	a1:SetDuration(a1.duration)

	local t1 = ag:CreateAnimation("Translation")
	t1.duration = 0.7
	t1:SetSmoothing("IN_OUT")
	t1:SetDuration(t1.duration)

	ag:SetScript("OnPlay", function()
		canvas:Show()
	end)

	ag:SetScript("OnFinished", function()
		animationPool.B:Release(canvas)
	end)

	function ag:Display(parent, r, g, b)
		canvas:SetParent(parent)
		canvas:SetAllPoints(parent)
		scrollChild:SetSize(parent:GetWidth(), parent:GetHeight())

		a1:SetDuration(a1.duration / parent.speed)
		t1:SetDuration(t1.duration / parent.speed)

		t1:SetOffset(canvas:GetWidth() + math.tan(math.pi / 4) * canvas:GetHeight() + WIDTH / math.cos(math.pi / 4), 0)
		tex:SetHeight(canvas:GetHeight() / math.sin(math.pi / 4) + WIDTH)
		tex:SetTexture(Cell.vars.whiteTexture)
		tex:SetVertexColor(r, g, b, 1)

		if ag:IsPlaying() then
			ag:Restart()
		else
			ag:Play()
		end
	end

	return canvas
end

animationPool.B = CreateObjectPool(CreateAnimationGroup_TypeB, ResetterFunc)

-------------------------------------------------
-- animation: C
-------------------------------------------------
local function CreateAnimationGroup_TypeC()
	local canvas = CreateFrame("Frame")

	-- frame
	local f = CreateFrame("Frame", nil, canvas)

	-- texture
	local tex = f:CreateTexture(nil, "ARTWORK")
	tex:SetAllPoints(f)
	tex:SetTexture("Interface\\AddOns\\Cell_Wrath\\Media\\Icons\\upgrade.tga")

	canvas:EnableMouse(false)
	f:EnableMouse(false)

	-- animation
	local ag = f:CreateAnimationGroup()
	canvas.ag = ag

	local a1 = ag:CreateAnimation("Alpha")
	a1.duration = 0.5
	a1:SetFromAlpha(0)
	a1:SetToAlpha(1)
	a1:SetOrder(1)
	a1:SetDuration(a1.duration)
	a1:SetSmoothing("OUT")

	local t1 = ag:CreateAnimation("Translation")
	t1.duration = 0.5
	t1:SetOrder(1)
	t1:SetSmoothing("OUT")
	t1:SetDuration(t1.duration)

	local a2 = ag:CreateAnimation("Alpha")
	a2.duration = 0.5
	a2:SetFromAlpha(1)
	a2:SetToAlpha(0)
	a2:SetDuration(a2.duration)
	a2:SetOrder(2)
	a2:SetSmoothing("IN")

	ag:SetScript("OnPlay", function()
		canvas:Show()
	end)

	ag:SetScript("OnFinished", function()
		animationPool.C:Release(canvas)
	end)

	function ag:Display(parent, subType, r, g, b)
		canvas:SetParent(parent)
		canvas:SetAllPoints(parent)

		f:ClearAllPoints()
		if subType == "1" then
			f:SetPoint("BOTTOMLEFT")
			f:SetPoint("TOPLEFT", canvas, "LEFT")
		elseif subType == "2" then
			f:SetPoint("BOTTOM")
			f:SetPoint("TOP", canvas, "CENTER")
		else
			f:SetPoint("BOTTOMRIGHT")
			f:SetPoint("TOPRIGHT", canvas, "RIGHT")
		end

		a1:SetDuration(a1.duration / parent.speed)
		t1:SetDuration(t1.duration / parent.speed)
		a2:SetDuration(a2.duration / parent.speed)

		f:SetWidth(canvas:GetHeight() / 2)
		t1:SetOffset(0, canvas:GetHeight() / 2)
		-- tex:SetGradient("VERTICAL", CreateColor(r, g, b, 0), CreateColor(r, g, b, 1))
		-- tex:SetGradientAlpha("VERTICAL", r, g, b, 0, r, g, b, 1)
		tex:SetVertexColor(r, g, b, 1)

		if ag:IsPlaying() then
			ag:Restart()
		else
			ag:Play()
		end
	end

	return canvas
end

animationPool.C = CreateObjectPool(CreateAnimationGroup_TypeC, ResetterFunc)

-------------------------------------------------
-- animation: D
-------------------------------------------------
local function CreateAnimationGroup_TypeD()
	-- Use ScrollFrame for clipping in WotLK
	local canvas = CreateFrame("ScrollFrame")
	canvas:EnableMouse(false)

	local scrollChild = CreateFrame("Frame")
	canvas:SetScrollChild(scrollChild)
	scrollChild:EnableMouse(false)

	-- frame
	local f = CreateFrame("Frame", nil, scrollChild)
	f:SetAllPoints(scrollChild)

	-- texture - use circle texture directly instead of mask
	local tex = f:CreateTexture(nil, "ARTWORK")
	tex:SetPoint("CENTER")
	tex:SetTexture("Interface\\AddOns\\Cell_Wrath\\Media\\Shapes\\circle_filled_256.tga")

	f:EnableMouse(false)

	-- animation
	local ag = f:CreateAnimationGroup()
	canvas.ag = ag

	local a1 = ag:CreateAnimation("Alpha")
	a1.duration = 0.3
	a1:SetFromAlpha(0)
	a1:SetToAlpha(1)
	a1:SetOrder(1)
	a1:SetDuration(a1.duration)
	a1:SetSmoothing("OUT")

	local s1 = ag:CreateAnimation("Scale")
	s1.duration = 0.5
	s1:SetScaleFrom(0, 0)
	s1:SetScaleTo(1, 1)
	s1:SetOrder(1)
	s1:SetDuration(s1.duration)

	local a2 = ag:CreateAnimation("Alpha")
	a2.duration = 0.5
	a2:SetFromAlpha(1)
	a2:SetToAlpha(0)
	a2:SetDuration(a2.duration)
	a2:SetOrder(2)
	a2:SetSmoothing("IN")

	ag:SetScript("OnPlay", function()
		canvas:Show()
	end)

	ag:SetScript("OnFinished", function()
		animationPool.D:Release(canvas)
	end)

	function ag:Display(parent, r, g, b)
		canvas:SetParent(parent)
		canvas:SetAllPoints(parent)
		scrollChild:SetSize(parent:GetWidth(), parent:GetHeight())

		a1:SetDuration(a1.duration / parent.speed)
		s1:SetDuration(s1.duration / parent.speed)
		a2:SetDuration(a2.duration / parent.speed)

		local l = math.sqrt((parent:GetParent():GetHeight() / 2) ^ 2 + (parent:GetParent():GetWidth() / 2) ^ 2) * 2
		tex:SetSize(l, l)
		tex:SetVertexColor(r, g, b, 0.6)

		if ag:IsPlaying() then
			ag:Restart()
		else
			ag:Play()
		end
	end

	return canvas
end

animationPool.D = CreateObjectPool(CreateAnimationGroup_TypeD, ResetterFunc)

-------------------------------------------------
-- animation: E
-------------------------------------------------
local function CreateAnimationGroup_TypeE()
	-- Use ScrollFrame for clipping in WotLK
	local canvas = CreateFrame("ScrollFrame")
	canvas:EnableMouse(false)

	local scrollChild = CreateFrame("Frame")
	canvas:SetScrollChild(scrollChild)
	scrollChild:EnableMouse(false)

	-- frame
	local f = CreateFrame("Frame", nil, scrollChild)
	f:SetPoint("TOPRIGHT", scrollChild, "TOPLEFT")
	f:SetPoint("BOTTOMRIGHT", scrollChild, "BOTTOMLEFT")

	-- texture
	local tex = f:CreateTexture(nil, "ARTWORK")
	tex:SetAllPoints(f)
	tex:SetTexture("Interface\\AddOns\\Cell_Wrath\\Media\\Icons\\arrow.tga")
	f:EnableMouse(false)

	-- animation
	local ag = f:CreateAnimationGroup()
	canvas.ag = ag

	local t1 = ag:CreateAnimation("Translation")
	t1.duration = 0.8
	t1:SetSmoothing("IN_OUT")
	t1:SetDuration(t1.duration)

	ag:SetScript("OnPlay", function()
		canvas:Show()
	end)

	ag:SetScript("OnFinished", function()
		animationPool.E:Release(canvas)
	end)

	function ag:Display(parent, r, g, b)
		canvas:SetParent(parent)
		canvas:SetAllPoints(parent)
		scrollChild:SetSize(parent:GetWidth(), parent:GetHeight())

		t1:SetDuration(t1.duration / parent.speed)

		local l = canvas:GetHeight() * 2
		f:SetWidth(l)
		t1:SetOffset(l + canvas:GetWidth(), 0)

		tex:SetVertexColor(r, g, b, 0.6)

		if ag:IsPlaying() then
			ag:Restart()
		else
			ag:Play()
		end
	end

	return canvas
end

animationPool.E = CreateObjectPool(CreateAnimationGroup_TypeE, ResetterFunc)

-------------------------------------------------
-- animation: F
-------------------------------------------------
local function CreateAnimationGroup_TypeF()
	-- Use ScrollFrame for clipping in WotLK
	local canvas = CreateFrame("ScrollFrame")
	canvas:EnableMouse(false)

	local scrollChild = CreateFrame("Frame")
	canvas:SetScrollChild(scrollChild)
	scrollChild:EnableMouse(false)

	-- frame
	local f = CreateFrame("Frame", nil, scrollChild)
	f:SetAllPoints(scrollChild)

	-- texture - use heart texture directly instead of mask
	local tex = f:CreateTexture(nil, "ARTWORK")
	tex:SetPoint("CENTER")
	tex:SetTexture("Interface\\AddOns\\Cell_Wrath\\Media\\Shapes\\heart_filled_256.tga")

	f:EnableMouse(false)

	-- animation
	local ag = f:CreateAnimationGroup()
	canvas.ag = ag

	local a1 = ag:CreateAnimation("Alpha")
	a1.duration = 0.3
	a1:SetFromAlpha(0)
	a1:SetToAlpha(1)
	a1:SetOrder(1)
	a1:SetDuration(a1.duration)
	a1:SetSmoothing("OUT")

	local s1 = ag:CreateAnimation("Scale")
	s1.duration = 0.5
	s1:SetScaleFrom(0, 0)
	s1:SetScaleTo(1, 1)
	s1:SetOrder(1)
	s1:SetDuration(s1.duration)

	local a2 = ag:CreateAnimation("Alpha")
	a2.duration = 0.5
	a2:SetFromAlpha(1)
	a2:SetToAlpha(0)
	a2:SetDuration(a2.duration)
	a2:SetOrder(2)
	a2:SetSmoothing("IN")

	ag:SetScript("OnPlay", function()
		canvas:Show()
	end)

	ag:SetScript("OnFinished", function()
		animationPool.F:Release(canvas)
	end)

	function ag:Display(parent, r, g, b)
		canvas:SetParent(parent)
		canvas:SetAllPoints(parent)
		scrollChild:SetSize(parent:GetWidth(), parent:GetHeight())

		a1:SetDuration(a1.duration / parent.speed)
		s1:SetDuration(s1.duration / parent.speed)
		a2:SetDuration(a2.duration / parent.speed)

		local l = max(parent:GetParent():GetWidth(), parent:GetParent():GetHeight()) * 2
		tex:SetSize(l, l)
		tex:SetVertexColor(r, g, b, 0.6)

		if ag:IsPlaying() then
			ag:Restart()
		else
			ag:Play()
		end
	end

	return canvas
end

animationPool.F = CreateObjectPool(CreateAnimationGroup_TypeF, ResetterFunc)

-------------------------------------------------
-- animation: G
-------------------------------------------------
local function CreateAnimationGroup_TypeG()
	local canvas = CreateFrame("Frame")

	-- frame
	local f = CreateFrame("Frame", nil, canvas)
	f:SetPoint("TOPLEFT", canvas)
	f:SetPoint("TOPRIGHT", canvas)

	-- texture
	local tex = f:CreateTexture(nil, "ARTWORK")
	tex:SetAllPoints(f)
	tex:SetTexture(Cell.vars.whiteTexture)

	canvas:EnableMouse(false)
	f:EnableMouse(false)

	-- animation
	local ag = f:CreateAnimationGroup()
	canvas.ag = ag

	local a1 = ag:CreateAnimation("Alpha")
	a1.duration = 0.5
	a1:SetFromAlpha(0)
	a1:SetToAlpha(1)
	a1:SetOrder(1)
	a1:SetDuration(a1.duration)
	a1:SetSmoothing("OUT")

	local a2 = ag:CreateAnimation("Alpha")
	a2.duration = 0.5
	a2:SetFromAlpha(1)
	a2:SetToAlpha(0)
	a2:SetDuration(a2.duration)
	a2:SetOrder(2)
	a2:SetSmoothing("IN")

	ag:SetScript("OnPlay", function()
		canvas:Show()
	end)

	ag:SetScript("OnFinished", function()
		animationPool.G:Release(canvas)
	end)

	function ag:Display(parent, r, g, b)
		canvas:SetParent(parent)
		canvas:SetAllPoints(parent)

		f:SetHeight(canvas:GetHeight() / 2)

		-- tex:SetGradient("VERTICAL", CreateColor(r, g, b, 0), CreateColor(r, g, b, 1))
		-- tex:SetGradientAlpha("VERTICAL", r, g, b, 0, r, g, b, 1)
		tex:SetVertexColor(r, g, b, 1)

		a1:SetDuration(a1.duration / parent.speed)
		a2:SetDuration(a2.duration / parent.speed)

		if ag:IsPlaying() then
			ag:Restart()
		else
			ag:Play()
		end
	end

	return canvas
end

animationPool.G = CreateObjectPool(CreateAnimationGroup_TypeG, ResetterFunc)

-------------------------------------------------
-- indicator
-------------------------------------------------
local previews = {}
local previewOrientation

local function Actions_SetSpeed(self, speed)
	self.speed = speed
end

local function Actions_Display(self, animationType, color)
	-- animations[animationType]:Display(unpack(color))
	-- if Cell.vars.actionsDebugModeEnabled then
	--    print("Actions_Display:", animationType, color[1], color[2], color[3])
	-- end

	if strfind(animationType, "^C") then
		local subType = strmatch(animationType, "%d")
		local canvas = animationPool.C:Acquire()
		canvas.ag:Display(self, subType, color[1], color[2], color[3])
	else
		local canvas = animationPool[animationType]:Acquire()
		canvas.ag:Display(self, color[1], color[2], color[3])
	end
end

function I.CreateActions(parent, isPreview)
	local actions =
		CreateFrame("Frame", parent:GetName() .. "ActionsParent", isPreview and parent or parent.widgets.indicatorFrame)

	if isPreview then
		parent.actions = actions
		tinsert(previews, parent)
		actions:SetPoint("TOPLEFT", 1, -1)
		actions:SetPoint("BOTTOMRIGHT", -1, 1)
		actions.orientation = previewOrientation
	else
		parent.indicators.actions = actions
		actions:SetAllPoints(parent.widgets.healthBar)
	end

	actions:EnableMouse(false)

	actions.speed = 1
	actions.SetSpeed = Actions_SetSpeed
	actions.Display = Actions_Display
end

function I.UpdateActionsOrientation(button, barOrientation)
	button.indicators.actions.orientation = barOrientation

	if previewOrientation ~= barOrientation then
		previewOrientation = barOrientation
		for _, p in pairs(previews) do
			p.actions.orientation = barOrientation
		end
	end
end

function I.EnableActions(enabled)
	if enabled then
		eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	else
		eventFrame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	end
end
