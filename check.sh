#!/usr/bin/env bash
# Runs fleetlint: annotations and summary first, then the gate.
set -euo pipefail

report="$RUNNER_TEMP/fleetlint.json"
fleetlint -C "$INPUT_PATH" check --format json --fail-on never >"$report"

annotations=$INPUT_ANNOTATIONS
if [ "$annotations" = auto ]; then
  # Gitea and Forgejo print workflow commands into the log instead of annotating.
  annotations=true
  if [ "${GITEA_ACTIONS:-}" = true ] || [ "${FORGEJO_ACTIONS:-}" = true ]; then
    annotations=false
  fi
fi
if [ "$annotations" = true ]; then
  if command -v jq >/dev/null; then
    prefix=""
    [ "$INPUT_PATH" != . ] && prefix="${INPUT_PATH%/}/"
    # Workflow commands need %, CR and LF escaped, and properties also : and ,.
    jq -r --arg prefix "$prefix" '
      def msg: gsub("%"; "%25") | gsub("\r"; "%0D") | gsub("\n"; "%0A");
      def prop: msg | gsub(":"; "%3A") | gsub(","; "%2C");
      .results[] | select(.status == "fail") | . as $r
      | (if (.findings // []) | length > 0 then .findings[] else {message: $r.rule.title} end)
      | ({"error": "error", "warning": "warning"}[$r.severity] // "notice") as $level
      | (if .path then "file=\(($prefix + .path) | prop)," + (if (.line // 0) > 0 then "line=\(.line)," else "" end) else "" end) as $where
      | "::\($level) \($where)title=\($r.rule.id | prop)::\(.message | msg)"
    ' "$report"
  else
    echo "::notice::jq is not installed; no annotations"
  fi
fi

if [ "$INPUT_SUMMARY" = true ] && [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  fleetlint -C "$INPUT_PATH" check --format markdown --fail-on never >>"$GITHUB_STEP_SUMMARY"
fi

if [ -n "$INPUT_SARIF_FILE" ]; then
  fleetlint -C "$INPUT_PATH" check --format sarif --fail-on never >"$INPUT_SARIF_FILE"
fi

fleetlint -C "$INPUT_PATH" check --fail-on "$INPUT_FAIL_ON" --color=false
