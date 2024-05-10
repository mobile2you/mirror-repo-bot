#!/bin/bash
set -ex

ERROR_MESSAGES=()

for REPO_NAME in $SOURCE_REPOSITORIES; do

  # Clone repository from source workspace
  git clone --bare "https://$SOURCE_USERNAME:$SOURCE_PASSWORD@$SOURCE_WORKSPACE/$REPO_NAME.git"
  cd "$REPO_NAME.git"

  if [ "$FULL_MIRROR" = true ]; then
    # Mirror full repository to the target workspace
    if ! git push --mirror --force "https://$TARGET_USERNAME:$TARGET_PASSWORD@$TARGET_WORKSPACE/$REPO_NAME.git"; then
      ERROR_MESSAGES+=("$REPO_NAME - Failed to fully mirror repository to the target workspace")
    fi
  else
    # Mirror only specific branches to the target workspace
    for BRANCH in "${SPECIFIC_BRANCHES[@]}"; do
      if ! git push --force "https://$TARGET_USERNAME:$TARGET_PASSWORD@$TARGET_WORKSPACE/$REPO_NAME.git" "$BRANCH"; then
        ERROR_MESSAGES+=("$REPO_NAME - Failed to mirror branch $BRANCH to the target workspace")
      fi
    done
  fi

  cd ..
done

# Handling error messages
if [[ ${#ERROR_MESSAGES[@]} -gt 0 ]]; then
  ERROR_STRING=$(printf '%s\n' "${ERROR_MESSAGES[@]}" | awk '{print NR". "$0}')
  envman add --key ERROR_MESSAGE_OUTPUT --value "$ERROR_STRING"
  exit 1
else
  echo "Transfer complete!"
  exit 0
fi
