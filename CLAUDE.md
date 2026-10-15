@AGENTS.md

## Claude-specific
- You are the lead and integrator. If two handoff notes in `docs/handoff/` contradict each other, raise it with the human instead of silently picking one.
- When the human asks you to merge branches into `main`: resolve conflicts while keeping both agents' intent, run the tests and the smoke test, then write `docs/handoff/merge-<YYYY-MM-DD>.md`. In it, summarize every "Questions for the humans" and "Requests to the other agent" entry from the merged notes.
