#!/bin/sh -e

TAG=$1

# Tag image in registry with given label
IMAGE_NAME="eu.gcr.io/$GCLOUD_PROJECT/$BITBUCKET_REPO_SLUG:$BITBUCKET_COMMIT"
TAGGED_IMAGE_NAME="eu.gcr.io/$GCLOUD_PROJECT/$BITBUCKET_REPO_SLUG:$TAG"

echo "Tag $IMAGE_NAME as $TAGGED_IMAGE_NAME"

echo "$GCLOUD_API_KEYFILE" | base64 -d > ~/.gcloud-api-key.json
gcloud auth activate-service-account --key-file ~/.gcloud-api-key.json
gcloud config set project "$GCLOUD_PROJECT"
gcloud auth configure-docker --quiet

docker pull "$IMAGE_NAME"
docker tag "$IMAGE_NAME" "$TAGGED_IMAGE_NAME"
docker push "$TAGGED_IMAGE_NAME"
