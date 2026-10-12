// Rings the terminal bell when a top-level session shown in this TUI finishes so tmux `monitor-bell` flags the window
import { Plugin } from "@opencode/plugin/tui"

export default Plugin.define({
  id: "terminal-bell",
  setup(context) {
    // Every TUI on the shared service receives every session's events, so only ring for sessions open in this one
    const visible = (sessionID: string) => {
      if (context.ui.tabs.enabled()) return context.ui.tabs.list().some((tab) => tab.sessionID === sessionID)
      const route = context.ui.router.current()
      return route.type === "session" && context.data.session.root(route.sessionID) === sessionID
    }

    const ring = (sessionID: string) => {
      const session = context.data.session.get(sessionID)
      if (!session || session.parentID || !visible(sessionID)) return
      process.stdout.write("\x07")
    }

    const stop = [
      context.data.on("session.execution.succeeded", (event) => ring(event.data.sessionID)),
      context.data.on("session.execution.failed", (event) => ring(event.data.sessionID)),
      context.data.on("session.execution.interrupted", (event) => {
        if (event.data.reason === "user" || event.data.reason === "superseded") return
        ring(event.data.sessionID)
      }),
    ]

    return () => stop.forEach((cleanup) => cleanup())
  },
})
