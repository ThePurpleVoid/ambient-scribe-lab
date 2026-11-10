#!/usr/bin/env bash
# Deterministic PHI and public-repo scan. Runs on every PR before any model-based review.
# Fails closed: any hit blocks the merge until someone shows it is safe.
# Prints file:line and the rule that matched, never the matched text.
#
#   bash tests/phi/scan.sh            scan every tracked and staged file
#   bash tests/phi/scan.sh FILE...    scan only these files
#
# A line can be cleared after review by adding the marker  phi-scan:reviewed-synthetic  to it,
# and only inside a file whose name contains "synthetic".
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

fail=0
hit() { printf 'BLOCK  %s  %s\n' "$1" "$2"; fail=1; }

# 1. Private kit files must never be tracked in this public repo.
while IFS= read -r f; do
  case "$f" in
    .agent-team/*|docs/team/*|scripts/agent-team/*|CLAUDE.md|.claude/*) hit "$f" "private kit file is tracked; remove it from git" ;;
  esac
done < <(git ls-files --cached 2>/dev/null)

if [ $# -gt 0 ]; then
  files=("$@")
else
  mapfile -t files < <(git ls-files --cached 2>/dev/null | grep -v '^tests/phi/')
fi

# 2. Fixture names must say "synthetic".
for f in "${files[@]}"; do
  case "$f" in
    evals/fixtures/*) [ -f "$f" ] && case "$(basename "$f")" in *synthetic*|README.md|LICENSE*|*.license.md) ;; *) hit "$f" "fixture file name must contain \"synthetic\"" ;; esac ;;
  esac
done

# 3. Safe Harbor style identifiers and banned claims, line by line.
#    The employer and kit name patterns are stored encoded so the names never appear in this repo.
employer="$(printf 'a25vd3RleA==' | base64 -d)"
kit="$(printf '%s' 'b3JnY3JhZnR8YWdlbnQgdGVhbSBraXQ=' | base64 -d)"
declare -a names=(
  "US social security number pattern"
  "US phone number pattern"
  "email address"
  "medical record number pattern"
  "date of birth next to a date"
  "street address pattern"
  "\"HIPAA compliant\" claim (say: built with HIPAA-style controls)"
  "\"clinically validated\" claim (say: measured on public data)"
  "prospective employer name (keep the repo general)"
  "private kit described as open source"
)
declare -a pats=(
  '\b[0-9]{3}-[0-9]{2}-[0-9]{4}\b'
  '(\(?\b[0-9]{3}\)?[-. ][0-9]{3}[-. ][0-9]{4}\b)'
  '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
  '\b(MRN|medical record( number)?)[^A-Za-z0-9]{0,4}[A-Z]{0,3}[0-9]{5,}'
  '\b(DOB|date of birth|born on)\b.{0,20}[0-9]{1,4}[-/.][0-9]{1,2}[-/.][0-9]{1,4}'
  '\b[0-9]{2,5} [A-Z][a-z]+ (Street|St|Avenue|Ave|Road|Rd|Lane|Ln|Drive|Dr|Boulevard|Blvd)\b'
  'HIPAA[- ]compliant'
  'clinically[- ]validated'
  "\\b${employer}\\b"
  "(${kit}).{0,40}open[- ]source"
)
# Addresses that are allowed: no-reply bot addresses and reserved example domains.
email_ok='noreply@|@example\.(com|org|net)|@users\.noreply\.github\.com'

for f in "${files[@]}"; do
  [ -f "$f" ] || continue
  grep -Iq . "$f" 2>/dev/null || continue   # skip binary files
  for i in "${!pats[@]}"; do
    while IFS=: read -r ln rest; do
      [ -n "$ln" ] || continue
      line="$(sed -n "${ln}p" "$f")"
      if [ "$i" = 2 ] && grep -Eqi "$email_ok" <<<"$line"; then continue; fi
      if grep -q 'phi-scan:reviewed-synthetic' <<<"$line" && [[ "$(basename "$f")" == *synthetic* ]]; then continue; fi
      hit "$f:$ln" "${names[$i]}"
    done < <(grep -nEi "${pats[$i]}" "$f" 2>/dev/null | cut -d: -f1 | sed 's/$/:/')
  done
done

if [ "$fail" -ne 0 ]; then
  echo "PHI scan: BLOCKED. Fix each line above, or show it is safe and mark it (synthetic fixtures only)."
  exit 1
fi
echo "PHI scan: clean (${#files[@]} files)."
