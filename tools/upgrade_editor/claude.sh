#!/usr/bin/env bash
readonly CLAUDE_TOOLS="Read,Edit,Write,Glob,Grep"
readonly CLAUDE_DENIED="Bash,WebFetch,WebSearch,NotebookEdit"

run_claude() {
  local prompt_file="$1"
  local -a command
  read -r -a command <<< "${CLAUDE_CMD:-claude}"
  "${command[@]}" -p \
    --tools "$CLAUDE_TOOLS" \
    --allowedTools "$CLAUDE_TOOLS" \
    --disallowedTools "$CLAUDE_DENIED" \
    --permission-mode dontAsk \
    --strict-mcp-config < "$prompt_file"
}
