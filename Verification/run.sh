#!/bin/bash
# Checks the parts of UniTrack that have a right answer, against real sources.
#
#   ./Verification/run.sh
#
# 1. WAM and GPA, against the worked example ECU publishes (expects 58.43).
# 2. Password hashing: salting, verification, and rejection of bad input.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=$(mktemp -d)
trap 'rm -rf "$OUT"' EXIT

echo "--- Calculations ---"
swiftc -O UniTrack/Models/*.swift \
          UniTrack/Domain/WAMCalculator.swift \
          UniTrack/Domain/GPACalculator.swift \
          UniTrack/Domain/GradeMapper.swift \
          UniTrack/Domain/Security/PasswordHasher.swift \
          Verification/main.swift \
          -o "$OUT/calc"
"$OUT/calc"

echo
swiftc -O UniTrack/Domain/Security/PasswordHasher.swift \
          Verification/Auth/main.swift \
          -o "$OUT/auth"
"$OUT/auth"
