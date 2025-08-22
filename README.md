# SUIFontOverride
extension addon for SUI (WoW Addon)

Add into your addons folder /reload and it should change the colour of the font. 

All the color magic is centralized at the top of the LUA file:

```
local PINK   = { r = 1.00, g = 0.42, b = 0.88 }  -- accents, titles, POI rings, “!” etc.
local PURPLE = { r = 0.45, g = 0.28, b = 0.65 }  -- headers (module & game menu)
local WHITE  = { r = 1.00, g = 1.00, b = 1.00 }  -- info/body text in tracker
```

If you ever want a different vibe, just change those r/g/b values (they’re 0–1 floats). Then /suifont or /reload and everything that references that swatch will update: tracker titles/accents (PINK), headers (PURPLE), and objective text (WHITE). Chat highlight colors and the pinkified atlases (POI icons, rings, etc.) also follow PINK.

Quick hex → RGB cheats:
```
Take each hex pair and divide by 255.
Example: #C4A1FF → r=196/255≈0.7686, g=161/255≈0.6314, b=255/255=1.0

Hot pink #FF5DBB → r=1.0, g=93/255≈0.3647, b=187/255≈0.7333
```
Bonus tiny knobs (optional, not color but “glow-y-ness”):

`In the atlas hook I set highlight/shine alphas to 0.9 / 0.85. Nudge those up/down if you want the glows louder/softer.`

That’s it—edit the swatches, refresh, and werk. 💖
