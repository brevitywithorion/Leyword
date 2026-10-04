-- Add words here, then /reload.
-- Five letters. One word per line, inside the quotes.
--
-- answers: if you add any, the daily puzzle cycles through only these words.
-- Everyone in the guild needs the same answers or you will not share a word.
-- guesses: extra words that count as a guess and are never the puzzle.
-- Leave answers empty to keep the shared puzzle.

Leyword = Leyword or {}
Leyword.Answers = Leyword.Answers or {}
Leyword.GuessSet = Leyword.GuessSet or {}

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
    Leyword.GuessSet[word] = true
  end
end

if #custom > 0 then
  Leyword.Answers = custom
end

for i = 1, #guesses do
  local word = Clean(guesses[i])
  if word then
    Leyword.GuessSet[word] = true
  end
end
