#!/usr/bin/env bash
# End-to-end smoke test for the Quiet Spots API.
# Usage: bash scripts/smoke.sh [base_url]   (default http://localhost:8787)
set -euo pipefail
BASE="${1:-http://localhost:8787}"
USER="smoke_$RANDOM"
PASS="password123"
# Build JSON in a variable: a literal {"a":1,"b":2} inside "$(...)" gets split by bash brace expansion.
CREDS="{\"username\":\"$USER\",\"password\":\"$PASS\"}"
WRONG="{\"username\":\"$USER\",\"password\":\"nope\"}"
j() { python3 -c "import sys,json; d=json.load(sys.stdin); print(eval('d'+sys.argv[1]))" "$1"; }
code() { curl -s -o /dev/null -w '%{http_code}' "$@"; }
expect() { [ $# -eq 2 ] || { echo "  FAIL: expect() got $# args: $*"; exit 1; }; [ "$1" = "$2" ] && echo "  ok ($1)" || { echo "  FAIL: expected $2, got $1"; exit 1; }; }

echo "== health";                 curl -sf "$BASE/health"; echo
echo "== dashboard HTML";          expect "$(code "$BASE/")" 200
echo "== spots list";              curl -sf "$BASE/spots" | j "[0]['name']"
echo "== register $USER"
TOKEN=$(curl -sf -X POST "$BASE/auth/register" -H 'Content-Type: application/json' \
  -d "$CREDS" | j "['token']")
echo "== duplicate register";      expect "$(code -X POST "$BASE/auth/register" -H 'Content-Type: application/json' -d "$CREDS")" 409
echo "== login";                   curl -sf -X POST "$BASE/auth/login" -H 'Content-Type: application/json' -d "$CREDS" | j "['user']"
echo "== wrong password";          expect "$(code -X POST "$BASE/auth/login" -H 'Content-Type: application/json' -d "$WRONG")" 401
echo "== report without token";    expect "$(code -X POST "$BASE/spots/1/reports" -H 'Content-Type: application/json' -d '{"db":40}')" 401
echo "== report with bad db";      expect "$(code -X POST "$BASE/spots/1/reports" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{"db":500}')" 400
echo "== report at Crosland 4F"
ID=$(curl -sf -X POST "$BASE/spots/1/reports" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"db":38.4,"vote":"quiet","note":"Smoke test","lat":33.7744,"lon":-84.3957}' | tee /dev/stderr | j "['id']")
echo; echo "== spot detail (level + weather)"
curl -sf "$BASE/spots/1" -H "Authorization: Bearer $TOKEN" | python3 -c "import sys,json; d=json.load(sys.stdin); print({k:d[k] for k in ('name','avg_db','level','recent_reports','weather')}, 'mine=', d['reports'][0]['mine'])"
echo "== me";                      curl -sf "$BASE/me" -H "Authorization: Bearer $TOKEN" | j "['reports']"
echo "== event";                   curl -sf -X POST "$BASE/events" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{"name":"smoke_test","platform":"curl"}'; echo
echo "== delete report $ID";       expect "$(code -X DELETE "$BASE/reports/$ID" -H "Authorization: Bearer $TOKEN")" 204
echo "== delete again";            expect "$(code -X DELETE "$BASE/reports/$ID" -H "Authorization: Bearer $TOKEN")" 404
echo "== stats";                   curl -sf "$BASE/stats" | j "['events']"
echo "ALL GOOD"
