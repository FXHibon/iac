#!/bin/bash
set -e

# Get the absolute path of the script's directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ANSIBLE_DIR="$PROJECT_ROOT/infra/ansible"

# Parse arguments
DRY_RUN=false
BASE_COMMIT=""

for arg in "$@"; do
    if [ "$arg" == "--dry-run" ]; then
        DRY_RUN=true
    elif [ -z "$BASE_COMMIT" ]; then
        BASE_COMMIT="$arg"
    fi
done

# Base commit selection logic
if [ -n "$BASE_COMMIT" ]; then
    echo "Comparing against specified commit: $BASE_COMMIT"
elif [ -n "$GITHUB_BASE_REF" ]; then
    # We are in a GitHub Action pull request context
    BASE_COMMIT="origin/$GITHUB_BASE_REF"
    echo "GitHub Actions context: Comparing against PR base branch '$BASE_COMMIT'"
elif [ -n "$GITHUB_EVENT_BEFORE" ] && [ "$GITHUB_EVENT_BEFORE" != "0000000000000000000000000000000000000000" ]; then
    # We are in a GitHub Action push/merge context
    BASE_COMMIT="$GITHUB_EVENT_BEFORE"
    echo "GitHub Actions context: Comparing against commit before push '$BASE_COMMIT'"
elif git rev-parse --verify deployed >/dev/null 2>&1; then
    BASE_COMMIT="deployed"
    echo "Comparing against git tag 'deployed' ($(git rev-parse --short deployed))"
else
    # Fallback to HEAD~1
    if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
        BASE_COMMIT="HEAD~1"
        echo "Git tag 'deployed' not found. Falling back to comparing against HEAD~1 ($(git rev-parse --short HEAD~1))"
    else
        echo "Error: Could not determine base commit. Git tag 'deployed' does not exist and there is no HEAD~1."
        echo "If this is the first run, you can initialize the deployed tag at your current commit using:"
        echo "  git tag deployed HEAD"
        exit 1
    fi
fi

if [ "$DRY_RUN" = true ]; then
    echo "--- DRY RUN MODE ---"
fi

# Get list of changed files
CHANGED_FILES=$(git diff --name-only "$BASE_COMMIT" HEAD)

if [ -z "$CHANGED_FILES" ]; then
    echo "No files have changed since $BASE_COMMIT."
    exit 0
fi

echo "Changed files since $BASE_COMMIT:"
echo "$CHANGED_FILES" | sed 's/^/  /'
echo ""

# Declare array to track tags to deploy
tags_to_deploy=()
deploy_all=false

# Map changed files to deploy tags
while read -r file; do
    [ -z "$file" ] && continue
    
    if [[ "$file" =~ ^deployments/vps/([^/]+)/ ]]; then
        app_name="${BASH_REMATCH[1]}"
        # Known VPS apps
        if [[ "$app_name" =~ ^(fresh-fridge|fxhibon-fr|monitoring|poc-cms|running-pace-calculator|square-collage-maker|stanne|satisfactory|traefik)$ ]]; then
            tags_to_deploy+=("$app_name")
        else
            echo "Unknown VPS application directory: $app_name (skipping)"
        fi
    elif [[ "$file" =~ ^deployments/rp5/ ]]; then
        tags_to_deploy+=("rp5")
    elif [[ "$file" =~ ^infra/ansible/playbook.yml ]] || [[ "$file" =~ ^infra/ansible/secrets.enc.yaml ]] || [[ "$file" =~ ^infra/ansible/ansible.cfg ]] || [[ "$file" =~ ^Taskfile.yml ]]; then
        # Core infrastructure files changed - trigger full deploy
        deploy_all=true
    fi
done <<< "$CHANGED_FILES"

# Deduplicate tags
if [ ${#tags_to_deploy[@]} -gt 0 ]; then
    unique_tags=($(echo "${tags_to_deploy[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
else
    unique_tags=()
fi

# Determine deploy actions
if [ "$deploy_all" = true ]; then
    echo "Core configuration changes detected (e.g. playbook, secrets, or Taskfile)."
    echo "Plan: Run full deployment (deploy-all)."
    
    if [ "$DRY_RUN" = false ]; then
        echo "Executing: cd $ANSIBLE_DIR && ./deploy.sh"
        cd "$ANSIBLE_DIR"
        ./deploy.sh
        cd "$PROJECT_ROOT"
        
        # Update tag
        git tag -f deployed HEAD
        echo "Git tag 'deployed' updated to HEAD."
        if git remote | grep -q "^origin$"; then
            echo "Pushing 'deployed' tag to origin..."
            git push origin deployed --force >/dev/null 2>&1 || echo "Warning: Could not push tag to origin (ignoring)."
        fi
    else
        echo "[DRY RUN] Would run: cd $ANSIBLE_DIR && ./deploy.sh"
    fi
elif [ ${#unique_tags[@]} -gt 0 ]; then
    echo "Plan: Deploy the following updated stacks/apps:"
    for tag in "${unique_tags[@]}"; do
        echo "  - $tag"
    done
    
    if [ "$DRY_RUN" = false ]; then
        cd "$ANSIBLE_DIR"
        for tag in "${unique_tags[@]}"; do
            echo ""
            echo "================================================================================"
            echo "Deploying application: $tag"
            echo "================================================================================"
            ./deploy.sh --tags "$tag"
        done
        cd "$PROJECT_ROOT"
        echo ""
        echo "All applications deployed successfully."
        
        # Update tag
        git tag -f deployed HEAD
        echo "Git tag 'deployed' updated to HEAD."
        if git remote | grep -q "^origin$"; then
            echo "Pushing 'deployed' tag to origin..."
            git push origin deployed --force >/dev/null 2>&1 || echo "Warning: Could not push tag to origin (ignoring)."
        fi
    else
        echo ""
        for tag in "${unique_tags[@]}"; do
            echo "[DRY RUN] Would run: cd $ANSIBLE_DIR && ./deploy.sh --tags $tag"
        done
    fi
else
    echo "No deployable applications or services were modified in this change."
    # Update tag anyway to mark these commits as handled
    if [ "$DRY_RUN" = false ]; then
        git tag -f deployed HEAD
        echo "Git tag 'deployed' updated to HEAD."
        if git remote | grep -q "^origin$"; then
            echo "Pushing 'deployed' tag to origin..."
            git push origin deployed --force >/dev/null 2>&1 || echo "Warning: Could not push tag to origin (ignoring)."
        fi
    else
        echo "[DRY RUN] Would update tag 'deployed' to HEAD."
    fi
fi
