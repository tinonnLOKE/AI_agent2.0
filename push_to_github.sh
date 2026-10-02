#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$DIR"

echo "=== Pushing AI Agent 2.0 to GitHub ==="

if ! gh auth status >/dev/null 2>&1; then
    echo "Error: Not authenticated with GitHub."
    exit 1
fi

USER_NAME=$(gh api user -q .login)
echo "Authenticated as GitHub user: $USER_NAME"

git push origin main
echo "=== Successfully pushed AI Agent 2.0 to GitHub: https://github.com/$USER_NAME/AI_performance ==="
