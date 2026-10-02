#!/usr/bin/env bash
set -e

echo "=== Pushing AI_harness and AI_performance to GitHub ==="

# 1. Verify GitHub CLI authentication
if ! gh auth status >/dev/null 2>&1; then
    echo "Error: Not authenticated with GitHub. Please authenticate first via 'gh auth login' or token."
    exit 1
fi

USER_NAME=$(gh api user -q .login)
echo "Authenticated as GitHub user: $USER_NAME"

# 2. Push AI_harness
echo "[1/4] Creating and pushing AI_harness repository..."
cd /home/df/AI_harness
if [ ! -d ".git" ]; then
    git init -b main
    git config user.name "$USER_NAME"
    git add .
    git commit -m "feat: complete AI Harness web app with TinyLlama, Qwen3, Gemma4"
fi

if ! gh repo view "$USER_NAME/AI_harness" >/dev/null 2>&1; then
    gh repo create "$USER_NAME/AI_harness" --public --source=. --remote=origin --push
else
    git remote remove origin 2>/dev/null || true
    git remote add origin "https://github.com/$USER_NAME/AI_harness.git"
    git push -u origin main
fi

# 3. Setup AI_performance with AI_harness as submodule
echo "[2/4] Setting up AI_performance with submodule..."
cd /home/df/AI_performance
if [ ! -d ".git" ]; then
    git init -b main
    git config user.name "$USER_NAME"
fi

# If AI_harness is currently a symlink, replace it with submodule
if [ -L "AI_harness" ]; then
    rm AI_harness
fi

if [ ! -f ".gitmodules" ] || ! grep -q "AI_harness" .gitmodules 2>/dev/null; then
    git submodule add "https://github.com/$USER_NAME/AI_harness.git" AI_harness
fi

# 4. Commit AI_performance
echo "[3/4] Committing AI_performance..."
git add .
git commit -m "feat: setup AI_performance with OVMS configs, Gemma 4, Qwen3, TinyLlama and AI_harness submodule" || true

# 5. Create & Push AI_performance
echo "[4/4] Creating and pushing AI_performance repository..."
if ! gh repo view "$USER_NAME/AI_performance" >/dev/null 2>&1; then
    gh repo create "$USER_NAME/AI_performance" --public --source=. --remote=origin --push
else
    git remote remove origin 2>/dev/null || true
    git remote add origin "https://github.com/$USER_NAME/AI_performance.git"
    git push -u origin main
fi

echo "=== All repositories successfully pushed to GitHub! ==="
echo "AI_harness:     https://github.com/$USER_NAME/AI_harness"
echo "AI_performance: https://github.com/$USER_NAME/AI_performance"
