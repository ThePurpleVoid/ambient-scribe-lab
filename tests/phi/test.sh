#!/usr/bin/env bash
# Proves the PHI scan blocks what it should and passes what it should. Every fake value below is
# assembled at run time so this file itself stays clean.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"; log="$(mktemp)"; trap 'rm -rf "$tmp" "$log"' EXIT
cd "$tmp" && git init -q && mkdir -p evals/fixtures app tests/phi && cp "$here/scan.sh" tests/phi/

expect() { # expect <block|pass> <description>
  git add -A >/dev/null
  if bash tests/phi/scan.sh >"$log" 2>&1; then got=pass; else got=block; fi
  if [ "$got" = "$1" ]; then echo "ok    $2"; else echo "FAIL  $2 (expected $1, got $got)"; cat "$log"; exit 1; fi
  git read-tree --empty; rm -rf app/* evals/fixtures/* .agent-team
}

d=$(printf '%s-%s-%s' 123 45 6789)
echo "Log.d(TAG, \"patient ssn $d\")" > app/Recorder.kt;                 expect block "SSN-shaped number in app code"
echo "call back at $(printf '(%s) %s-%s' 415 555 0134)" > app/a.txt;    expect block "phone number"
echo "MRN: $(printf '%s' 00482913)" > app/a.txt;                         expect block "record number"
echo "DOB $(printf '%s/%s/%s' 03 14 1962)" > app/a.txt;                 expect block "date of birth"
echo "{}" > evals/fixtures/encounter-01.json;                             expect block "fixture without synthetic in its name"
echo "This is $(printf 'HIPAA %s' compliant)." > app/README.md;           expect block "banned compliance claim"
mkdir -p .agent-team && echo x > .agent-team/config.sh;                   expect block "private kit file tracked"
echo "Patient denies chest pain." > evals/fixtures/encounter-01.synthetic.json; expect pass "clean synthetic fixture"
echo "Log.d(TAG, \"chunk 12 uploaded\")" > app/Recorder.kt;              expect pass "clean app log line"
echo "All PHI scan tests passed."
