import assert from "node:assert/strict";
import { test } from "node:test";
import { answers, guessList } from "./words.ts";
import { answerFor, buildLists, hardViolation, parseWordList, puzzleNumber, scoreGuess } from "./wowdle.ts";

test("puzzle number matches the realm-day count", () => {
  assert.equal(puzzleNumber(2026, 1, 1), 1);
  assert.equal(puzzleNumber(2026, 10, 4), 277);
  assert.equal(puzzleNumber(2026, 1, 2), 2);
});

test("scoring handles greens, yellows, and repeats", () => {
  assert.equal(scoreGuess("crane", "crane"), "GGGGG");
  assert.equal(scoreGuess("crane", "trace"), "BGGYG");
  assert.equal(scoreGuess("allot", "llama"), "YGYBB");
  assert.equal(scoreGuess("books", "boost"), "GGGYB");
  assert.equal(scoreGuess("abbey", "babes"), "YYGGB");
});

test("hard mode keeps revealed hints", () => {
  assert.equal(hardViolation(["slate"], ["BBGBG"], "apple"), "Hard mode: use the revealed hints.");
  assert.equal(hardViolation(["slate"], ["BBGBG"], "crane"), null);
});

test("a custom answer list replaces the puzzle and extra guesses stay valid", () => {
  const base = answerFor(2026, 10, 4);
  const guessesOnly = buildLists([], ["xyzzq"]);
  assert.equal(answerFor(2026, 10, 4, guessesOnly.answers), base);
  assert.equal(guessesOnly.valid.has("xyzzq"), true);
  assert.equal(guessesOnly.valid.has("crane"), true);
  const parsed = parseWordList("-- note\nglyph\nblarg\n\nguesses\nxyzzq\n");
  const merged = buildLists(parsed.answers, parsed.guesses);
  assert.deepEqual(merged.answers, ["glyph", "blarg"]);
  assert.equal(merged.addedGuesses, 1);
  assert.equal(answerFor(2026, 10, 4, merged.answers), "glyph");
  assert.equal(merged.valid.has("crane"), true);
});

test("word lists are five-letter and answers are guessable", () => {
  const guesses = new Set(guessList);
  assert.ok(answers.length >= 300);
  for (const word of answers) {
    assert.match(word, /^[a-z]{5}$/);
    assert.ok(guesses.has(word), word);
  }
  assert.equal(new Set(answers).size, answers.length);
  assert.ok(guesses.has("thick"));
  assert.ok(guesses.has("tanky"));
  assert.ok(guesses.size > 15000);
  assert.match(answerFor(2026, 10, 4), /^[a-z]{5}$/);
});
