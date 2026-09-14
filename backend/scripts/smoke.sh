#!/usr/bin/env bash
# End-to-end smoke test for the CheckIn API.
# Usage: bash scripts/smoke.sh [base_url]   (default http://localhost:8787)
set -euo pipefail
BASE="${1:-http://localhost:8787}"
USER="smoke_$RANDOM"
PASS="password123"
j() { python3 -c "import sys,json; print(json.load(sys.stdin)$1)"; }

echo "== health";   curl -sf "$BASE/health"; echo
echo "== register $USER"
TOKEN=$(curl -sf -X POST "$BASE/auth/register" -H 'Content-Type: application/json' \
  -d "{\"username\":\"$USER\",\"password\":\"$PASS\"}" | j "['token']")
echo "== login";    curl -sf -X POST "$BASE/auth/login" -H 'Content-Type: application/json' \
  -d "{\"username\":\"$USER\",\"password\":\"$PASS\"}" | j "['user']"
echo "== bad login (expect 401)"
curl -s -o /dev/null -w '%{http_code}\n' -X POST "$BASE/auth/login" -H 'Content-Type: application/json' \
  -d "{\"username\":\"$USER\",\"password\":\"wrong\"}"
echo "== feed without token (expect 401)"
curl -s -o /dev/null -w '%{http_code}\n' "$BASE/checkins"
echo "== post check-in at Georgia Tech"
ID=$(curl -sf -X POST "$BASE/checkins" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"note":"Smoke test from Klaus","mood":"great","lat":33.7771,"lon":-84.3963,"steps":4200}' | tee /dev/stderr | j "['id']")
echo; echo "== feed";   curl -sf "$BASE/checkins?limit=3" -H "Authorization: Bearer $TOKEN"; echo
echo "== me";       curl -sf "$BASE/me" -H "Authorization: Bearer $TOKEN"; echo
echo "== event";    curl -sf -X POST "$BASE/events" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"smoke_test","platform":"curl"}'; echo
echo "== delete check-in $ID (expect 204)"
curl -s -o /dev/null -w '%{http_code}\n' -X DELETE "$BASE/checkins/$ID" -H "Authorization: Bearer $TOKEN"
echo "== stats";    curl -sf "$BASE/stats"; echo
echo "ALL GOOD"
