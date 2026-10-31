const { spawn, execSync } = require("child_process");
const fs = require("fs");
const path = require("path");

function findGodotExecutable() {
  const localWingetConsole = path.join(
    process.env.LOCALAPPDATA || "",
    "Microsoft",
    "WinGet",
    "Packages",
    "GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe",
    "Godot_v4.7.2-stable_win64_console.exe"
  );
  if (fs.existsSync(localWingetConsole)) {
    return localWingetConsole;
  }

  const localWinget = path.join(
    process.env.LOCALAPPDATA || "",
    "Microsoft",
    "WinGet",
    "Packages",
    "GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe",
    "Godot_v4.7.2-stable_win64.exe"
  );
  if (fs.existsSync(localWinget)) {
    return localWinget;
  }

  try {
    const stdout = execSync("where.exe godot", { encoding: "utf-8" }).trim();
    const firstLine = stdout.split(/\r?\n/)[0];
    if (firstLine && fs.existsSync(firstLine)) {
      return firstLine;
    }
  } catch (e) {}

  return "godot";
}

const isEditor = process.argv.includes("--editor") || process.argv.includes("-e");
const exe = findGodotExecutable();
const projectDir = __dirname;

const args = ["--path", projectDir];
if (isEditor) {
  args.push("--editor");
}

console.log(`[Clowder Launcher] Using Godot: ${exe}`);
console.log(`[Clowder Launcher] Starting in ${isEditor ? "Editor" : "Game"} mode...`);

const child = spawn(exe, args, {
  stdio: "inherit",
  cwd: projectDir
});

child.on("exit", (code) => {
  process.exit(code || 0);
});
