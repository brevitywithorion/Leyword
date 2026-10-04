# WoWdle

One five-letter puzzle per realm day for WoW Forever. Guildmates who have the addon see your score and the colored grid. The words you guessed are never sent.

## Install

1. Close the game.
2. Unzip so the folder is `Interface\AddOns\WoWdle`. On the Forever beta client that is `World of Warcraft\_classic_beta_\Interface\AddOns\WoWdle`. The folder name has to match the toc name.
3. Start the game and enable WoWdle if it is unchecked.
4. Type `/wowdle` or `/wd`, or open it from the minimap addon compartment.

## Commands

- `/wowdle` opens or closes the window
- `/wowdle skin` matches ElvUI and Tukui after a reload (this is the default)
- `/wowdle noskin` keeps the Blizzard frame after a reload
- `/wowdle test` runs the puzzle checks

After a win, Share posts the score and colored grid to Say, Party, Yell, Raid, Guild, or a whisper at your target. The last line tells anyone without the addon to install it. The word itself is never sent.

## Extra words

Edit `CustomWords.lua` in the addon folder, then `/reload`.

- `answers`: if you add any, the daily puzzle uses only those words. The whole guild needs the same list.
- `guesses`: accepted as guesses, never the puzzle. Leave `answers` empty to keep the shared puzzle.

A plain text list works in the preview too: one word per line. Put `guesses` on its own line before words that should never be the answer.

## Reskin

EllesmereUI skins the window through its own skinning API when that addon is installed. The letter tiles and keyboard keep the puzzle colors. ElvUI and Tukui are matched unless you run `/wowdle noskin`.

Other UI addons can reskin WoWdle without editing it. Frames use Blizzard templates only.

```lua
WoWdle.RegisterSkin(function(frames)
  -- frames.main, guessBox, submit, share, back, puzzleTab, guildTab,
  -- hardMode, colorblind, guildScroll, tiles[row][col], keys[letter]
end)
```

Or:

```lua
EventRegistry:RegisterCallback("WoWdle.Skin", function(_, frames) end)
WoWdle.GetFrames()
```

Named frames: `WoWdleFrame`, `WoWdleGuessBox`, `WoWdleSubmitButton`, `WoWdleShareButton`, `WoWdleBackButton`, `WoWdleGuildScroll`, `WoWdleHardModeCheck`, `WoWdleColorblindCheck`, and `WoWdleTile_1_1` through `WoWdleTile_6_5`.

Replace `WoWdle.ApplyTile(tile, letter, mark)` to paint tiles. `mark` is nil, `"G"`, `"Y"`, or `"B"`.
