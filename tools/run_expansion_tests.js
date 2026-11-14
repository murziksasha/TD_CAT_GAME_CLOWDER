const { spawnSync, execFileSync } = require("child_process");
const fs = require("fs");
const path = require("path");

function findGodot() {
  const winget = path.join(
    process.env.LOCALAPPDATA || "",
    "Microsoft", "WinGet", "Packages",
    "GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe",
    "Godot_v4.7.2-stable_win64_console.exe"
  );
  if (fs.existsSync(winget)) return winget;
  try {
    return execFileSync("where.exe", ["godot"], { encoding: "utf8" }).trim().split(/\r?\n/)[0];
  } catch (_) {
    return "godot";
  }
}

const root = path.dirname(__dirname);
const tests = [
  "res://tools/test_testing_lab.gd",
  "res://tools/test_testing_lab_ui.gd",
  "res://tools/test_alley_crawl.gd",
  "res://tools/test_alley_crawl_ui.gd"
];

for (const script of tests) {
  const result = spawnSync(findGodot(), ["--headless", "--path", root, "--script", script], {
    cwd: root,
    encoding: "utf8"
  });
  if (result.stdout) process.stdout.write(result.stdout);
  if (result.stderr) process.stderr.write(result.stderr);
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status || 1);
  const combined = `${result.stdout || ""}\n${result.stderr || ""}`;
  if (/SCRIPT ERROR:|Parse Error:|Compile Error:|^ERROR:/m.test(combined)) {
    console.error(`[FAIL] Godot reported an error while running ${script}`);
    process.exit(1);
  }
}

console.log("[PASS] Grand Expansion headless test suite");
