# Moral log

Every choice that changes the hidden moral ("Solidarität", −100 … 100, start 0), and every option that only appears under a condition. Use it to tune the numbers. The thresholds are in `data/rules.json`: **low ≤ −25, high ≥ 25**.

To change a value, edit the number in `$> GameState.add_moral(…)` in the dialogue file, then update this table.

## Choices that change moral
| File | Cue | Choice (German) | Δ |
|---|---|---|---|
| `area1/cook.dialogue` | `first_meet` | Wir teilen das Essen. Halbe-halbe. | +10 |
| `area1/cook.dialogue` | `first_meet` | Gib mir die Dose. Sofort. | −10 |
| `area1/cook.dialogue` | `campfire` | Ich geb meine Dose dazu. (needs a can) | +5 |
| `area1/raiders.dialogue` | `street` | Hier, nehmt meine Konserve. (needs a can) | +10 |
| `area1/raiders.dialogue` | `street` | Verschwindet, oder ich nehme euch eure Schuhe weg. | −10 |
| `area1/videostore.dialogue` | `clerk` | Ich helfe dir, die Rollläden zu reparieren. | +10 |
| `area1/videostore.dialogue` | `clerk` | Ich nehme mir, was in der Kasse ist. | −15 |
| `area1/videostore.dialogue` | `clerk` | Der Automat hat einen Wackelkontakt. (craftsman) | +5 |
| `area1/videostore.dialogue` | `sword_shelf` | Nehmen. (taking the sword without asking) | −5 |
| `area1/tinkerer.dialogue` | `first_meet` | Du redest mit einer Satellitenschüssel. | −5 |
| `area1/tinkerer.dialogue` | `first_meet` | Trägerfrequenz mit Phasenmodulation. (scientist) | +5 |
| `area1/tinkerer.dialogue` | `first_meet` | Die Halterung ist locker. (craftsman) | +5 |
| `area1/raiders.dialogue` | `camp_after_fight` | Lauf. Und lass dich hier nicht mehr blicken. | +5 |
| `area1/raiders.dialogue` | `camp_after_fight` | Dafür ist es zu spät. (low moral only, kills the raider) | −30 |
| `area1/alien_zone.dialogue` | `dilemma_choices` | Wir holen ihn zusammen raus. | +10 |
| `area1/alien_zone.dialogue` | `dilemma_choices` | Weitergehen. Nicht unser Problem. | −15 |
| combat | any human fight | winning by talking (`talk_win_moral` in `data/rules.json`) | rule |

**Reachable before the raider camp** (checked by `tests/dialogue/test_area1_dialogue.gd`):
- **High:** cook +10, clerk +10 (gives a can), street raiders +10 (with that can), tinkerer +5 (scientist/craftsman) = up to +35. Without a job bonus it's +30 (cook, clerk, street), still enough.
- **Low:** cook −10, clerk −15, sword −5, street −10, tinkerer −5 = down to −45.

## Options that depend on something
**Hidden** means the player never sees it. **Greyed out** means it's shown disabled with the reason, e.g. "[Arzt/Ärztin]" (tag `[#show_locked]`). Moral options are always hidden.

| File | Cue | Choice (German) | Condition | Shown as |
|---|---|---|---|---|
| `raiders.dialogue` | `camp_choices` | Erinnert ihr euch an mich? (a raider lets you through) | `moral_is("high")` | hidden |
| `raiders.dialogue` | `camp_after_fight` | Dafür ist es zu spät. (kill the raider) | `moral_is("low")` | hidden |
| `raiders.dialogue` | `street` | Hier, nehmt meine Konserve. | `has_item("canned_food")` | greyed out |
| `raiders.dialogue` | `street` | Polizei! Hände hoch! | `job_is("police")` | greyed out |
| `raiders.dialogue` | `camp_choices` | Hier, eine Konserve. Für den Durchgang. | `has_item("canned_food")` | greyed out |
| `raiders.dialogue` | `camp_choices` | Du blutest. Lass mich das verbinden. | `job_is("doctor")` | greyed out |
| `raiders.dialogue` | `camp_choices` | Euer Generator stottert. | `job_is("craftsman")` | greyed out |
| `raiders.dialogue` | `camp_choices` | Ich zeige meine Dienstmarke. | `job_is("police")` | greyed out |
| `raiders.dialogue` | `camp_choices` | Der Schwarm reagiert auf euren Lärm. | `job_is("scientist")` | greyed out |
| `raiders.dialogue` | `camp_choices` | Durchgangsgenehmigung. (useless) | `job_is("civil_servant")` | greyed out |
| `cook.dialogue` | `first_meet` | Haltbarkeitsdatum war 1979. | `job_is("doctor")` | greyed out |
| `cook.dialogue` | `first_meet` | Essensration in dreifacher Ausfertigung. (useless) | `job_is("civil_servant")` | greyed out |
| `cook.dialogue` | `campfire` | Ich geb meine Dose dazu. | `has_item("canned_food")` | greyed out |
| `tinkerer.dialogue` | `first_meet` | Trägerfrequenz mit Phasenmodulation. | `job_is("scientist")` | greyed out |
| `tinkerer.dialogue` | `first_meet` | Die Halterung ist locker. | `job_is("craftsman")` | greyed out |
| `tinkerer.dialogue` | `first_meet` | Antenne beschlagnahmen. | `job_is("police")` | greyed out |
| `videostore.dialogue` | `clerk` | Wackelkontakt. | `job_is("craftsman")` | greyed out |
| `videostore.dialogue` | `clerk` | Quittung über meinen Besuch. (useless) | `job_is("civil_servant")` | greyed out |
| `alien_zone.dialogue` | `dilemma_choices` | Koch/Köchin, du lenkst ihn ab. (**kills the cook**) | `in_party("cook")` | hidden |
| `alien_zone.dialogue` | `dilemma_choices` | Bastler/in, kannst du ihr Signal stören? | `in_party("tinkerer")` | hidden |
| `alien_zone.dialogue` | `dilemma_choices` | Wirf was Glänzendes in die andere Richtung! | `job_is("scientist")` | greyed out |
| `alien_zone.dialogue` | `dilemma_choices` | Evakuierung des Busses anordnen. (useless) | `job_is("civil_servant")` | greyed out |
| `cult.dialogue` | `teaser` | Siebenundzwanzig Takte, dann Pause. | `job_is("scientist")` | hidden |

## Ways through the raider camp (`raiders_camp_resolved`)
`talk` (the right answer in `camp_talk`, or winning the fight by talking), `bribe` (a can), `job` (doctor, craftsman, police, scientist; the civil servant's option does nothing), `moral` (high moral), `fight` (then `camp_after_fight`). Every way gives the `jammer`.
