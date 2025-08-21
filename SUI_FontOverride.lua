-- SUI Font Override (Pink / Night-Elf Purple)
-- Candy + Nova — v1.4

local PINK   = { r = 1.00, g = 0.42, b = 0.88 }   -- WA pink
local PURPLE = { r = 0.45, g = 0.28, b = 0.65 }   -- Night Elf purple

local function rgb(c) return c.r, c.g, c.b end
local function hex(c) return ("|cFF%02X%02X%02X"):format(
  math.floor(c.r*255+0.5), math.floor(c.g*255+0.5), math.floor(c.b*255+0.5)
) end

local function paint(fs, c) if fs and fs.SetTextColor then fs:SetTextColor(rgb(c)) end end
local function stripCodes(s) if not s then return s end s=s:gsub("|c%x%x%x%x%x%x%x%x",""); s=s:gsub("|r",""); return s end

-- Hook a FontString so ANY future SetText/SetFormattedText keeps our color
local function hookColor(fs, color)
  if not fs or fs.__candy_hooked then return end
  fs.__candy_hooked = true
  local function apply(self, raw)
    local clean = stripCodes(raw or self:GetText() or "")
    if clean == "" or self.__candy_lock then return end
    self.__candy_lock = true
    self:SetText(hex(color)..clean.."|r")
    self.__candy_lock = false
  end
  hooksecurefunc(fs, "SetText", function(self, t) apply(self, t) end)
  hooksecurefunc(fs, "SetFormattedText", function(self, fmt, ...) apply(self, fmt and fmt:format(...)) end)
  apply(fs)
end

-- Tint header background/shine/glow textures purple (they’re the gold bars you saw)
local function tintHeaderTextures(h)
  if not h then return end
  local function tint(tex, a)
    if tex and tex.SetVertexColor then
      if tex.SetDesaturated then pcall(tex.SetDesaturated, tex, true) end
      tex:SetVertexColor(PURPLE.r, PURPLE.g, PURPLE.b, a or tex:GetAlpha() or 1)
    end
  end
  tint(h.Background)  -- Atlas: UI-QuestTracker-Primary/Secondary-Objective-Header
  tint(h.Shine, 0.8)
  tint(h.Glow,  0.8)
  -- some builds put bits on NineSlice
  if h.NineSlice and h.NineSlice:GetRegions() then
    for _, r in ipairs({ h.NineSlice:GetRegions() }) do
      if r and r.SetVertexColor then r:SetVertexColor(PURPLE.r, PURPLE.g, PURPLE.b) end
    end
  end
end

-- Deep-scan a header frame for ANY fontstrings and force purple
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

-- ========== GLOBAL PALETTE ==========
local function ApplyGlobalPalette()
  if NORMAL_FONT_COLOR      and NORMAL_FONT_COLOR.SetRGB      then NORMAL_FONT_COLOR:SetRGB(rgb(PINK)) end
  if HIGHLIGHT_FONT_COLOR   and HIGHLIGHT_FONT_COLOR.SetRGB   then HIGHLIGHT_FONT_COLOR:SetRGB(rgb(PINK)) end
  if YELLOW_FONT_COLOR      and YELLOW_FONT_COLOR.SetRGB      then YELLOW_FONT_COLOR:SetRGB(rgb(PINK)) end
  if LIGHTYELLOW_FONT_COLOR and LIGHTYELLOW_FONT_COLOR.SetRGB then LIGHTYELLOW_FONT_COLOR:SetRGB(rgb(PINK)) end
  if GOLD_FONT_COLOR        and GOLD_FONT_COLOR.SetRGB        then GOLD_FONT_COLOR:SetRGB(rgb(PINK)) end

  -- also override string codes many UIs embed directly
  _G.FONT_COLOR_CODE_CLOSE       = "|r"
  _G.YELLOW_FONT_COLOR_CODE      = hex(PINK)
  _G.LIGHTYELLOW_FONT_COLOR_CODE = hex(PINK)
  _G.HIGHLIGHT_FONT_COLOR_CODE   = hex(PINK)

  -- common “yellow” font objects
  for _, name in ipairs({
    "GameFontNormal","GameFontNormalLarge","GameFontNormalHuge","GameFontNormalMed3","GameFontNormalSmall","GameFont_Gigantic","GameFontNormalHuge2",
    "GameFontHighlight","GameFontHighlightSmall","ObjectiveFont","QuestFont_Normal","QuestFont_Highlight",
    "QuestFont_Enormous","QuestFont_Super_Huge","QuestFont_Super_Huge_Outline","QuestTitleFontBlackShadow",
    "NumberFontNormalYellow","NumberFontNormalRightYellow","NumberFontNormalLargeYellow","NumberFontNormalLargeRightYellow",
    "AchievementDateFont","AchievementPointsFont","AchievementPointsFontSmall","SplashHeaderFont"
  }) do local f=_G[name]; if f and f.SetTextColor then f:SetTextColor(rgb(PINK)) end end
end

-- ========== TRACKER REPAINT ==========
local function RepaintObjectiveTracker()
  local frame = ObjectiveTrackerFrame
  if not frame then return end

  -- Very top header (“All Objectives”)
  enforceHeader(frame.Header)

  -- Module headers (Quests / Campaign / Achievements / etc.)
  for _, m in pairs(frame.MODULES or {}) do
    if m and m.Header then enforceHeader(m.Header) end
  end

  -- Lines inside each quest block → pink
  local blocks = ObjectiveTrackerBlocksFrame or (frame and frame.BlocksFrame)
  if blocks and blocks.usedBlocks then
    for _, block in pairs(blocks.usedBlocks) do
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
  -- first pass + delayed passes (skins recolor one frame later)
  C_Timer.After(0.05, RepaintObjectiveTracker)
  C_Timer.After(0.25, RepaintObjectiveTracker)
end

-- ========== CHAT YELLOWS -> PINK ==========
local function PinkifyChat()
  if not ChatTypeInfo then return end
  for _, t in ipairs({
    "SYSTEM","EMOTE","TEXT_EMOTE","ACHIEVEMENT","GUILD_ACHIEVEMENT",
    "RAID_WARNING","RAID_BOSS_EMOTE","RAID_BOSS_WHISPER"
  }) do local info=ChatTypeInfo[t]; if info then info.r,info.g,info.b = rgb(PINK) end end
end

-- ========== SLASH ==========
SLASH_SUIFONT1, SLASH_SUIFONT2 = "/suifont", "/candypink"
SlashCmdList.SUIFONT = function(msg)
  msg = (msg or ""):lower()
  if msg == "debug" then
    local r,g,b = NORMAL_FONT_COLOR and NORMAL_FONT_COLOR:GetRGB() or 0,0,0
    print("|cffF48CBA[SUI Font Override]|r NORMAL_FONT_COLOR:", r,g,b)
    print("Tracker:", ObjectiveTrackerFrame and "present" or "nil")
  else
    ApplyGlobalPalette(); PinkifyChat(); HookTracker(); RepaintObjectiveTracker()
    print("|cffF48CBA[SUI Font Override]|r refresh complete.")
  end
end

-- ========== BOOT ==========
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
    if arg1 == "Blizzard_ObjectiveTracker" or arg1 == "SUI" then
      C_Timer.After(0.1, function()
        ApplyGlobalPalette()
        RepaintObjectiveTracker()
      end)
    end
  end
end)
