# AI Pipeline Notes

## Goal

This folder owns the mock-first diagnosis brain for KrishiAvalokan. It is deterministic, local, and demo-safe: no network call, trained model, or API key is required.

## Flow

1. `utils/feature_builder.py` validates `sowingDate`, infers the broad crop season, and normalizes symptoms by lowercasing and removing spaces.
2. `rules/diagnosis_rules.json` stores six cause rules: drought, waterlogging, pest, fungal, heat, and nutrient.
3. `diagnosis_engine.py` creates three mock weather phases from the sowing date: Early, Mid, and Late.
4. Each cause receives a weighted score from symptom matches, weather phase matches, base weight, and season hints.
5. The top cause is returned with `causeKey`, `causeTitle`, `confidenceScore`, `explanation`, `weatherPhases`, and `recommendations`.

## Scoring

The scorer is intentionally simple:

- Symptom matches are the strongest signal.
- Weather phase compatibility is the second signal.
- Base weight keeps every cause available even when input is incomplete.
- Season hints add a small boost only when the sowing month fits the common season.

Confidence is capped at `0.97`. Empty or weak symptom input is capped lower so the UI can show a cautious result.

## Mock Weather

The weather generator uses the sowing date plus phase offsets:

- Early: sowing date
- Mid: sowing date + 45 days
- Late: sowing date + 90 days

It maps the phase month to broad Indian weather patterns and adds a stable district-based shift. This gives repeatable but location-sensitive demo behavior.

## Future Upgrade Path

When real data is available, keep the same response contract and replace only the scoring internals. A later classifier can use features such as crop, symptoms, rainfall bucket, temperature bucket, humidity bucket, season, and cause label.
