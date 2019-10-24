#!/bin/sh

set -xe

if ! git remote --verbose | grep "^upstream" > /dev/null; then
    echo "* Add upstream remote"
    git remote add upstream git@bitbucket.org:enroute-mobi/chouette-core.git
fi

TAG=ci-master
git tag -d $TAG || true

echo "* Fetch upstream tags"
git fetch upstream --tags > /dev/null

TAG_COMMIT=$(git rev-parse $TAG)
echo "* Tag $TAG is $TAG_COMMIT"

# Ignore some files like bitbucket pipelines config
NOT_MERGED_FILES='bitbucket-pipelines.yml'

# To avoid problem in the merge, retrieve the chouette-core versions
for file in $NOT_MERGED_FILES; do
    git show "$TAG_COMMIT:$file" > $file
done

# But we need to commit :'(
git commit -m "Revert unmerged files" $NOT_MERGED_FILES

echo "* Merge without commit"
git merge --no-commit $TAG

echo "* Restore not merged files ($NOT_MERGED_FILES)"
git checkout HEAD^ $NOT_MERGED_FILES
git add $NOT_MERGED_FILES

echo "* Commit merge"
git commit --no-edit -a

echo "* Push on master"
[ "$DRY_RUN" = "true" ] && exit 0
git push origin master
