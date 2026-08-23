#!/bin/bash
# Checks the WAM and GPA calculators against the worked example ECU publishes.
# Compiles the real source files from the app target, not a copy of the maths.
#
#   ./Verification/run.sh
#
# Expected: WAM = 58.43, matching the university's published example.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=$(mktemp -d)
swiftc -O UniTrack/Models/*.swift \
          UniTrack/Domain/WAMCalculator.swift \
          UniTrack/Domain/GPACalculator.swift \
          UniTrack/Domain/GradeMapper.swift \
          Verification/main.swift \
          -o "$OUT/verify"
"$OUT/verify"
rm -rf "$OUT"
