-- SUI Font Override (Pink / Night-Elf Purple) — v1.7 (merged)
-- Candy + Nova

------------------------------------------------------------
-- Palette
------------------------------------------------------------
local PINK   = { r = 1.00, g = 0.42, b = 0.88 }   -- WA pink (use for "yellow" text)
local PURPLE = { r = 0.45, g = 0.28, b = 0.65 }   -- Night Elf purple (headers/bars)

local function rgb(c) return c.r, c.g, c.b end
local function hex(c) return ("|cFF%02X%02X%02X"):format(
  math.floor(c.r*255+0.5), math.floor(c.g*255+0.5), math.floor(c.b*255+0.5)
) end

------------------------------------------------------------
-- Utilities
------------------------------------------------------------
local function stripColorCodes(s)
  if not s then return s end
  s = s:gsub("|c%x%x%x%x%x%x%x%x","")
  s = s:gsub("|r","")
  return s
end

-- keep any FontString locked to our color (snippet 1 core)
local function hookColor(fs, color)
  if not fs or fs.__candy_hooked then return end
  fs.__candy_hooked = true
  local function apply(self, raw)
    local clean = stripColorCodes(raw or self:GetText() or "")
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

local function paint(fs, color)
  if fs and fs.SetTextColor then fs:SetTextColor(rgb(color)) end
end

------------------------------------------------------------
-- 1) Global yellow buckets -> PINK (and common font objects)
------------------------------------------------------------
local YellowFontTargets = {
  "AchievementDateFont","AchievementPointsFont","AchievementPointsFontSmall",
  "BossEmoteNormalHuge","DialogButtonNormalText","FocusFontSmall",
  "GameFontNormal","GameFontNormalHuge","GameFontNormalLarge","GameFontNormalMed3","GameFontNormalSmall",
  "GameFont_Gigantic","GameFontNormalHuge2",
  "NumberFontNormalLargeRightYellow","NumberFontNormalLargeYellow",
  "NumberFontNormalRightYellow","NumberFontNormalYellow",
  "QuestFont_Enormous","QuestFont_Super_Huge","QuestFont_Super_Huge_Outline",
  "QuestTitleFontBlackShadow","SplashHeaderFont",
  -- tracker/log leaning yellow:
  "GameFontHighlight","GameFontHighlightSmall","ObjectiveFont",
  "QuestFont_Normal","QuestFont_Highlight",
  -- extra UI fonts that often show yellow:
  "GameFontNormalOutline","GameFontHighlightOutline",
  "QuestFont_Large","QuestFont_Huge","QuestFont_Shadow_Huge",
  "MailFont_Large","SystemFont_Med1","SystemFont_Med2","SystemFont_Med3",
  "SystemFont_Large","SystemFont_Huge1",
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

local function ApplyGlobalPalette()
  -- Color mixins used everywhere
  if NORMAL_FONT_COLOR      and NORMAL_FONT_COLOR.SetRGB      then NORMAL_FONT_COLOR:SetRGB(rgb(PINK)) end
  if HIGHLIGHT_FONT_COLOR   and HIGHLIGHT_FONT_COLOR.SetRGB   then HIGHLIGHT_FONT_COLOR:SetRGB(rgb(PINK)) end
  if YELLOW_FONT_COLOR      and YELLOW_FONT_COLOR.SetRGB      then YELLOW_FONT_COLOR:SetRGB(rgb(PINK)) end
  if LIGHTYELLOW_FONT_COLOR and LIGHTYELLOW_FONT_COLOR.SetRGB then LIGHTYELLOW_FONT_COLOR:SetRGB(rgb(PINK)) end
  if GOLD_FONT_COLOR        and GOLD_FONT_COLOR.SetRGB        then GOLD_FONT_COLOR:SetRGB(rgb(PINK)) end

  -- Inline string color codes (so baked |cffFFD100 etc. pull pink)
  _G.FONT_COLOR_CODE_CLOSE       = "|r"
  _G.YELLOW_FONT_COLOR_CODE      = hex(PINK)
  _G.LIGHTYELLOW_FONT_COLOR_CODE = hex(PINK)
  _G.HIGHLIGHT_FONT_COLOR_CODE   = hex(PINK)

  -- Objective Tracker color table
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

  RecolorYellowFontsList()
end

------------------------------------------------------------
-- 2) Headers: text locked PURPLE + texture bars tinted PURPLE (snippet 1)
------------------------------------------------------------
local function tintHeaderTextures(h)
  if not h then return end
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

local function enforceHeader(h)
  if not h then return end
  if h.Text then hookColor(h.Text, PURPLE) end
  if h.GetRegions then
    for _, r in ipairs({ h:GetRegions() }) do
      if r and r.GetObjectType and r:GetObjectType()=="FontString" then hookColor(r, PURPLE) end
    end
  end
  tintHeaderTextures(h)
end

local function PaintTrackerTopBar()
  local m = ObjectiveTrackerFrame and ObjectiveTrackerFrame.HeaderMenu
  if not m then return end
  for _, obj in ipairs({ m.Title, m.TitleText, m.Text, m.Label }) do
    if obj and obj.GetObjectType and obj:GetObjectType()=="FontString" then hookColor(obj, PURPLE) end
  end
  if m.GetRegions then
    for _, r in ipairs({ m:GetRegions() }) do
      if r and r.GetObjectType and r:GetObjectType()=="FontString" then hookColor(r, PURPLE) end
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
  PaintTrackerTopBar()
end

------------------------------------------------------------
-- 3) Tracker: objective lines to PINK, keep headers PURPLE
------------------------------------------------------------
local function RepaintLines()
  local frame = ObjectiveTrackerFrame
  if not frame then return end
  local blocks = ObjectiveTrackerBlocksFrame or (frame and frame.BlocksFrame)
  if not blocks or not blocks.usedBlocks then return end

  for _, block in pairs(blocks.usedBlocks) do
    if block.HeaderText then hookColor(block.HeaderText, PURPLE) end
    if block.lines then
      for _, line in pairs(block.lines) do
        if line.Dash     then paint(line.Dash,     PINK) end
        if line.Text     then paint(line.Text,     PINK) end
        if line.leftText then paint(line.leftText, PINK) end
        if line.rightText then paint(line.rightText, PINK) end
      end
    end
  end
end

local function RepaintObjectiveTracker()
  PaintAllModuleHeaders()
  RepaintLines()
end

local function HookTracker()
  if not ObjectiveTrackerFrame then return end
  if ObjectiveTracker_Update then hooksecurefunc("ObjectiveTracker_Update", RepaintObjectiveTracker) end
  for _, m in ipairs({
    _G.QUEST_TRACKER_MODULE,
    _G.CAMPAIGN_QUEST_TRACKER_MODULE,
    _G.WORLD_QUEST_TRACKER_MODULE,
    _G.SCENARIO_TRACKER_MODULE,
    _G.ACHIEVEMENT_TRACKER_MODULE,
  }) do if m and m.Update then hooksecurefunc(m, "Update", RepaintObjectiveTracker) end end
  HookHeaderMenu()
  C_Timer.After(0.05, RepaintObjectiveTracker)
  C_Timer.After(0.25, RepaintObjectiveTracker)
end

-- Progress/quest events to repaint promptly
local function HookQuestProgressUpdates()
  if QuestMapFrame_UpdateAll then
    hooksecurefunc("QuestMapFrame_UpdateAll", function() C_Timer.After(0.05, RepaintObjectiveTracker) end)
  end
  if QuestWatch_Update then
    hooksecurefunc("QuestWatch_Update", function() C_Timer.After(0.05, RepaintObjectiveTracker) end)
  end
  if ObjectiveTracker_Update then
    hooksecurefunc("ObjectiveTracker_Update", function() C_Timer.After(0.05, RepaintObjectiveTracker) end)
  end
end

local function HookQuestEvents()
  local f = CreateFrame("Frame")
  f:RegisterEvent("QUEST_LOG_UPDATE")
  f:RegisterEvent("QUEST_WATCH_UPDATE")
  f:RegisterEvent("QUEST_PROGRESS")
  f:RegisterEvent("UI_INFO_MESSAGE")
  f:RegisterEvent("QUEST_COMPLETE")
  f:SetScript("OnEvent", function() C_Timer.After(0.1, RepaintObjectiveTracker) end)
end

------------------------------------------------------------
-- 4) Chat + tooltips/alerts tweaks
------------------------------------------------------------
local function PinkifyChat()
  if not ChatTypeInfo then return end
  for _, t in ipairs({
    "SYSTEM","EMOTE","TEXT_EMOTE","ACHIEVEMENT","GUILD_ACHIEVEMENT",
    "RAID_WARNING","RAID_BOSS_EMOTE","RAID_BOSS_WHISPER"
  }) do local info=ChatTypeInfo[t]; if info then info.r,info.g,info.b = rgb(PINK) end end
end

local function HookTooltipColors()
  if not GameTooltip then return end
  GameTooltip:HookScript("OnShow", function(self)
    for i=1,self:NumLines() do
      local line = _G["GameTooltipTextLeft"..i]
      if line then
        local text = line:GetText()
        if text and text:find("|cff") then
          text = text:gsub("|cffFFD700", hex(PINK))
                     :gsub("|cffFFFF00", hex(PINK))
                     :gsub("|cffFFD100", hex(PINK))
          line:SetText(text)
        end
      end
    end
  end)
end

local function HookAlertFrames()
  if AchievementAlertFrame_ShowAlert then
    hooksecurefunc("AchievementAlertFrame_ShowAlert", function()
      C_Timer.After(0.1, function()
        for i=1,MAX_ACHIEVEMENT_ALERTS or 4 do
          local frame = _G["AchievementAlertFrame"..i]
          if frame and frame:IsShown() then
            if frame.Name   then paint(frame.Name,   PINK) end
            if frame.Points then paint(frame.Points, PINK) end
          end
        end
      end)
    end)
  end
end

------------------------------------------------------------
-- 5) Slash
------------------------------------------------------------
SLASH_SUIFONT1, SLASH_SUIFONT2 = "/suifont", "/candypink"
SlashCmdList.SUIFONT = function(msg)
  msg = (msg or ""):lower()
  if msg == "debug" then
    local r,g,b = NORMAL_FONT_COLOR and NORMAL_FONT_COLOR.GetRGB and NORMAL_FONT_COLOR:GetRGB() or 0,0,0
    print("|cffF48CBA[SUI Font Override]|r NORMAL_FONT_COLOR:", r, g, b)
    print("Tracker:", ObjectiveTrackerFrame and "present" or "nil")
  else
    ApplyGlobalPalette()
    PinkifyChat()
    HookTracker()
    HookQuestProgressUpdates()
    HookQuestEvents()
    HookTooltipColors()
    HookAlertFrames()
    RepaintObjectiveTracker()
    print("|cffF48CBA[SUI Font Override]|r refresh complete.")
  end
end

------------------------------------------------------------
-- 6) Boot
------------------------------------------------------------
local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:RegisterEvent("ADDON_LOADED")
boot:SetScript("OnEvent", function(_, event, arg1)
  if event == "PLAYER_LOGIN" then
    ApplyGlobalPalette()
    PinkifyChat()
    HookTracker()
    HookQuestProgressUpdates()
    HookQuestEvents()
    HookTooltipColors()
    HookAlertFrames()
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
