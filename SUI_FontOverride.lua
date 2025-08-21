-- SUI Font Override (Pink / Night-Elf Purple) — v1.8 (headers from Lua2 + text from Lua1)
-- Candy + Nova

------------------------------------------------------------
-- CONFIG (you can tweak these)
------------------------------------------------------------
local TINT_HEADER_TEXTURES   = false  -- set to true if you want the purple header bars/shines
local PINKIFY_ONLY_YELLOWISH = false  -- false = make all objective lines pink (Lua1 behavior)
                                       -- true  = only recolor lines that look gold-ish

------------------------------------------------------------
-- Palette
------------------------------------------------------------
local PINK   = { r = 1.00, g = 0.42, b = 0.88 }   -- WA pink (for "yellow" text)
local PURPLE = { r = 0.45, g = 0.28, b = 0.65 }   -- Night Elf purple (headers)

local function rgb(c) return c.r, c.g, c.b end
local function hex(c) return ("|cFF%02X%02X%02X"):format(
  math.floor(c.r*255+0.5), math.floor(c.g*255+0.5), math.floor(c.b*255+0.5)
) end

------------------------------------------------------------
-- Utils
------------------------------------------------------------
local function stripCodes(s)
  if not s then return s end
  s = s:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
  return s
end

local function paint(fs, col) if fs and fs.SetTextColor then fs:SetTextColor(rgb(col)) end end

-- Lock a FontString to a color (Lua2 header method)
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
  hooksecurefunc(fs, "SetText", apply)
  hooksecurefunc(fs, "SetFormattedText", function(self, fmt, ...) apply(self, fmt and fmt:format(...)) end)
  apply(fs)
end

------------------------------------------------------------
-- 1) Global “yellow” buckets → PINK (keep normal white alone)
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
  "GameFontHighlight","GameFontHighlightSmall","ObjectiveFont",
  "QuestFont_Normal","QuestFont_Highlight",
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
  if WorldMapFrame and WorldMapFrame.NavBar
     and WorldMapFrame.NavBar.home and WorldMapFrame.NavBar.home.text then
    WorldMapFrame.NavBar.home.text:SetTextColor(rgb(PINK))
  end
end

local function ApplyGlobalPalette()
  -- Do NOT touch NORMAL_FONT_COLOR (white stays white)
  if HIGHLIGHT_FONT_COLOR   and HIGHLIGHT_FONT_COLOR.SetRGB   then HIGHLIGHT_FONT_COLOR:SetRGB(rgb(PINK)) end
  if YELLOW_FONT_COLOR      and YELLOW_FONT_COLOR.SetRGB      then YELLOW_FONT_COLOR:SetRGB(rgb(PINK)) end
  if LIGHTYELLOW_FONT_COLOR and LIGHTYELLOW_FONT_COLOR.SetRGB then LIGHTYELLOW_FONT_COLOR:SetRGB(rgb(PINK)) end
  if GOLD_FONT_COLOR        and GOLD_FONT_COLOR.SetRGB        then GOLD_FONT_COLOR:SetRGB(rgb(PINK)) end

  -- inline string codes
  _G.FONT_COLOR_CODE_CLOSE       = "|r"
  _G.YELLOW_FONT_COLOR_CODE      = hex(PINK)
  _G.LIGHTYELLOW_FONT_COLOR_CODE = hex(PINK)
  _G.HIGHLIGHT_FONT_COLOR_CODE   = hex(PINK)

  -- Tracker’s internal color table (logic colors)
  if OBJECTIVE_TRACKER_COLOR then
    local function setC(key, col)
      local c = OBJECTIVE_TRACKER_COLOR[key]
      if c then if c.SetRGB then c:SetRGB(col.r, col.g, col.b) end; c.r,c.g,c.b = col.r,col.g,col.b end
    end
    for _, k in ipairs({"Normal","Objective","TimeLeft","Failed"}) do setC(k, PINK) end
    for _, k in ipairs({"Header","Complete"}) do setC(k, PURPLE) end
  end

  RecolorYellowFontsList()
end

------------------------------------------------------------
-- 2) Headers (Lua2): text purple; optional texture tint
------------------------------------------------------------
local function tintHeaderTextures(h)
  if not TINT_HEADER_TEXTURES or not h then return end
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

------------------------------------------------------------
-- 3) Objective lines (Lua1): paint to pink
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
        if PINKIFY_ONLY_YELLOWISH and line.Text and line.Text.GetTextColor then
          local r,g,b = line.Text:GetTextColor()
          if r and g and b and r > 0.8 and g > 0.6 and b < 0.35 then paint(line.Text, PINK) end
        else
          if line.Text     then paint(line.Text,     PINK) end
        end
        if line.leftText  then paint(line.leftText,  PINK) end
        if line.rightText then paint(line.rightText, PINK) end
        if line.Dash      then paint(line.Dash,      PINK) end
      end
    end
  end
end

local function RepaintObjectiveTracker()
  PaintAllModuleHeaders()
  RepaintLines()
end

local function HookTracker()
  if ObjectiveTracker_Update then hooksecurefunc("ObjectiveTracker_Update", RepaintObjectiveTracker) end
  for _, m in ipairs({
    _G.QUEST_TRACKER_MODULE, _G.CAMPAIGN_QUEST_TRACKER_MODULE,
    _G.WORLD_QUEST_TRACKER_MODULE, _G.SCENARIO_TRACKER_MODULE, _G.ACHIEVEMENT_TRACKER_MODULE,
  }) do if m and m.Update then hooksecurefunc(m, "Update", RepaintObjectiveTracker) end end
  C_Timer.After(0.05, RepaintObjectiveTracker)
  C_Timer.After(0.25, RepaintObjectiveTracker)
end

-- extra quest events so recolor happens promptly
local function HookQuestEvents()
  local f = CreateFrame("Frame")
  f:RegisterEvent("QUEST_LOG_UPDATE")
  f:RegisterEvent("QUEST_WATCH_UPDATE")
  f:RegisterEvent("QUEST_PROGRESS")
  f:RegisterEvent("QUEST_COMPLETE")
  f:RegisterEvent("UI_INFO_MESSAGE")
  f:SetScript("OnEvent", function() C_Timer.After(0.1, RepaintObjectiveTracker) end)
end

------------------------------------------------------------
-- 4) Chat / tooltips (optional niceties)
------------------------------------------------------------
local function PinkifyChat()
  if not ChatTypeInfo then return end
  for _, t in ipairs({"SYSTEM","EMOTE","TEXT_EMOTE","ACHIEVEMENT","GUILD_ACHIEVEMENT","RAID_WARNING","RAID_BOSS_EMOTE","RAID_BOSS_WHISPER"}) do
    local info = ChatTypeInfo[t]; if info then info.r,info.g,info.b = rgb(PINK) end
  end
end

local function HookTooltipColors()
  if not GameTooltip then return end
  GameTooltip:HookScript("OnShow", function(self)
    for i=1,self:NumLines() do
      local line = _G["GameTooltipTextLeft"..i]
      if line then
        local tx = line:GetText()
        if tx and tx:find("|cff") then
          tx = tx:gsub("|cffFFD700", hex(PINK))  -- gold
                 :gsub("|cffFFFF00", hex(PINK))  -- yellow
                 :gsub("|cffFFD100", hex(PINK))  -- quest yellow
          line:SetText(tx)
        end
      end
    end
  end)
end

------------------------------------------------------------
-- 5) Slash
------------------------------------------------------------
SLASH_SUIFONT1, SLASH_SUIFONT2 = "/suifont", "/candypink"
SlashCmdList.SUIFONT = function(msg)
  msg = (msg or ""):lower()
  if msg == "debug" then
    local r,g,b = YELLOW_FONT_COLOR and YELLOW_FONT_COLOR.GetRGB and YELLOW_FONT_COLOR:GetRGB() or 0,0,0
    print("|cffF48CBA[SUI Font Override]|r YELLOW:", r,g,b, " Tracker:", ObjectiveTrackerFrame and "present" or "nil")
    print("Header textures tint:", TINT_HEADER_TEXTURES and "ON" or "OFF", " | Lines mode:", PINKIFY_ONLY_YELLOWISH and "yellow-only" or "all pink")
  else
    ApplyGlobalPalette()
    PinkifyChat()
    HookTracker()
    HookQuestEvents()
    HookTooltipColors()
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
    HookQuestEvents()
    HookTooltipColors()
    C_Timer.After(0.1, RepaintObjectiveTracker)
  elseif event == "ADDON_LOADED" then
    if arg1 == "Blizzard_ObjectiveTracker" or arg1 == "Blizzard_AchievementUI" or arg1 == "Blizzard_WorldMap" or arg1 == "SUI" then
      C_Timer.After(0.1, function()
        ApplyGlobalPalette()
        RecolorYellowFontsList()
        RepaintObjectiveTracker()
      end)
    end
  end
end)
