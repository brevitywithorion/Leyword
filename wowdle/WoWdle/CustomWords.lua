-- Add words here, then /reload.
-- Five letters. One word per line, inside the quotes.
--
-- answers: if you add any, the daily puzzle cycles through only these words.
-- Everyone in the guild needs the same answers or you will not share a word.
-- guesses: extra words that count as a guess and are never the puzzle.
-- Leave answers empty to keep the shared puzzle.

WoWdle = WoWdle or {}
WoWdle.Answers = WoWdle.Answers or {}
WoWdle.GuessSet = WoWdle.GuessSet or {}

local answers = {
  -- "glyph",
}

local guesses = {
  -- "blarg",
}

local function Clean(word)
  if type(word) ~= "string" then
    return nil
  end
  word = string.lower(word):gsub("[^a-z]", "")
  if #word ~= 5 then
    return nil
  end
  return word
end

local custom = {}
local seen = {}
for i = 1, #answers do
  local word = Clean(answers[i])
  if word and not seen[word] then
    seen[word] = true
    custom[#custom + 1] = word
    WoWdle.GuessSet[word] = true
  end
end

if #custom > 0 then
  WoWdle.Answers = custom
end

for i = 1, #guesses do
  local word = Clean(guesses[i])
  if word then
    WoWdle.GuessSet[word] = true
  end
end
