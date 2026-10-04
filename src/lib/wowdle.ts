import { answers, guessList } from "./words.ts";

export type Mark = "G" | "Y" | "B";
export type Done = "play" | "win" | "loss";

export const EPOCH = { y: 2026, m: 1, d: 1 };

const guessSet = new Set<string>([...answers, ...guessList]);

export function rdn(y: number, m: number, d: number): number {
  const a = Math.floor((14 - m) / 12);
  const yy = y + 4800 - a;
  const mm = m + 12 * a - 3;
  return (
    d +
    Math.floor((153 * mm + 2) / 5) +
    365 * yy +
    Math.floor(yy / 4) -
    Math.floor(yy / 100) +
    Math.floor(yy / 400) -
    32045
  );
}

export function dateKey(y: number, m: number, d: number): string {
  return `${y}${String(m).padStart(2, "0")}${String(d).padStart(2, "0")}`;
}

export function puzzleNumber(y: number, m: number, d: number): number {
  return rdn(y, m, d) - rdn(EPOCH.y, EPOCH.m, EPOCH.d) + 1;
}

export function answerFor(y: number, m: number, d: number, list: readonly string[] = answers): string {
  const number = puzzleNumber(y, m, d);
  const index = ((number - 1) % list.length + list.length) % list.length;
  return list[index] ?? list[0];
}

export function scoreGuess(answer: string, guess: string): string {
  const marks: Mark[] = ["B", "B", "B", "B", "B"];
  const left: Record<string, number> = {};
  for (let i = 0; i < 5; i++) {
    if (guess[i] === answer[i]) marks[i] = "G";
    else left[answer[i]] = (left[answer[i]] ?? 0) + 1;
  }
  for (let i = 0; i < 5; i++) {
    if (marks[i] === "G") continue;
    const ch = guess[i];
    if ((left[ch] ?? 0) > 0) {
      marks[i] = "Y";
      left[ch] -= 1;
    }
  }
  return marks.join("");
}

export function hardViolation(guesses: string[], states: string[], guess: string): string | null {
  const green: Array<string | null> = [null, null, null, null, null];
  const minCount: Record<string, number> = {};
  guesses.forEach((previous, index) => {
    const state = states[index] ?? "";
    const seen: Record<string, number> = {};
    for (let i = 0; i < 5; i++) {
      const ch = previous[i] ?? "";
      if (state[i] === "G") green[i] = ch;
      if (state[i] === "G" || state[i] === "Y") seen[ch] = (seen[ch] ?? 0) + 1;
    }
    for (const ch of Object.keys(seen)) {
      if (seen[ch] > (minCount[ch] ?? 0)) minCount[ch] = seen[ch];
    }
  });
  for (let i = 0; i < 5; i++) {
    if (green[i] && guess[i] !== green[i]) return "Hard mode: use the revealed hints.";
  }
  const counts: Record<string, number> = {};
  for (const ch of guess) counts[ch] = (counts[ch] ?? 0) + 1;
  for (const ch of Object.keys(minCount)) {
    if ((counts[ch] ?? 0) < minCount[ch]) return "Hard mode: use the revealed hints.";
  }
  return null;
}

export function isGuess(word: string, valid: Set<string> = guessSet): boolean {
  return valid.has(word);
}

export function normalizeWord(word: string): string | null {
  const clean = word.toLowerCase().replace(/[^a-z]/g, "");
  return clean.length === 5 ? clean : null;
}

export function parseWordList(text: string): { answers: string[]; guesses: string[] } {
  let mode: "answers" | "guesses" = "answers";
  let sawHeader = false;
  const answerWords: string[] = [];
  const guessWords: string[] = [];
  for (const line of text.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#") || trimmed.startsWith("--")) continue;
    const tokens = trimmed.toLowerCase().split(/[^a-z]+/).filter(Boolean);
    const words = tokens.filter((word) => word.length === 5);
    if (words.length === 0) {
      if (tokens.includes("answer") || tokens.includes("answers")) {
        mode = "answers";
        sawHeader = true;
      } else if (tokens.includes("guess") || tokens.includes("guesses") || tokens.includes("valid")) {
        mode = "guesses";
        sawHeader = true;
      }
      continue;
    }
    (mode === "guesses" ? guessWords : answerWords).push(...words);
  }
  if (!sawHeader) {
    return { answers: [...answerWords, ...guessWords], guesses: [] };
  }
  return { answers: answerWords, guesses: guessWords };
}

export function buildLists(extraAnswers: string[], extraGuesses: string[]) {
  const valid = new Set(guessSet);
  const custom: string[] = [];
  const seen = new Set<string>();
  let addedAnswers = 0;
  let addedGuesses = 0;
  for (const raw of extraAnswers) {
    const word = normalizeWord(raw);
    if (!word || seen.has(word)) continue;
    seen.add(word);
    custom.push(word);
    valid.add(word);
    addedAnswers += 1;
  }
  for (const raw of extraGuesses) {
    const word = normalizeWord(raw);
    if (!word) continue;
    if (!valid.has(word) && !seen.has(word)) addedGuesses += 1;
    valid.add(word);
  }
  return {
    answers: custom.length > 0 ? custom : [...answers],
    valid,
    addedAnswers,
    addedGuesses,
  };
}

export function shareChat(number: number, states: string[]): string[] {
  const grid = states.map((state) => state.replace(/[^GYB]/g, "")).join(" ");
  return [
    `Wordle of Warcraft ${number} ${states.length}/6 ${grid}`,
    "Don't have Wordle of Warcraft? Install the addon to play today's word.",
  ];
}

export type Stats = {
  played: number;
  wins: number;
  streak: number;
  maxStreak: number;
  lastDate: string | null;
  dist: number[];
};

export function emptyStats(): Stats {
  return { played: 0, wins: 0, streak: 0, maxStreak: 0, lastDate: null, dist: [0, 0, 0, 0, 0, 0] };
}

export function recordFinish(stats: Stats, y: number, m: number, d: number, won: boolean, guesses: number): Stats {
  const next: Stats = { ...stats, dist: [...stats.dist] };
  const key = dateKey(y, m, d);
  next.played += 1;
  if (won) {
    next.wins += 1;
    next.dist[guesses - 1] = (next.dist[guesses - 1] ?? 0) + 1;
    if (stats.lastDate) {
      const prev = stats.lastDate;
      const py = Number(prev.slice(0, 4));
      const pm = Number(prev.slice(4, 6));
      const pd = Number(prev.slice(6, 8));
      next.streak = rdn(y, m, d) - rdn(py, pm, pd) === 1 ? stats.streak + 1 : 1;
    } else {
      next.streak = 1;
    }
    next.maxStreak = Math.max(next.maxStreak, next.streak);
  } else {
    next.streak = 0;
  }
  next.lastDate = key;
  return next;
}
