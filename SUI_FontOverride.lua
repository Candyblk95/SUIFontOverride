-- SUI Font Override (Pink / Night-Elf Purple)
-- Candy + Nova

local ADDON = ...

-- === palette ===
local PINK   = { r = 1.00, g = 0.42, b = 0.88 }   -- WA pink
local PURPLE = { r = 0.45, g = 0.28, b = 0.65 }   -- Night Elf purple
local function rgb(c) return c.r, c.g, c.b end
local function hex(c) return ("|cFF%02X%02X%02X"):format(
  math.floor(c.r*255+0.5), math.floor(c.g*255+0.5), math.floor(c.b*255+0.5)
) end

local function paint(fs, c) if fs and fs.SetTextColor then fs:SetTextColor(rgb(c)) end end

-- remove WoW color codes
local function stripCodes(s)
  if not s then return s end
  s = s:gsub("|c%x%x%x%x%x%x%x%x", "")
  s = s:gsub("|r", "")
  return s
end

-- force a FontString to our color by rewriting its text with color codes,
-- and hook future SetText/SetFormattedText calls
local function hookColor(fs, color)
  if not fs or fs.__candy_hooked then return end
  fs.__candy_hooked = true

  local function apply(self, raw)
    local clean = stripCodes(raw or self:GetText() or "")
    if clean == "" then return end
    if self.__candy_lock then return end
    self.__candy_lock = true
    self:SetText(hex(color)..clean.."|r")
    self.__candy_lock = false
  end

  hooksecurefunc(fs, "SetText", function(self, t) apply(self, t) end)
  hooksecurefunc(fs, "SetFormattedText", function(self, fmt, ...)
    apply(self, string.format(fmt or "", ...))
  end)

  apply(fs)
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
}

local function RecolorYellowFontsList()
  for _, name in ipairs(YellowFontTargets) do
    local obj = _G[name]
    if obj and obj.SetTextColor then obj:SetTextColor(rgb(PINK)) end
  end

  -- World Map navbar "Home"
  if WorldMapFrame and WorldMapFrame.NavBar
     and WorldMapFrame.NavBar.home and WorldMapFrame.NavBar.home.text then
    WorldMapFrame.NavBar.home.text:SetTextColor(rgb(PINK))
  end
end

-- ===================================================================
-- 2) Override Blizzard's global color buckets + *string* color codes
-- ===================================================================

local function ApplyGlobalPalette()
  -- Mixins
  if NORMAL_FONT_COLOR      and NORMAL_FONT_COLOR.SetRGB      then NORMAL_FONT_COLOR:SetRGB(rgb(PINK)) end
  if HIGHLIGHT_FONT_COLOR   and HIGHLIGHT_FONT_COLOR.SetRGB   then HIGHLIGHT_FONT_COLOR:SetRGB(rgb(PINK)) end
  if YELLOW_FONT_COLOR      and YELLOW_FONT_COLOR.SetRGB      then YELLOW_FONT_COLOR:SetRGB(rgb(PINK)) end
  if LIGHTYELLOW_FONT_COLOR and LIGHTYELLOW_FONT_COLOR.SetRGB then LIGHTYELLOW_FONT_COLOR:SetRGB(rgb(PINK)) end
  if GOLD_FONT_COLOR        and GOLD_FONT_COLOR.SetRGB        then GOLD_FONT_COLOR:SetRGB(rgb(PINK)) end

  -- String constants many frames embed directly
  _G.FONT_COLOR_CODE_CLOSE         = "|r"
  _G.YELLOW_FONT_COLOR_CODE        = hex(PINK)
  _G.LIGHTYELLOW_FONT_COLOR_CODE   = hex(PINK)
  _G.HIGHLIGHT_FONT_COLOR_CODE     = hex(PINK)
  _G.NORMAL_FONT_COLOR_CODE        = _G.NORMAL_FONT_COLOR_CODE or "|cFFFFFFFF" -- leave white alone

  RecolorYellowFontsList()

  -- Objective Tracker palette
  if OBJECTIVE_TRACKER_COLOR then
    local function setC(key, col)
      local c = OBJECTIVE_TRACKER_COLOR[key]
      if c then
        if c.SetRGB then c:SetRGB(col.r, col.g, col.b) end
        c.r, c.g, c.b = col.r, col.g, col.b
      end
    end
    for _, key in ipairs({ "Normal","Objective","TimeLeft","Failed" }) do setC(key, PINK) end
    for _, key in ipairs({ "Header","Complete" }) do setC(key, PURPLE) end
  end
end

-- ===================================================================
-- 3) Objective Tracker repaint + header/title enforcement
-- ===================================================================

local function ScanHeaderRegions(headerFrame)
  if not headerFrame or not headerFrame.GetRegions then return end
  for _, region in ipairs({ headerFrame:GetRegions() }) do
    if region and region.GetObjectType and region:GetObjectType() == "FontString" then
      hookColor(region, PURPLE)
    end
  end
end

-- very top bar ("All Objectives")
local function PaintTrackerTopBar()
  local m = ObjectiveTrackerFrame and ObjectiveTrackerFrame.HeaderMenu
  if not m then return end
  local candidates = { m.Title, m.TitleText, m.Text, m.Label }
  for _, obj in ipairs(candidates) do
    if obj and obj.GetObjectType and obj:GetObjectType() == "FontString" then
      hookColor(obj, PURPLE)
    end
  end
  ScanHeaderRegions(m) -- catch unnamed clones
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

  -- Top title
  PaintTrackerTopBar()

  -- Module headers (Quests / Campaign / etc.) – strip & rewrite to kill baked yellow
  for _, module in pairs(frame.MODULES or {}) do
    if module and module.Header then
      if module.Header.Text then hookColor(module.Header.Text, PURPLE) end
      ScanHeaderRegions(module.Header) -- SUI/Blizz sometimes use extra fontstrings here
    end
  end

  -- Lines inside each block
  local blocksFrame = ObjectiveTrackerBlocksFrame or (frame and frame.BlocksFrame)
  if not blocksFrame or not blocksFrame.usedBlocks then return end

  for _, block in pairs(blocksFrame.usedBlocks) do
    if block.HeaderText then hookColor(block.HeaderText, PURPLE) end
    if block.lines then
      for _, line in pairs(block.lines) do
        if line.Text     then paint(line.Text,     PINK) end
        if line.Dash     then paint(line.Dash,     PINK) end
        if line.leftText then paint(line.leftText, PINK) end
        if line.rightText then paint(line.rightText, PINK) end
      end
    end
  end
end

local function HookTracker()
  if not ObjectiveTrackerFrame then return end

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
  C_Timer.After(0.05, RepaintObjectiveTracker)
  C_Timer.After(0.25, RepaintObjectiveTracker)
end

-- ===================================================================
-- 4) Chat "attention" channels that default to yellow -> pink
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
-- 5) Slash commands
-- ===================================================================

SLASH_SUIFONT1, SLASH_SUIFONT2 = "/suifont", "/candypink"
SlashCmdList.SUIFONT = function(msg)
  msg = (msg or ""):lower()
  if msg == "debug" then
    local r,g,b = 0,0,0
    if NORMAL_FONT_COLOR and NORMAL_FONT_COLOR.GetRGB then r,g,b = NORMAL_FONT_COLOR:GetRGB() end
    print("|cffF48CBA[SUI Font Override]|r NORMAL_FONT_COLOR:", r, g, b)
    print("ObjectiveTrackerFrame exists:", ObjectiveTrackerFrame ~= nil)
  else
    ApplyGlobalPalette()
    PinkifyChat()
    HookTracker()
    RepaintObjectiveTracker()
    print("|cffF48CBA[SUI Font Override]|r refresh complete.")
  end
end

-- ===================================================================
-- 6) Event bootstrap
-- ===================================================================

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, event, arg1)
  if event == "PLAYER_LOGIN" then
    ApplyGlobalPalette()
    PinkifyChat()
    HookTracker()
    C_Timer.After(0.1, RepaintObjectiveTracker)
  elseif event == "ADDON_LOADED" then
    if arg1 == "Blizzard_ObjectiveTracker" or
       arg1 == "Blizzard_AchievementUI"   or
       arg1 == "Blizzard_WorldMap"        or
       arg1 == "SUI" then
      C_Timer.After(0.1, function()
        ApplyGlobalPalette()
        RecolorYellowFontsList()
        HookHeaderMenu()
        RepaintObjectiveTracker()
      end)
    end
  end
end)
