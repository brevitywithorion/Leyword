# WoWdle

A daily five-letter puzzle for WoW Forever, plus the web preview. Free to use and fork. Not a commercial product.

Guildmates who have the addon see your score and the colored grid. The words you guessed are never sent.

## Install the addon

1. Close the game.
2. Copy [wowdle/WoWdle](wowdle/WoWdle) to `Interface\AddOns\WoWdle`. On the Forever beta client that is `World of Warcraft\_classic_beta_\Interface\AddOns\WoWdle`. The folder name has to match the toc name.
3. Log in and type `/wowdle` or `/wd`.

Commands, custom words, sharing a win, and reskin notes are in [wowdle/WoWdle/README.md](wowdle/WoWdle/README.md).

## Preview

```
npm install
npm run dev
```

## Word lists

`wowdle/extra-words.txt` is the guess dictionary. `wowdle/build-words.mjs` regenerates `wowdle/WoWdle/Words.lua` and `src/lib/words.ts`. Players can also add words in `CustomWords.lua` without rebuilding.
