-- SUI Font Override (Pink / Night-Elf Purple)
-- Candy + Nova — v1.5

local PINK   = { r = 1.00, g = 0.42, b = 0.88 }   -- WA pink (for "yellow" text when needed)
local PURPLE = { r = 0.45, g = 0.28, b = 0.65 }   -- Night Elf purple (headers)

local function rgb(c) return c.r, c.g, c.b end
local function hex(c) return ("|cFF%02X%02X%02X"):format(
  math.floor(c.r*255+0.5), math.floor(c.g*255+0.5), math.floor(c.b*255+0.5)
) end

-- --- utils ---
local function stripCodes(s) if not s then return s end s=s:gsub("|c%x%x%x%x%x%x%x%x",""); s=s:gsub("|r",""); return s end
local function paint(fs, c) if fs and fs.SetTextColor then fs:SetTextColor(rgb(c)) end end

-- Hook a FontString so any future SetText/SetFormattedText keeps our color
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

-- Tint header background/shine/glow textures purple (those gold bars)
local function tintHeaderTextures(h)
  if not h then return end
  local function tint(tex, a)
    if tex and tex.SetVertexColor then
      if tex.SetDesaturated then pcall(tex.SetDesaturated, tex, true) end
      tex:SetVertexColor(PURPLE.r, PURPLE.g, PURPLE.b, a or tex:GetAlpha() or 1)
    end
  end
  tint(h.Background)
  tint(h.Shine, 0.85)
  tint(h.Glow,  0.85)
  if h.NineSlice and h.NineSlice.GetRegions then
    for _, r in ipairs({ h.NineSlice:GetRegions() }) do
      if r and r.SetVertexColor then r:SetVertexColor(PURPLE.r, PURPLE.g, PURPLE.b) end
    end
  end
end

-- Deep-scan a header for any FontStrings + tint textures
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

-- ===== GLOBAL PALETTE (keep white white; make "yellow buckets" pink) =====
local function ApplyGlobalPalette()
  if NORMAL_FONT_COLOR      and NORMAL_FONT_COLOR.SetRGB      then NORMAL_FONT_COLOR:SetRGB(rgb(PINK)) end
  if HIGHLIGHT_FONT_COLOR   and HIGHLIGHT_FONT_COLOR.SetRGB   then HIGHLIGHT_FONT_COLOR:SetRGB(rgb(PINK)) end
  if YELLOW_FONT_COLOR      and YELLOW_FONT_COLOR.SetRGB      then YELLOW_FONT_COLOR:SetRGB(rgb(PINK)) end
  if LIGHTYELLOW_FONT_COLOR and LIGHTYELLOW_FONT_COLOR.SetRGB then LIGHTYELLOW_FONT_COLOR:SetRGB(rgb(PINK)) end
  if GOLD_FONT_COLOR        and GOLD_FONT_COLOR.SetRGB        then GOLD_FONT_COLOR:SetRGB(rgb(PINK)) end

  -- also override inline color codes some UI strings embed
  _G.FONT_COLOR_CODE_CLOSE       = "|r"
  _G.YELLOW_FONT_COLOR_CODE      = hex(PINK)
  _G.LIGHTYELLOW_FONT_COLOR_CODE = hex(PINK)
  _G.HIGHLIGHT_FONT_COLOR_CODE   = hex(PINK)

  -- we purposely DO NOT recolor GameFontWhite etc. — white stays white
end

-- Explicitly target the module headers you showed in FrameStack
local function PaintAllModuleHeaders()
  local list = {
    ObjectiveTrackerFrame and ObjectiveTrackerFrame.Header,  -- "All Objectives" (top)
    _G.QuestObjectiveTracker and _G.QuestObjectiveTracker.Header,            -- "Quests"
    _G.CampaignQuestObjectiveTracker and _G.CampaignQuestObjectiveTracker.Header, -- "Campaign"
    _G.WorldQuestObjectiveTracker and _G.WorldQuestObjectiveTracker.Header,
    _G.ScenarioObjectiveTracker and _G.ScenarioObjectiveTracker.Header,
    _G.AchievementObjectiveTracker and _G.AchievementObjectiveTracker.Header,
  }
  for _, h in ipairs(list) do enforceHeader(h) end
end

-- Repaint objective lines only if they’re using the tracker “yellow”; keep white alone
local function RepaintLines()
  local frame = ObjectiveTrackerFrame
  if not frame then return end
  local blocks = ObjectiveTrackerBlocksFrame or (frame and frame.BlocksFrame)
  if not blocks or not blocks.usedBlocks then return end

  for _, block in pairs(blocks.usedBlocks) do
    -- quest name (header inside the block) → purple
    if block.HeaderText then hookColor(block.HeaderText, PURPLE) end
    -- objective lines: only nudge if they’re using the tracker’s yellow-ish color
    if block.lines then
      for _, line in pairs(block.lines) do
        local fs = line.Text or line.leftText or line.rightText
        if fs and fs.GetTextColor then
          local r,g,b = fs:GetTextColor()
          -- heuristic: if it's gold-ish, make it pink; otherwise leave (white stays white)
          if r and g and b and r > 0.8 and g > 0.6 and b < 0.3 then
            paint(fs, PINK)
          end
        end
        if line.Dash then paint(line.Dash, PINK) end
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
    _G.QUEST_TRACKER_MODULE,
    _G.CAMPAIGN_QUEST_TRACKER_MODULE,
    _G.WORLD_QUEST_TRACKER_MODULE,
    _G.SCENARIO_TRACKER_MODULE,
    _G.ACHIEVEMENT_TRACKER_MODULE,
  }) do if m and m.Update then hooksecurefunc(m, "Update", RepaintObjectiveTracker) end end

  -- do a couple delayed passes (skins recolor a frame later)
  C_Timer.After(0.05, RepaintObjectiveTracker)
  C_Timer.After(0.25, RepaintObjectiveTracker)
end

-- Chat “attention” channels → pink (white chat unaffected)
local function PinkifyChat()
  if not ChatTypeInfo then return end
  for _, t in ipairs({
    "SYSTEM","EMOTE","TEXT_EMOTE","ACHIEVEMENT","GUILD_ACHIEVEMENT",
    "RAID_WARNING","RAID_BOSS_EMOTE","RAID_BOSS_WHISPER"
  }) do local info=ChatTypeInfo[t]; if info then info.r,info.g,info.b = rgb(PINK) end end
end

-- Slash
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

-- Boot
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
