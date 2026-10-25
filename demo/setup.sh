#!/usr/bin/env bash
#
# Builds a throwaway repo in /tmp/git-coauthors-demo for recording the README demo
# (see demo/git-coauthors.tape). Its history has commits from a small team, so
# git-coauthors discovers them from `git log`. There is no GitHub remote, so the
# gh discovery path is skipped.

set -euo pipefail

DEMO_DIR=/tmp/git-coauthors-demo
REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# Ignore personal git config (signing, aliases, hooks, templates) and pin dates
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_DATE='2026-01-01T12:00:00Z' GIT_COMMITTER_DATE='2026-01-01T12:00:00Z'

commit_as() {
  local name=$1 email=$2 message=$3
  echo "$message" >>CHANGELOG.md
  git add CHANGELOG.md
  GIT_AUTHOR_NAME=$name GIT_AUTHOR_EMAIL=$email GIT_COMMITTER_NAME=$name GIT_COMMITTER_EMAIL=$email \
    git commit -q -m "$message"
}

rm -rf "$DEMO_DIR"
mkdir -p "$DEMO_DIR/task-tracker"
cd "$DEMO_DIR/task-tracker"
git init -q -b main

commit_as 'Priya Sharma' 'priya.sharma@example.com' 'Initial commit'
commit_as 'Grace Liu' 'grace.liu@example.com' 'Add task model'
commit_as 'Rosa Fernandez' 'rosa.f@example.com' 'Add due dates'
commit_as 'Tanya Ivanova' 'tanya.ivanova@example.com' 'Add list command'
commit_as 'Olivia Reyes' 'olivia.reyes@example.com' 'Add tags'
commit_as 'Frank Nakamura' 'frank.n@example.com' 'Add JSON export'
commit_as 'Liam Foster' 'liam.foster@example.com' 'Fix sorting by priority'
commit_as 'Carol Johnson' 'carol.j@example.com' 'Add README'

# A staged change for the demo commit
echo 'Dark mode follows the system appearance.' >README.md
git add README.md

# Environment for the demo shell: same git isolation, and git commit opens nvim with the demo config
cat >"$DEMO_DIR/env.sh" <<ENV
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME='David Kim' GIT_AUTHOR_EMAIL='david.kim@example.com'
export GIT_COMMITTER_NAME='David Kim' GIT_COMMITTER_EMAIL='david.kim@example.com'
export GIT_EDITOR="nvim -u $REPO_DIR/demo/init.lua"
# Keep nvim's data dir (and the plugin's default handles file) inside the sandbox
export XDG_DATA_HOME=$DEMO_DIR/data
ENV
