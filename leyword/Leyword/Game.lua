Leyword = Leyword or {}

local EPOCH_Y, EPOCH_M, EPOCH_D = 2026, 1, 1

function Leyword.Rdn(y, m, d)
  local a = math.floor((14 - m) / 12)
  local yy = y + 4800 - a
  local mm = m + 12 * a - 3
  return d
    + math.floor((153 * mm + 2) / 5)
    + 365 * yy
    + math.floor(yy / 4)
    - math.floor(yy / 100)
    + math.floor(yy / 400)
    - 32045
end

function Leyword.DateKey(y, m, d)
  return string.format("%04d%02d%02d", y, m, d)
end

function Leyword.PuzzleNumber(y, m, d)
  return Leyword.Rdn(y, m, d) - Leyword.Rdn(EPOCH_Y, EPOCH_M, EPOCH_D) + 1
end

function Leyword.AnswerFor(y, m, d)
  local list = Leyword.Answers
  local n = #list
  local number = Leyword.PuzzleNumber(y, m, d)
  local index = (number - 1) % n
  if index < 0 then
    index = index + n
  end
  return list[index + 1], number
end

function Leyword.Today()
  local t = C_DateAndTime.GetCurrentCalendarTime()
  return t.year, t.month, t.monthDay or t.day
end

function Leyword.ParseKey(key)
  local y, m, d = tostring(key or ""):match("^(%d%d%d%d)(%d%d)(%d%d)$")
  if not y then
    return nil
  end
  return tonumber(y), tonumber(m), tonumber(d)
end

function Leyword.Score(answer, guess)
  local marks = { "B", "B", "B", "B", "B" }
  local left = {}
  for i = 1, 5 do
    local g = guess:sub(i, i)
    local a = answer:sub(i, i)
    if g == a then
      marks[i] = "G"
    else
      left[a] = (left[a] or 0) + 1
    end
  end
  for i = 1, 5 do
    if marks[i] ~= "G" then
      local g = guess:sub(i, i)
      if (left[g] or 0) > 0 then
        marks[i] = "Y"
        left[g] = left[g] - 1
      end
    end
  end
  return table.concat(marks)
end

function Leyword.HardViolation(guesses, states, guess)
  local green = {}
  local minCount = {}
  for i = 1, #guesses do
    local previous = guesses[i]
    local state = states[i]
    local seen = {}
    for p = 1, 5 do
      local ch = previous:sub(p, p)
      local mark = state:sub(p, p)
      if mark == "G" then
        green[p] = ch
      end
      if mark == "G" or mark == "Y" then
        seen[ch] = (seen[ch] or 0) + 1
      end
    end
    for ch, n in pairs(seen) do
      if n > (minCount[ch] or 0) then
        minCount[ch] = n
      end
    end
  end
  for p = 1, 5 do
    if green[p] and guess:sub(p, p) ~= green[p] then
      return "Hard mode: use the revealed hints."
    end
  end
  local counts = {}
  for p = 1, 5 do
    local ch = guess:sub(p, p)
    counts[ch] = (counts[ch] or 0) + 1
  end
  for ch, n in pairs(minCount) do
    if (counts[ch] or 0) < n then
      return "Hard mode: use the revealed hints."
    end
  end
  return nil
end

function Leyword.Round()
  local daily = Leyword.EnsureToday()
  local extra = LeywordDB.extra
  if type(extra) == "table" and extra.date == daily.date then
    return extra
  end
  if type(extra) == "table" then
    LeywordDB.extra = nil
  end
  return daily
end

function Leyword.StartExtra()
  local daily = Leyword.EnsureToday()
  local showing = Leyword.Round()
  if showing.done == "play" then
    return
  end
  local list = Leyword.Answers
  if type(list) ~= "table" or #list < 1 then
    return
  end
  local todayAnswer = Leyword.AnswerFor(daily.y, daily.m, daily.d)
  if LeywordDB.usedDate ~= daily.date or type(LeywordDB.used) ~= "table" then
    LeywordDB.used = {}
    LeywordDB.usedDate = daily.date
  end
  LeywordDB.used[todayAnswer] = true
  if showing.answer then
    LeywordDB.used[showing.answer] = true
  end
  local pick
  for _ = 1, 50 do
    local word = list[math.random(#list)]
    if not LeywordDB.used[word] then
      pick = word
      break
    end
  end
  if not pick then
    LeywordDB.used = { [todayAnswer] = true }
    pick = list[math.random(#list)]
    if pick == todayAnswer and #list > 1 then
      pick = list[(math.random(#list - 1) % #list) + 1]
    end
  end
  LeywordDB.used[pick] = true
  LeywordDB.extra = {
    date = daily.date,
    y = daily.y,
    m = daily.m,
    d = daily.d,
    answer = pick,
    guesses = {},
    states = {},
    done = "play",
    recorded = true,
    shared = true,
    extra = true,
    character = nil,
  }
  Leyword.draft = ""
end

function Leyword.EnsureToday()
  local y, m, d = Leyword.Today()
  local key = Leyword.DateKey(y, m, d)
  local cur = LeywordDB.current
  if type(cur) ~= "table" or cur.date ~= key then
    cur = {
      date = key,
      y = y,
      m = m,
      d = d,
      guesses = {},
      states = {},
      done = "play",
      recorded = false,
      shared = false,
      character = nil,
    }
    LeywordDB.current = cur
  end
  return cur
end

local function CharacterName()
  local name, realm = UnitFullName("player")
  if not realm or realm == "" then
    realm = GetRealmName()
  end
  return (name or "Unknown") .. "-" .. (realm or "")
end

function Leyword.RecordFinish(cur)
  if cur.recorded then
    return
  end
  cur.recorded = true
  local stats = LeywordDB.stats
  stats.played = (stats.played or 0) + 1
  if cur.done == "win" then
    stats.wins = (stats.wins or 0) + 1
    local n = #cur.guesses
    stats.dist[n] = (stats.dist[n] or 0) + 1
    if stats.lastDate and Leyword.Rdn(cur.y, cur.m, cur.d) - (function()
      local py, pm, pd = Leyword.ParseKey(stats.lastDate)
      if not py then
        return Leyword.Rdn(cur.y, cur.m, cur.d)
      end
      return Leyword.Rdn(py, pm, pd)
    end)() == 1 then
      stats.streak = (stats.streak or 0) + 1
    else
      stats.streak = 1
    end
    if (stats.streak or 0) > (stats.maxStreak or 0) then
      stats.maxStreak = stats.streak
    end
  else
    stats.streak = 0
  end
  stats.lastDate = cur.date
end

function Leyword.SubmitGuess(raw)
  local cur = Leyword.Round()
  if cur.done ~= "play" then
    return "Already finished."
  end
  local text = string.lower(raw or ""):gsub("[^a-z]", "")
  if #text ~= 5 then
    return "Enter five letters."
  end
  if not Leyword.GuessSet[text] then
    return "Not in the word list."
  end
  for i = 1, #cur.guesses do
    if cur.guesses[i] == text then
      return "Already tried."
    end
  end
  local answer = cur.answer or Leyword.AnswerFor(cur.y, cur.m, cur.d)
  local marks = Leyword.Score(answer, text)
  cur.guesses[#cur.guesses + 1] = text
  cur.states[#cur.states + 1] = marks
  if text == answer then
    cur.done = "win"
  elseif #cur.guesses >= 6 then
    cur.done = "loss"
  end
  if cur.done ~= "play" and not cur.extra then
    cur.character = CharacterName()
    Leyword.RecordFinish(cur)
    if Leyword.BroadcastResult then
      Leyword.BroadcastResult()
    end
  end
  return nil
end

function Leyword.SelfTest()
  local fails = {}
  local function eq(name, got, expect)
    if got ~= expect then
      fails[#fails + 1] = name .. " got " .. tostring(got)
    end
  end
  eq("crane", Leyword.Score("crane", "crane"), "GGGGG")
  eq("trace", Leyword.Score("crane", "trace"), "BGGYG")
  eq("llama", Leyword.Score("allot", "llama"), "YGYBB")
  eq("boost", Leyword.Score("books", "boost"), "GGGYB")
  eq("babes", Leyword.Score("abbey", "babes"), "YYGGB")
  eq("epoch", Leyword.PuzzleNumber(2026, 1, 1), 1)
  eq("oct4", Leyword.PuzzleNumber(2026, 10, 4), 277)
  if Leyword.HardViolation({ "slate" }, { "BBGBG" }, "apple") == nil then
    fails[#fails + 1] = "hard mode allowed apple"
  end
  if Leyword.HardViolation({ "slate" }, { "BBGBG" }, "crane") ~= nil then
    fails[#fails + 1] = "hard mode blocked crane"
  end
  if #fails == 0 then
    print("|cffd4a85aLeyword|r checks passed")
  else
    print("|cffff4040Leyword|r " .. table.concat(fails, "; "))
  end
end
