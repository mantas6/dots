// Rings the terminal bell when a top-level session finishes so tmux `monitor-bell` flags the window
import { Plugin } from "@opencode/plugin/tui"

export default Plugin.define({
  id: "terminal-bell",
  setup(context) {
    const ring = (sessionID: string) => {
      if (context.data.session.get(sessionID)?.parentID) return
      process.stdout.write("\x07")
    }

    const stop = [
      context.data.on("session.execution.succeeded", (event) => ring(event.data.sessionID)),
      context.data.on("session.execution.failed", (event) => ring(event.data.sessionID)),
      context.data.on("session.execution.interrupted", (event) => ring(event.data.sessionID)),
    ]

    return () => stop.forEach((cleanup) => cleanup())
  },
})
