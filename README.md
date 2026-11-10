# ambient-scribe-lab

A small lab for the hard parts of an ambient clinical AI scribe: capturing a long visit on an Android phone without losing audio, scoring how much of an AI-written note a clinician would keep, and catching note errors with a citation to the transcript line.

No real patient data is used anywhere. Fixtures are synthetic or from public de-identified sets, and every fixture file name says `synthetic`. The lab is built with HIPAA-style controls and makes no compliance or clinical-validation claim; numbers are measured on public data.

## Status (updated 2026-11-10)

| Part | Works today | Measured on | Command |
| --- | --- | --- | --- |
| PHI merge gate (deterministic scan, fails closed) | Yes | 9 self-test cases | `bash tests/phi/test.sh && bash tests/phi/scan.sh` |
| Android capture app (`android/`) | Not built yet | | |
| Audio reliability matrix (`docs/audio-reliability-matrix.md`) | Not built yet | | |
| Keep-rate eval on public encounters (`evals/`) | Not built yet | | |
| Note QA with transcript citations (`evals/note-qa/`) | Not built yet | | |
| FHIR R4 export check | Not planned before the first demo | | |

Audio reliability is measured as two numbers: seconds of captured audio lost (target zero: every chunk the phone wrote is uploaded exactly once), and capture gap seconds while a phone call holds the microphone or the app is restarting. Gaps are reported, never hidden.

Every number in this README comes from a run anyone can repeat with the command next to it. A suite with fewer than 20 cases is reported as too small to gate.

## Repository layout

- `android/` capture app (foreground service, chunked encrypted recording, resumable upload)
- `tests/audio-reliability/` the reliability matrix runner
- `evals/` keep-rate harness and fixtures; `evals/note-qa/` note error checks
- `tests/phi/` the PHI scan and its tests
- `docs/` controls, results and the error taxonomy
