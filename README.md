# Leyword

A daily five-letter puzzle for WoW Forever, plus the web preview. Free to use and fork. Not a commercial product. If you already installed the old WoWdle folder, delete it and use `Leyword` instead. Saved games do not carry over.

Guildmates who have the addon see your score and the colored grid. The words you guessed are never sent.

## Install the addon

1. Close the game.
2. Copy [leyword/Leyword](leyword/Leyword) to `Interface\AddOns\Leyword`. On the Forever beta client that is `World of Warcraft\_classic_beta_\Interface\AddOns\Leyword`. The folder name has to match the toc name.
3. Log in and type `/leyword` or `/lw`.

Commands, custom words, sharing a win, and reskin notes are in [leyword/Leyword/README.md](leyword/Leyword/README.md).

## Preview

```
npm install
npm run dev
```

## Word lists

`leyword/extra-words.txt` is the guess dictionary. `leyword/build-words.mjs` regenerates `leyword/Leyword/Words.lua` and `src/lib/words.ts`. Players can also add words in `CustomWords.lua` without rebuilding.
