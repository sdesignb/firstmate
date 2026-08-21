#!/usr/bin/env bash
# The fleet-wide prohibited-model policy, and the single owner of which model
# ids it matches.
#
# The captain's standing constraint (AGENTS.md section 4) is that no agent, at
# any depth, runs on the fable model. It is measured, not stylistic: on
# 2026-08-20 a scout's parallel helper agents took the fable weekly window from
# 32% to 21% inside one session, and on 2026-08-21 the fable week reached 100%
# used while the all-models week still had 29% left.
#
# The policy REFUSES rather than substituting another model. A silent
# substitution would hide the misconfiguration that produced the fable value,
# which is the thing the captain wants reported.
#
# Public interface:
#   fm_model_policy_matched_token <model>
#     Print <model> and return 0 when it names a prohibited model; return 1
#     otherwise. Callers must resolve the model before invoking this policy.
#   fm_model_policy_check <model> <source>
#     Return 0 when <model> is permitted. Otherwise print the
#     refusal, naming the offending value AND <source>, and return 1.
#   fm_model_policy_source_label <source>
#     Render a known source token - flag, config/crew-dispatch.json,
#     config/secondmate-harness, raw-launch-command, task-metadata - as readable prose. Any other value
#     is passed through, so a call site can supply its own phrase. These tokens
#     are the same vocabulary bin/fm-spawn.sh records as model_source= in a
#     task's meta.
#
# Matching is bounded to the model name itself: `claude-fable-5`, `fable`, and
# `fable-mini` are prohibited, while an unrelated id that merely contains those
# letters (`affable-1`) is not. Add a second prohibited model here, never at a
# call site.

# Every route that can carry a model into a launch calls this; adding a new
# route means adding a call, not a second matcher.
fm_model_policy_matched_token() {
  local model=${1:-} lower
  lower=$(printf '%s' "$model" | tr '[:upper:]' '[:lower:]')
  [[ $lower =~ (^|[^a-z])fable([^a-z]|$) ]] || return 1
  printf '%s\n' "$model"
}

fm_model_policy_source_label() {
  case "${1:-}" in
    flag) printf '%s\n' 'the --model flag' ;;
    config/crew-dispatch.json) printf '%s\n' 'config/crew-dispatch.json' ;;
    config/secondmate-harness) printf '%s\n' 'the model token in config/secondmate-harness' ;;
    raw-launch-command) printf '%s\n' 'the raw launch command' ;;
    task-metadata) printf '%s\n' 'the task metadata' ;;
    '') printf '%s\n' 'an unnamed source' ;;
    *) printf '%s\n' "$1" ;;
  esac
}

fm_model_policy_check() {
  local model=${1:-} source=${2:-} offender
  offender=$(fm_model_policy_matched_token "$model") || return 0
  printf 'error: refusing to launch on the prohibited fable model %s, which came from %s.\n' \
    "'$offender'" "$(fm_model_policy_source_label "$source")" >&2
  printf '%s\n' \
    'The captain prohibits the fable model fleet-wide, and firstmate never silently substitutes another model for it. Correct that source and dispatch again.' >&2
  return 1
}
