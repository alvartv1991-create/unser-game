extends Node
## Global signal hub. Signals only, no logic. See AGENTS.md § Contracts.
## Anyone may ADD signals here (never rename or remove them). Mention additions in your handoff.

@warning_ignore_start("unused_signal")

signal flag_changed(id: String, value: Variant)
signal moral_changed(value: int)                  # only the debug overlay may show this
signal item_changed(id: String, count: int)
signal companion_recruited(id: String)
signal companion_died(id: String, reason: String) # reason: "story:<dialogue cue>" or "combat:<encounter_id>"
signal party_changed()
signal hp_changed()
signal objective_changed(text: String)            # a translation key from localization/story.csv; show it with tr()
signal area_unlocked(area_id: String)
signal scene_changed(scene_path: String)
signal locale_changed(locale: String)
signal dialogue_started(file: String, title: String)
signal dialogue_finished(file: String, title: String)
signal combat_started(encounter_id: String)
signal combat_finished(result: Dictionary)        # {encounter_id, outcome: "win"|"lose"|"flee"|"talk"|"cheat", loot: {item_id: count}, died: [companion_id]}
signal device_glitch(intensity: float, duration: float)   # alien tech interference; intensity 0..1, duration in seconds
signal bark_requested(speaker_id: String, text: String)   # short floating line above a character (text already localized)
