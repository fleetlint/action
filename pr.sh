#!/usr/bin/env bash
# Proposes changes as a pull request with the run's token: the onboarding
# configuration when the repository has none, else the mechanical fixes.
# Runs of pull requests and of other branches only check.
set -euo pipefail

case "$INPUT_EVENT" in
  pull_request*)
    echo "pr: a pull request run only checks"
    exit 0
    ;;
esac
if [ -n "$INPUT_DEFAULT_BRANCH" ] && [ "$INPUT_REF" != "$INPUT_DEFAULT_BRANCH" ]; then
  echo "pr: only runs of $INPUT_DEFAULT_BRANCH propose changes"
  exit 0
fi
if [ -z "${FLEETLINT_TOKEN:-}" ]; then
  echo "::error::pr: true needs a token (the token input, by default the run's github.token)"
  exit 1
fi
# The commit is the workflow's: the forge's own Actions user.
if [ "${FORGEJO_ACTIONS:-}" = true ]; then
  name=forgejo-actions email=noreply@forgejo.org
elif [ "${GITEA_ACTIONS:-}" = true ]; then
  name=gitea-actions email=teabot@gitea.io
else
  name="github-actions[bot]" email="41898282+github-actions[bot]@users.noreply.github.com"
fi
export GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-$name}"
export GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-$email}"
export GIT_COMMITTER_NAME="${GIT_COMMITTER_NAME:-$GIT_AUTHOR_NAME}"
export GIT_COMMITTER_EMAIL="${GIT_COMMITTER_EMAIL:-$GIT_AUTHOR_EMAIL}"

if [ -f "$INPUT_PATH/.fleetlint.yaml" ] || [ -f "$INPUT_PATH/fleetlint.yaml" ]; then
  fleetlint -C "$INPUT_PATH" fix --apply --pr | tee -a "${GITHUB_STEP_SUMMARY:-/dev/null}"
else
  fleetlint -C "$INPUT_PATH" init --pr | tee -a "${GITHUB_STEP_SUMMARY:-/dev/null}"
  echo "onboarding=true" >>"${GITHUB_OUTPUT:-/dev/null}"
fi
