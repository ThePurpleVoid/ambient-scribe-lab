# PHI controls

This lab is built with HIPAA-style controls. It is a demo lab, holds no real patient data, and makes no compliance claim.

## Data rules
- No real patient data, ever. Fixtures are synthetic or from public de-identified sets, and every fixture file name contains `synthetic`.
- No transcript or note text in logs, analytics events, crash reports or error messages. Log chunk ids, sizes and timings only.
- Audio on the device is encrypted at rest and deleted after confirmed upload.

## Merge gate
Every PR runs `bash tests/phi/scan.sh` (see `.github/workflows/phi-gate.yml`). It checks, without any model:
- private kit files tracked in git;
- fixture file names without `synthetic`;
- Safe Harbor style identifiers: SSN, phone, email, record number, date of birth, street address;
- banned claims about compliance or clinical validation (the exact phrases are in `tests/phi/scan.sh`).

It prints file and line only, never the matched text, and fails closed. Model review runs only after it passes, on what it cannot decide.

## Approved vendors
Audio or note text may only be sent to a service listed here. The list is empty until the owner approves one, so any such call blocks the merge.

| Vendor | Used for | Data sent | Retention | Approved on |
| --- | --- | --- | --- | --- |

## Retention
Not set yet. Until it is, nothing is kept server-side beyond a test run.
