-- SUI Font Override (Pink / Night-Elf Purple)
-- Candy + Nova - Enhanced Version

local ADDON = ...

------------------------------------------------------------
-- CONFIG (you can tweak these)
------------------------------------------------------------
local TINT_HEADER_TEXTURES   = false  -- set to true if you want the purple header bars/shines
local PINKIFY_ONLY_YELLOWISH = false  -- false = recolor listed fonts unconditionally (classic behavior)
                                      -- true  = only recolor those that currently look gold/yellow-ish
------------------------------------------------------------

-- === palette ===
local PINK   = { r = 1.00, g = 0.42, b = 0.88 }   -- WA pink
local PURPLE = { r = 0.45, g = 0.28, b = 0.65 }   -- Night Elf purple
local WHITE  = { r = 1.00, g = 1.00, b = 1.00 }   -- pure white
local function rgb(c) return c.r, c.g, c.b end
local function hex(c) return ("|cFF%02X%02X%02X"):format(
  math.floor(c.r*255+0.5), math.floor(c.g*255+0.5), math.floor(c.b*255+0.5)
) end

local function paint(fs, c) if fs and fs.SetTextColor then fs:SetTextColor(rgb(c)) end end

-- Remove WoW color codes from a string
local function stripColorCodes(s)
  if not s or type(s) ~= "string" then return s end
  s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  s = s:gsub("|T.-|t", "")
  return s
end

-- Hook a FontString to force a color (and keep it despite subsequent SetText calls)
local function hookFontStringColor(fs, color)
  if not fs or not fs.SetTextColor then return end
  if fs.__candy_hooked then
    fs.__candy_color = color
    fs:SetTextColor(rgb(color))
    return
  end

  fs.__candy_color = color
  fs:SetTextColor(rgb(color))

  local function apply(self, text)
    if not self or not self.SetTextColor then return end
    if text and type(text) == "string" then
      local cleaned = stripColorCodes(text)
      if cleaned ~= text then
        self:SetText(cleaned)
      end
    end
    self:SetTextColor(rgb(self.__candy_color or color))
  end

  fs:HookScript("OnShow", function(self) apply(self, self:GetText()) end)
  hooksecurefunc(fs, "SetText", function(self, text) apply(self, text) end)
  hooksecurefunc(fs, "SetFormattedText", function(self, fmt, ...)
    apply(self, string.format(fmt or "", ...))
  end)

  apply(fs)
end

-- helper: is a color "yellow/gold-ish"?
local function isYellowish(r, g, b)
  if not r or not g or not b then return false end
  -- bright, warm, low blue
  return r >= 0.80 and g >= 0.70 and b <= 0.30 and (r - g) <= 0.20
end

-- ===================================================================
-- 1) Recolor Blizzard's "yellow" font objects directly (safe checks)
-- ===================================================================

local YellowFontTargets = {
  "AchievementDateFont","AchievementPointsFont","AchievementPointsFontSmall",
  "BossEmoteNormalHuge","DialogButtonNormalText","FocusFontSmall",
  "GameFontNormal","GameFontNormalHuge","GameFontNormalLarge","GameFontNormalMed3","GameFontNormalSmall",
  "GameFont_Gigantic","GameFontNormalHuge2",
  "NumberFontNormalLargeRightYellow","NumberFontNormalLargeYellow",
  "NumberFontNormalRightYellow","NumberFontNormalYellow",
  "QuestFont_Enormous","QuestFont_Super_Huge","QuestFont_Super_Huge_Outline",
  "QuestTitleFontBlackShadow","SplashHeaderFont",
  "GameFontHighlight","GameFontHighlightSmall","ObjectiveFont",
  "QuestFont_Normal","QuestFont_Highlight",
  "GameFontNormalOutline","GameFontHighlightOutline",
  "QuestFont_Large","QuestFont_Huge","QuestFont_Shadow_Huge",
  "MailFont_Large","SystemFont_Med1","SystemFont_Med2","SystemFont_Med3",
  "SystemFont_Large","SystemFont_Huge1",
}

local function RecolorYellowFontsList()
  for _, name in ipairs(YellowFontTargets) do
    local f = _G[name]
    if f and f.SetTextColor then
      if PINKIFY_ONLY_YELLOWISH and f.GetTextColor then
        local r, g, b = f:GetTextColor()
        if isYellowish(r, g, b) then
          f:SetTextColor(rgb(PINK))
        end
      else
        f:SetTextColor(rgb(PINK))
      end
    end
  end
end

-- ===================================================================
-- 2) Global palette nudges for Blizzard color tables
-- ===================================================================

local function ApplyGlobalPalette()
  -- These are inherently yellow-ish, so we always steer them pink.
  if NORMAL_FONT_COLOR      and NORMAL_FONT_COLOR.SetRGB      then NORMAL_FONT_COLOR:SetRGB(rgb(PINK)) end
  if HIGHLIGHT_FONT_COLOR   and HIGHLIGHT_FONT_COLOR.SetRGB   then HIGHLIGHT_FONT_COLOR:SetRGB(rgb(PINK)) end
  if YELLOW_FONT_COLOR      and YELLOW_FONT_COLOR.SetRGB      then YELLOW_FONT_COLOR:SetRGB(rgb(PINK)) end
  if LIGHTYELLOW_FONT_COLOR and LIGHTYELLOW_FONT_COLOR.SetRGB then LIGHTYELLOW_FONT_COLOR:SetRGB(rgb(PINK)) end
  if GOLD_FONT_COLOR        and GOLD_FONT_COLOR.SetRGB        then GOLD_FONT_COLOR:SetRGB(rgb(PINK)) end

  RecolorYellowFontsList()

  if OBJECTIVE_TRACKER_COLOR then
    local function setC(key, col)
      local c = OBJECTIVE_TRACKER_COLOR[key]
      if c then
        if c.SetRGB then c:SetRGB(col.r, col.g, col.b) end
        c.r, c.g, c.b = col.r, col.g, col.b
      end
    end
    -- Titles pink; info white
    setC("Header", PINK)
    for _, key in ipairs({ "Normal","Objective","TimeLeft","Failed","Complete" }) do setC(key, WHITE) end
  end
end

-- ===================================================================
-- 3) Objective Tracker: titles pink, info white
-- ===================================================================

local function PaintTrackerTopBar()
  local m = ObjectiveTrackerFrame and ObjectiveTrackerFrame.HeaderMenu
  if not m then return end
  local candidates = { m.Title, m.TitleText, m.Text, m.Label }
  for _, obj in ipairs(candidates) do
    if obj and obj.GetObjectType and obj:GetObjectType() == "FontString" then
      hookFontStringColor(obj, PURPLE)
    end
  end
  local regions = { m:GetRegions() }
  for _, region in ipairs(regions) do
    if region and region.GetObjectType and region:GetObjectType() == "FontString" then
      hookFontStringColor(region, PURPLE)
    end
  end
end

local function HookHeaderMenu()
  local m = ObjectiveTrackerFrame and ObjectiveTrackerFrame.HeaderMenu
  if not m then return end
  PaintTrackerTopBar()
  if not m.__candy_hooked then
    m.__candy_hooked = true
    m:HookScript("OnShow", PaintTrackerTopBar)
    m:HookScript("OnEvent", PaintTrackerTopBar)
  end
end

local function RepaintObjectiveTracker()
  local frame = ObjectiveTrackerFrame
  if not frame then return end

  PaintTrackerTopBar()

  for _, module in pairs(frame.MODULES or {}) do
    local hdr = module and module.Header and module.Header.Text
    if hdr then hookFontStringColor(hdr, PURPLE) end
  end

  local blocksFrame = ObjectiveTrackerBlocksFrame or (frame and frame.BlocksFrame)
  if not blocksFrame or not blocksFrame.usedBlocks then return end

  for _, block in pairs(blocksFrame.usedBlocks) do
    if block.HeaderText then hookFontStringColor(block.HeaderText, PINK) end
    if block.lines then
      for _, line in pairs(block.lines) do
        if line.Text      then paint(line.Text,      WHITE) end
        if line.Dash      then paint(line.Dash,      WHITE) end
        if line.leftText  then paint(line.leftText,  WHITE) end
        if line.rightText then paint(line.rightText, WHITE) end
      end
    end
  end

  -- also enforce your purple header pass
  if PaintAllModuleHeaders then PaintAllModuleHeaders() end
end

-- ===================================================================
-- 4) Quest progress & alerts
-- ===================================================================

local function HookQuestProgressUpdates()
  if not UIErrorsFrame or not UIErrorsFrame.AddMessage then return end
  hooksecurefunc(UIErrorsFrame, "AddMessage", function(self, text, r, g, b, id, holdTime)
    if type(text) == "string" then
      local cleaned = stripColorCodes(text)
      if cleaned ~= text then
        self:AddMessage(cleaned, rgb(PINK), id, holdTime)
        return
      end
    end
  end)
end

local function HookQuestEvents()
  local f = CreateFrame("Frame")
  f:RegisterEvent("UI_INFO_MESSAGE")
  f:RegisterEvent("QUEST_ACCEPTED")
  f:RegisterEvent("QUEST_TURNED_IN")
  f:RegisterEvent("QUEST_COMPLETE")
  f:SetScript("OnEvent", function(self, event)
    C_Timer.After(0.05, RepaintObjectiveTracker)
  end)

  if ObjectiveTracker_Update then
    hooksecurefunc("ObjectiveTracker_Update", function()
      C_Timer.After(0.05, RepaintObjectiveTracker)
    end)
  end
end

-- ========================
-- 5) Tooltips + Alerts
-- ========================

local function HookTooltipColors()
  if GameTooltip and GameTooltip.TextLeft1 then
    hookFontStringColor(GameTooltip.TextLeft1, PINK)
  end
  if GameTooltipHeaderText then hookFontStringColor(GameTooltipHeaderText, PINK) end
end

local function HookAlertFrames()
  if AchievementAlertFrame1 then
    hooksecurefunc(AchievementAlertSystem, "addAlert", function()
      C_Timer.After(0.1, function()
        for i = 1, MAX_ACHIEVEMENT_ALERTS do
          local frame = _G["AchievementAlertFrame" .. i]
          if frame and frame:IsShown() then
            if frame.Name then paint(frame.Name, PINK) end
            if frame.Points then paint(frame.Points, PINK) end
          end
        end
      end)
    end)
  end
  if AlertFrame then
    AlertFrame:HookScript("OnUpdate", function()
      C_Timer.After(0.05, function()
        ApplyGlobalPalette()
        RepaintObjectiveTracker()
      end)
    end)
  end
end

-- ===================================================================
-- 6) Chat attention channels -> pink
-- ===================================================================

local function PinkifyChat()
  if not ChatTypeInfo then return end
  local types = {
    "SYSTEM","EMOTE","TEXT_EMOTE",
    "ACHIEVEMENT","GUILD_ACHIEVEMENT",
    "RAID_WARNING","RAID_BOSS_EMOTE","RAID_BOSS_WHISPER",
  }
  for _, t in ipairs(types) do
    local info = ChatTypeInfo[t]
    if info then info.r, info.g, info.b = rgb(PINK) end
  end
end

-- ===================================================================
-- 7) YOUR EXISTING HEADER FIX (UNCHANGED) + toggled texture tint
-- ===================================================================

-- === turn those gold/yellow headers to PURPLE ===

-- keep any FontString locked to our color
local function hookColor(fs, color)
  if not fs or fs.__candy_hooked then return end
  fs.__candy_hooked = true
  local function apply(self, raw)
    local clean = (raw or self:GetText() or ""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
    if clean == "" or self.__candy_lock then return end
    self.__candy_lock = true
    self:SetText(("|cFF%02X%02X%02X"):format(
      math.floor(color.r*255+0.5), math.floor(color.g*255+0.5), math.floor(color.b*255+0.5)
    )..clean.."|r")
    self.__candy_lock = false
  end
  hooksecurefunc(fs, "SetText", apply)
  hooksecurefunc(fs, "SetFormattedText", function(self, fmt, ...) apply(self, fmt and fmt:format(...)) end)
  apply(fs)
end

-- tint header textures (those shiny gold bars) to purple too
local function tintHeaderTextures(h)
  if not h or not TINT_HEADER_TEXTURES then return end
  local function tint(tex, a)
    if tex and tex.SetVertexColor then
      if tex.SetDesaturated then pcall(tex.SetDesaturated, tex, true) end
      tex:SetVertexColor(PURPLE.r, PURPLE.g, PURPLE.b, a or tex:GetAlpha() or 1)
    end
  end
  tint(h.Background); tint(h.Shine, 0.85); tint(h.Glow, 0.85)
  if h.NineSlice and h.NineSlice.GetRegions then
    for _, r in ipairs({ h.NineSlice:GetRegions() }) do
      if r and r.SetVertexColor then r:SetVertexColor(PURPLE.r, PURPLE.g, PURPLE.b) end
    end
  end
end

-- apply to each header
local function enforceHeader(h)
  if not h then return end
  if h.Text then hookColor(h.Text, PURPLE) end
  if h.GetRegions then
    for _, r in ipairs({ h:GetRegions() }) do
      if r and r.GetObjectType and r:GetObjectType()=="FontString" then hookColor(r, PURPLE) end
    end
  end
  tintHeaderTextures(h) -- respects TINT_HEADER_TEXTURES
end

-- the specific headers in the Objective Tracker
local function PaintAllModuleHeaders()
  local list = {
    ObjectiveTrackerFrame and ObjectiveTrackerFrame.Header,                -- "All Objectives"
    _G.QuestObjectiveTracker and _G.QuestObjectiveTracker.Header,          -- "Quests"
    _G.CampaignQuestObjectiveTracker and _G.CampaignQuestObjectiveTracker.Header, -- "Campaign"
    _G.WorldQuestObjectiveTracker and _G.WorldQuestObjectiveTracker.Header,
    _G.ScenarioObjectiveTracker and _G.ScenarioObjectiveTracker.Header,
    _G.AchievementObjectiveTracker and _G.AchievementObjectiveTracker.Header,
  }
  for _, h in ipairs(list) do enforceHeader(h) end
end

-- add the Game Menu panel header using the same enforcement
local function PaintGameMenuHeader()
  if GameMenuFrame and GameMenuFrame.Header then
    enforceHeader(GameMenuFrame.Header)
  end
  if GameMenuFrame and GameMenuFrame.TitleText then hookColor(GameMenuFrame.TitleText, PURPLE) end
end

local function HookGameMenuHeader()
  if not GameMenuFrame then return end
  if not GameMenuFrame.__candy_header_hook then
    GameMenuFrame.__candy_header_hook = true
    GameMenuFrame:HookScript("OnShow", function()
      C_Timer.After(0, PaintGameMenuHeader)
    end)
  end
  C_Timer.After(0.05, PaintGameMenuHeader)
end

-- ===================================================================
-- 8) Init / late-load safety
-- ===================================================================

local function Init()
  ApplyGlobalPalette()
  RecolorYellowFontsList()
  HookTooltipColors()
  HookAlertFrames()
  PinkifyChat()

  if ObjectiveTracker_Update then
    hooksecurefunc("ObjectiveTracker_Update", RepaintObjectiveTracker)
  end

  local modules = {
    _G.QUEST_TRACKER_MODULE,
    _G.CAMPAIGN_QUEST_TRACKER_MODULE,
    _G.WORLD_QUEST_TRACKER_MODULE,
    _G.SCENARIO_TRACKER_MODULE,
    _G.ACHIEVEMENT_TRACKER_MODULE,
  }
  for _, m in ipairs(modules) do
    if m and m.Update then hooksecurefunc(m, "Update", RepaintObjectiveTracker) end
  end

  HookHeaderMenu()
  HookQuestProgressUpdates()
  HookQuestEvents()

  PaintAllModuleHeaders()
  HookGameMenuHeader()

  C_Timer.After(0.05, RepaintObjectiveTracker)
  C_Timer.After(0.25, RepaintObjectiveTracker)
end

-- ===================================================================
-- 9) ADDON LOADING
-- ===================================================================

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, arg1)
  if event == "PLAYER_LOGIN" then
    Init()
  elseif event == "ADDON_LOADED" then
    if arg1 == "Blizzard_ObjectiveTracker" or
       arg1 == "Blizzard_AchievementUI"   or
       arg1 == "Blizzard_WorldMap"        or
       arg1 == "Blizzard_Settings"        or
       arg1 == "SUI" then
      C_Timer.After(0.1, function()
        ApplyGlobalPalette()
        RecolorYellowFontsList()
        HookHeaderMenu()
        RepaintObjectiveTracker()
        HookTooltipColors()
        HookAlertFrames()
        PaintAllModuleHeaders()
        HookGameMenuHeader()
      end)
    end
  end
end)

-- ===================================================================
-- 10) Slash commands
-- ===================================================================

SLASH_SUIFONT1, SLASH_SUIFONT2 = "/suifont", "/suipaint"
SlashCmdList.SUIFONT = function(msg)
  if msg == "reload" then ReloadUI() return end
  ApplyGlobalPalette()
  RepaintObjectiveTracker()
  PaintAllModuleHeaders()
  HookGameMenuHeader()
  print(hex(PINK).."SUI Font Override|r: refreshed.")
end
