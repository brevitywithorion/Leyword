import { useEffect, useMemo, useState } from "react";
import {
  answerFor,
  buildLists,
  dateKey,
  emptyStats,
  isGuess,
  parseWordList,
  puzzleNumber,
  recordFinish,
  scoreGuess,
  shareChat,
  type Done,
  type Stats,
} from "@/lib/leyword";

type Save = {
  date: string;
  y: number;
  m: number;
  d: number;
  guesses: string[];
  states: string[];
  done: Done;
  recorded: boolean;
  extraAnswer?: string;
  settings: { colorblind: boolean; keyboard?: boolean };
  stats: Stats;
};

const KEYS = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"];

function blankSave(now = new Date()): Save {
  const y = now.getFullYear();
  const m = now.getMonth() + 1;
  const d = now.getDate();
  return {
    date: dateKey(y, m, d),
    y,
    m,
    d,
    guesses: [],
    states: [],
    done: "play",
    recorded: false,
    settings: { colorblind: false, keyboard: true },
    stats: emptyStats(),
  };
}

function loadSave(): Save {
  const fresh = blankSave();
  try {
    const raw = localStorage.getItem("leyword");
    if (!raw) return fresh;
    const parsed = JSON.parse(raw) as Partial<Save>;
    const stats = {
      ...emptyStats(),
      ...(parsed.stats ?? {}),
      dist: parsed.stats?.dist?.length === 6 ? parsed.stats.dist : emptyStats().dist,
    };
    const settings = parsed.settings ?? fresh.settings;
    if (parsed.date !== fresh.date) {
      return { ...fresh, stats, settings };
    }
    return {
      ...fresh,
      ...parsed,
      date: fresh.date,
      y: fresh.y,
      m: fresh.m,
      d: fresh.d,
      stats,
      settings,
      guesses: parsed.guesses ?? [],
      states: parsed.states ?? [],
      done: parsed.done ?? "play",
    };
  } catch {
    return fresh;
  }
}

export function LeywordApp() {
  const [save, setSave] = useState<Save>(() => blankSave());
  const [draft, setDraft] = useState("");
  const [message, setMessage] = useState("");
  const [tab, setTab] = useState<"puzzle" | "guild">("puzzle");
  const [ready, setReady] = useState(false);
  const [extras, setExtras] = useState<{ answers: string[]; guesses: string[] }>({ answers: [], guesses: [] });
  const [wordsReady, setWordsReady] = useState(false);
  const lists = useMemo(() => buildLists(extras.answers, extras.guesses), [extras]);

  useEffect(() => {
    setSave(loadSave());
    setReady(true);
    try {
      const raw = localStorage.getItem("leyword-words");
      if (raw) {
        const parsed = JSON.parse(raw) as { answers?: string[]; guesses?: string[] };
        setExtras({ answers: parsed.answers ?? [], guesses: parsed.guesses ?? [] });
      }
    } catch {
      setExtras({ answers: [], guesses: [] });
    }
    setWordsReady(true);
  }, []);

  useEffect(() => {
    if (ready) localStorage.setItem("leyword", JSON.stringify(save));
  }, [save, ready]);

  useEffect(() => {
    if (wordsReady) localStorage.setItem("leyword-words", JSON.stringify(extras));
  }, [extras, wordsReady]);

  const number = puzzleNumber(save.y, save.m, save.d);
  const dailyAnswer = answerFor(save.y, save.m, save.d, lists.answers);
  const answer = save.extraAnswer ?? dailyAnswer;
  const active = save.guesses.length;
  const best: Record<string, string> = {};
  const rank: Record<string, number> = { B: 1, Y: 2, G: 3 };
  save.guesses.forEach((guess, index) => {
    const state = save.states[index] ?? "";
    for (let i = 0; i < 5; i++) {
      const letter = guess[i]?.toUpperCase() ?? "";
      const mark = state[i] ?? "B";
      if (!best[letter] || rank[mark] > rank[best[letter]]) best[letter] = mark;
    }
  });

  function updateDraft(value: string | ((current: string) => string)) {
    setDraft((current) => {
      const next = typeof value === "function" ? value(current) : value;
      return next.toUpperCase().replace(/[^A-Z]/g, "").slice(0, 5);
    });
    setMessage("");
  }

  function submit(text = draft) {
    if (!save || save.done !== "play") return;
    const guess = text.toLowerCase();
    if (guess.length !== 5) {
      setMessage("Enter five letters.");
      return;
    }
    if (!isGuess(guess, lists.valid)) {
      setMessage("Not in the word list.");
      return;
    }
    if (save.guesses.includes(guess)) {
      setMessage("Already tried.");
      return;
    }
    const state = scoreGuess(answer, guess);
    const guesses = [...save.guesses, guess];
    const states = [...save.states, state];
    const won = guess === answer;
    const done: Done = won ? "win" : guesses.length >= 6 ? "loss" : "play";
    let stats = save.stats;
    let recorded = save.recorded;
    if (done !== "play" && !recorded && !save.extraAnswer) {
      stats = recordFinish(stats, save.y, save.m, save.d, won, guesses.length);
      recorded = true;
    }
    setSave({
      ...save,
      guesses,
      states,
      done,
      recorded,
      stats,
    });
    setDraft("");
    setMessage("");
  }

  const played = save.stats.played;
  const rate = played > 0 ? Math.round((save.stats.wins / played) * 100) : 0;
  const maxDist = Math.max(1, ...save.stats.dist);

  return (
    <main className="stage">
      <section className="panel" data-colorblind={save.settings.colorblind ? "true" : "false"} aria-label="Leyword">
        <h1 className="title">Leyword</h1>
        <p className="number" suppressHydrationWarning>{save.extraAnswer ? "Extra" : `No. ${number}`}</p>
        <div className="tabs" role="tablist">
          <button className="tab" type="button" role="tab" aria-selected={tab === "puzzle"} onClick={() => setTab("puzzle")}>
            Puzzle
          </button>
          <button className="tab" type="button" role="tab" aria-selected={tab === "guild"} onClick={() => setTab("guild")}>
            Guild
          </button>
        </div>

        {tab === "puzzle" ? (
          <div>
            <div className="board">
              {Array.from({ length: 6 }, (_, row) => {
                const guess = save.guesses[row];
                const state = save.states[row];
                const fresh = row === save.guesses.length - 1 && save.guesses.length > 0;
                return (
                  <div className="row" key={row}>
                    {Array.from({ length: 5 }, (_, col) => {
                      const letter = guess ? guess[col] : row === active ? draft[col] : "";
                      const mark = state?.[col] ?? "";
                      return (
                        <div className="tile" key={col} data-mark={mark} data-fresh={fresh && mark ? "true" : "false"}>
                          {letter}
                        </div>
                      );
                    })}
                  </div>
                );
              })}
            </div>
            <p className="status" role="status">{message}</p>
            <p className="result">
              {save.done === "win" ? `Solved in ${save.guesses.length}.` : ""}
              {save.done === "loss" ? `The word was ${answer.toUpperCase()}.` : ""}
            </p>
            <form
              className="entry"
              onSubmit={(event) => {
                event.preventDefault();
                submit();
              }}
            >
              <label className="sr-only" htmlFor="guess">
                Five letter guess
              </label>
              <input
                id="guess"
                className="guess"
                value={draft}
                maxLength={5}
                autoComplete="off"
                autoCapitalize="characters"
                spellCheck={false}
                disabled={save.done !== "play"}
                onChange={(event) => updateDraft(event.target.value)}
              />
              <button className="wow-button" type="submit" disabled={save.done !== "play"}>
                Enter
              </button>
            </form>
            {save.settings.keyboard !== false ? (
            <div className="keys">
              {KEYS.map((row) => (
                <div className="key-row" key={row}>
                  {row.split("").map((letter) => (
                    <button
                      key={letter}
                      className="key"
                      type="button"
                      data-mark={best[letter] ?? ""}
                      disabled={save.done !== "play"}
                      onClick={() => updateDraft((current) => current + letter)}
                    >
                      {letter}
                    </button>
                  ))}
                </div>
              ))}
            </div>
            ) : null}
            <div className="checks">
              <label className="check">
                <input
                  type="checkbox"
                  checked={save.settings.colorblind}
                  onChange={(event) =>
                    setSave({ ...save, settings: { ...save.settings, colorblind: event.target.checked } })
                  }
                />
                Colorblind
              </label>
              <label className="check">
                <input
                  type="checkbox"
                  checked={save.settings.keyboard !== false}
                  onChange={(event) =>
                    setSave({ ...save, settings: { ...save.settings, keyboard: event.target.checked } })
                  }
                />
                Keys
              </label>
            </div>
            <p className="stats">
              Played {played} · Win {rate}% · Streak {save.stats.streak} · Max {save.stats.maxStreak}
            </p>
            {save.done !== "play" ? (
              <div className="dist" aria-label="Guess distribution">
                {save.stats.dist.map((count, index) => (
                  <div className="dist-row" key={index}>
                    <span>{index + 1}</span>
                    <span className="bar" style={{ width: `${Math.max(8, Math.round((count / maxDist) * 100))}%` }} />
                    <span>{count}</span>
                  </div>
                ))}
              </div>
            ) : null}
            {save.done !== "play" ? (
              <button
                className="wow-button"
                type="button"
                onClick={() => {
                  const pool = lists.answers.filter((word) => word !== dailyAnswer && word !== save.extraAnswer);
                  const pick = pool[Math.floor(Math.random() * pool.length)] ?? dailyAnswer;
                  setSave({
                    ...save,
                    guesses: [],
                    states: [],
                    done: "play",
                    extraAnswer: pick,
                    recorded: true,
                  });
                  setDraft("");
                  setMessage("");
                }}
              >
                Another
              </button>
            ) : null}
            {save.done === "win" ? (
              <div className="share-row">
                {(
                  [
                    ["Say", "say"],
                    ["Party", "party"],
                    ["Yell", "yell"],
                    ["Raid", "raid"],
                    ["Guild", "guild"],
                    ["Whisper", "w"],
                  ] as const
                ).map(([label, slash]) => (
                  <button
                    key={slash}
                    className="wow-button"
                    type="button"
                    onClick={() => {
                      const lines = shareChat(number, save.states, Boolean(save.extraAnswer));
                      const text = lines.join("\n");
                      void navigator.clipboard?.writeText(text).then(
                        () => setMessage(`/${slash}  ${lines[0]}`),
                        () => setMessage(text),
                      );
                    }}
                  >
                    {label}
                  </button>
                ))}
              </div>
            ) : null}
          </div>
        ) : (
          <div className="guild-list">
            {save.done === "play" ? (
              <p className="note">Finish today's puzzle and your guild sees the score and grid, not the words.</p>
            ) : (
              <div className="guild-row">
                <div>
                  <div className="who">You</div>
                  <div className="score">{save.done === "win" ? `${save.guesses.length}/6` : "X/6"}</div>
                </div>
                <div className="mini" aria-hidden="true">
                  {save.states.map((state, row) => (
                    <div className="mini-row" key={row}>
                      {state.split("").map((mark, index) => (
                        <span className="swatch" data-mark={mark} key={index} />
                      ))}
                    </div>
                  ))}
                </div>
              </div>
            )}
            <p className="note">Other guild rows show up in WoW Forever, for people in your guild who have the addon.</p>
          </div>
        )}

        <div className="download">
          <a className="wow-button" href="/leyword.zip" download="Leyword.zip">
            Download addon
          </a>
        </div>
        <p className="install">
          Close WoW Forever, unzip into the game's Interface\AddOns folder, then log in and type /leyword. Add words in CustomWords.lua and /reload. EllesmereUI skins the window on its own.
        </p>
        <div className="words">
          <label className="wow-button">
            Add words
            <input
              className="sr-only"
              type="file"
              accept=".txt,.lua,text/plain"
              onChange={(event) => {
                const file = event.target.files?.[0];
                event.target.value = "";
                if (!file) return;
                void file.text().then((text) => {
                  const parsed = parseWordList(text);
                  setExtras(parsed);
                  const built = buildLists(parsed.answers, parsed.guesses);
                  setMessage(
                    `Using ${built.addedAnswers} puzzle words and ${built.addedGuesses} extra guesses. Leave the puzzle list empty in the file to keep the shared word.`,
                  );
                });
              }}
            />
          </label>
          {extras.answers.length > 0 || extras.guesses.length > 0 ? (
            <button className="wow-button" type="button" onClick={() => setExtras({ answers: [], guesses: [] })}>
              Clear words
            </button>
          ) : null}
        </div>
        {extras.answers.length > 0 || extras.guesses.length > 0 ? (
          <p className="note">
            {lists.addedAnswers} extra puzzle words, {lists.addedGuesses} extra guesses.
          </p>
        ) : null}
      </section>
    </main>
  );
}
