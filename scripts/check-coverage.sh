#!/usr/bin/env bash
# Merge unit-test result bundles and fail if the app target's line coverage is below a threshold.
# Usage: scripts/check-coverage.sh THRESHOLD_PERCENT BUNDLE.xcresult [BUNDLE.xcresult ...]
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 THRESHOLD_PERCENT BUNDLE.xcresult [BUNDLE.xcresult ...]" >&2
  exit 2
fi

threshold="$1"
shift

work="$(mktemp -d)"
trap 'command rm -rf "${work:?}"' EXIT

if [[ $# -gt 1 ]]; then
  merged="${work}/merged.xcresult"
  xcrun xcresulttool merge "$@" --output-path "${merged}" >/dev/null
else
  merged="$1"
fi

xcrun xccov view --report --json "${merged}" | python3 -c '
import json, sys

threshold = float(sys.argv[1])
report = json.load(sys.stdin)
app = next(t for t in report["targets"] if t["name"].endswith(".app"))
percent = app["lineCoverage"] * 100
print("%s: %.1f%% line coverage (%d/%d lines), threshold %g%%"
      % (app["name"], percent, app["coveredLines"], app["executableLines"], threshold))
if percent < threshold:
    sys.exit("Coverage %.1f%% is below the %g%% threshold" % (percent, threshold))
' "${threshold}"
