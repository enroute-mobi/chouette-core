#!/bin/sh -e

# remove the Gemfile freeze for bundle outdated
bundle config set --local deployment 'false'

export BUMMR_TEST="bundle exec rake ci"
export BUMMR_HEADLESS="true"

branch_name="gems-update-$BITBUCKET_BUILD_NUMBER"
echo "Create branch '$branch_name"
git checkout -b "$branch_name"
bundle exec bummr update
git push

pull_request_name="Gems update Week $(date "+%W %Y")"

echo "Create Pull Request '$pull_request_name'"

json_request=$(cat <<EOF
{
  "title": "$pull_request_name",
  "source": {
    "branch": {
      "name": "$branch_name"
    }
  }
}
EOF
)

curl -q "https://api.bitbucket.org/2.0/repositories/$BITBUCKET_REPO_FULL_NAME/pullrequests" \
  -u "$BITBUCKET_USERNAME:$BITBUCKET_APP_PASSWORD" \
  --header 'Content-Type: application/json' \
  --data "$json_request"
