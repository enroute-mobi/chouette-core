#!/bin/sh -e

# Retrieve the commit image into an "origin" registry and push it in the deployment registry

ORIGIN_IMAGE_NAME="eu.gcr.io/$ORIGIN_GCLOUD_PROJECT/$BITBUCKET_REPO_SLUG:$BITBUCKET_COMMIT"
IMAGE_NAME="eu.gcr.io/$GCLOUD_PROJECT/$BITBUCKET_REPO_SLUG:$BITBUCKET_COMMIT"

docker pull "$ORIGIN_IMAGE_NAME"
docker tag "$ORIGIN_IMAGE_NAME" "$IMAGE_NAME"
docker push "$IMAGE_NAME"
