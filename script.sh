#!/bin/bash

ORG="YOUR-ORG-NAME"
REPO_NAME=$(basename "$PWD")

gh secret set GH_TOKEN \
  --repo "${ORG}/${REPO_NAME}" \
  --body "${GH_PAT}"

# Set develop as the default branch
gh repo edit --default-branch develop

echo "🔐 Applying full branch protection..."
for BRANCH in main develop; do
  gh api \
    --method PUT \
    -H "Accept: application/vnd.github+json" \
    "/repos/${ORG}/${REPO_NAME}/branches/${BRANCH}/protection" \
    --input - <<EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["call-self / Quality Gate Checks"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "required_approving_review_count": 1,
    "require_code_owner_reviews": false,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "allow_deletions": false,
  "allow_force_pushes": false,
  "required_linear_history": true,
  "required_conversation_resolution": true,
  "lock_branch": false
}
EOF
done
echo "✅ Protection applied to main and develop branches."


echo "🧹 Enabling automatic branch deletion after merge..."
gh api \
  -X PATCH \
  -H "Accept: application/vnd.github+json" \
  /repos/${ORG}/${REPO_NAME} \
  -f delete_branch_on_merge=true


echo "⚙️ Setting Pull Request preferences (squash only)..."
gh api \
  --method PATCH \
  -H "Accept: application/vnd.github+json" \
  /repos/${ORG}/${REPO_NAME} \
  --input - <<EOF
{
  "allow_squash_merge": true,
  "allow_merge_commit": false,
  "allow_rebase_merge": false,
  "squash_merge_commit_title": "COMMIT_OR_PR_TITLE",
  "squash_merge_commit_message": "COMMIT_MESSAGES"
}
EOF

# --------------------------------------------------------------------------------

echo "🔐 Creating full ruleset for flow/*..."
JSON_PAYLOAD=$(cat <<EOF
{
  "name": "Protection for flow/*",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/flow/*"],
      "exclude": []
    }
  },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" }
  ],
  "bypass_actors": [
    {
      "actor_id": 5,
      "actor_type": "RepositoryRole",
      "bypass_mode": "always"
    }
  ]
}
EOF
)
echo "Creating/Updating Ruleset for ${ORG}/${REPO_NAME}..."
gh api --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/${ORG}/${REPO_NAME}/rulesets" \
  --input - <<< "$JSON_PAYLOAD"

# --------------------------------------------------------------------------------

echo "🔐 Creating full ruleset for hotfix/*..."
JSON_PAYLOAD=$(cat <<EOF
{
  "name": "Protection for hotfix/*",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/hotfix/*"],
      "exclude": []
    }
  },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" }
  ],
  "bypass_actors": [
    {
      "actor_id": 5,
      "actor_type": "RepositoryRole",
      "bypass_mode": "always"
    }
  ]
}
EOF
)
echo "Creating/Updating Ruleset for ${ORG}/${REPO_NAME}..."
gh api --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/${ORG}/${REPO_NAME}/rulesets" \
  --input - <<< "$JSON_PAYLOAD"

# --------------------------------------------------------------------------------

echo "🔐 Creating full ruleset for release/*..."
JSON_PAYLOAD=$(cat <<EOF
{
  "name": "Protection for release/*",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/release/*"],
      "exclude": []
    }
  },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" }
  ],
  "bypass_actors": [
    {
      "actor_id": 5,
      "actor_type": "RepositoryRole",
      "bypass_mode": "always"
    }
  ]
}
EOF
)
echo "Creating/Updating Ruleset for ${ORG}/${REPO_NAME}..."
gh api --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/${ORG}/${REPO_NAME}/rulesets" \
  --input - <<< "$JSON_PAYLOAD"

# --------------------------------------------------------------------------------

echo "🔐 Creating full ruleset for feature/*..."
JSON_PAYLOAD=$(cat <<EOF
{
  "name": "Protection for feature/*",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/feature/*"],
      "exclude": []
    }
  },
  "rules": [
    { "type": "non_fast_forward" }
  ]
}
EOF
)
echo "Creating/Updating Ruleset for ${ORG}/${REPO_NAME}..."
gh api --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/${ORG}/${REPO_NAME}/rulesets" \
  --input - <<< "$JSON_PAYLOAD"

# --------------------------------------------------------------------------------

echo "✅ Repository '$REPO_NAME' published with develop as default."
rm -- "$0"
