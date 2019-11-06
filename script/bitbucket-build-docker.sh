#!/bin/sh

export IMAGE_NAME="eu.gcr.io/$GCLOUD_PROJECT/$BITBUCKET_REPO_SLUG:$BITBUCKET_COMMIT"
echo "$GCLOUD_API_KEYFILE" | base64 -d > ~/.gcloud-api-key.json
gcloud auth activate-service-account --key-file ~/.gcloud-api-key.json
gcloud config set project "$GCLOUD_PROJECT"
gcloud auth configure-docker --quiet

# Build image
docker build . -t "$IMAGE_NAME" --build-arg VERSION="build-$BITBUCKET_BUILD_NUMBER"

# Publish image
docker push "$IMAGE_NAME"
