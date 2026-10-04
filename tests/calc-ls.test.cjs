// Run from the repository root: node --test tests/calc-ls.test.cjs
const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const path = require("node:path");
const test = require("node:test");

function evaluate(input) {
  const result = spawnSync(
    process.execPath,
    [path.join(__dirname, "../bin/calc-ls")],
    { input, encoding: "utf8", timeout: 5000 },
  );
  assert.ifError(result.error);
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stderr, "");
  return JSON.parse(result.stdout);
}

test("preserves blank lines inside multiline template literals", () => {
  assert.deepEqual(evaluate("`first\n\nlast`"), [
    { line: 3, message: JSON.stringify("first\n\nlast") },
  ]);
});

test("preserves comment-looking text inside multiline template literals", () => {
  assert.deepEqual(evaluate("`first\n  // literal text\nlast`"), [
    { line: 3, message: JSON.stringify("first\n  // literal text\nlast") },
  ]);
});

test("uses all literal lines when calculating string lengths", () => {
  assert.deepEqual(evaluate("const text = `a\n\n//b\nc`\ntext.length"), [
    { line: 5, message: "8" },
  ]);
});

test("skips standalone comments and blanks while keeping diagnostic rows", () => {
  assert.deepEqual(evaluate("\n// comment\n  \n40 + 2\n// trailing"), [
    { line: 4, message: "42" },
  ]);
});

test("retains persistent declarations and multiline arrays with comments", () => {
  assert.deepEqual(
    evaluate("const x = 6\nx * 7\n[\n  x,\n\n  // comment\n  7\n]"),
    [
      { line: 2, message: "42" },
      { line: 8, message: "[6,7]" },
    ],
  );
});

test("continues after invalid calculations and timed-out statements", () => {
  assert.deepEqual(evaluate("unknownVariable\nwhile (true) {}\n40 + 2"), [
    { line: 3, message: "42" },
  ]);
});
