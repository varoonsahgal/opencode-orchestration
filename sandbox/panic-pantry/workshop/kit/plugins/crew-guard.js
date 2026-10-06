// Panic Pantry crew guard: an OpenCode plugin (hooks).
// OpenCode auto-loads any .js/.ts file in .opencode/plugins/ at startup.
// Restart OpenCode after adding or changing this file.
//
// Three hooks, all plain code that runs on EVERY tool call, by EVERY agent:
//   1. Flight recorder (tool.execute.before): logs each call to workshop/tool-log.md
//   2. Frozen-file guard (tool.execute.before): refuses writes to frozen files
//   3. Test nudge (tool.execute.after): after a write to src/ or tests/,
//      appends a reminder the agent reads along with the tool result
import { appendFileSync, existsSync } from "node:fs"

const FROZEN = [
  "tests/test_importer_contract.py",
  "fixtures/",
  "data/promotions.json", // also matches data/promotions.json.seed
  "scripts/",
  "tickets/",
  "AGENTS.md",
]
const WRITE_TOOLS = new Set(["edit", "write", "patch", "apply_patch", "multiedit"])

// Paths a write-type tool is about to touch (never its file contents).
function targetPaths(args, directory) {
  const paths = [args.filePath, args.path].filter(Boolean)
  const patch = args.patchText ?? args.patch ?? ""
  for (const m of String(patch).matchAll(/^\*\*\* (?:Add|Update|Delete) File: (.+)$/gm)) paths.push(m[1])
  return paths.map((p) => String(p).replace(directory + "/", ""))
}

function summary(tool, args, directory) {
  if (tool === "bash") return args.command
  if (tool === "skill") return `loaded skill: ${args.name}`
  if (tool === "task") return `delegated to @${args.subagent_type}: ${args.description ?? ""}`
  return targetPaths(args, directory).join(", ") || args.pattern || ""
}

export const CrewGuard = async ({ directory }) => {
  const log = `${directory}/workshop/tool-log.md`
  if (!existsSync(log)) appendFileSync(log, "# Tool log (written by crew-guard)\n\n| Time | Session | Tool | What |\n|---|---|---|---|\n")

  return {
    "tool.execute.before": async (input, output) => {
      // Each session (Lead's, and each child's) has its own ID. A new ID right
      // after a "delegated to @…" row is that child's session.
      const who = `…${input.sessionID.slice(-4)}`
      const time = new Date().toTimeString().slice(0, 8)
      const what = String(summary(input.tool, output.args ?? {}, directory)).replaceAll("|", "\\|").slice(0, 90)
      appendFileSync(log, `| ${time} | ${who} | ${input.tool} | ${what} |\n`)

      if (WRITE_TOOLS.has(input.tool)) {
        const hit = targetPaths(output.args ?? {}, directory).find((p) => FROZEN.some((f) => p.startsWith(f)))
        if (hit) {
          appendFileSync(log, `| ${time} | ${who} | 🛑 BLOCKED | ${hit} is frozen |\n`)
          throw new Error(`crew-guard: ${hit} is frozen for every agent (see AGENTS.md). Report the problem to the human instead of editing it.`)
        }
      }
    },

    "tool.execute.after": async (input, output) => {
      if (!WRITE_TOOLS.has(input.tool)) return
      const touched = targetPaths(input.args ?? {}, directory)
      if (touched.some((p) => p.startsWith("src/") || p.startsWith("tests/"))) {
        output.output += "\n\n[crew-guard] You changed product code. Run `python3 -m unittest discover -s tests -v` before you report DONE."
      }
    },
  }
}
