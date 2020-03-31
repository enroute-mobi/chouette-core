#!/bin/sh -ex

CLUSTER_OPTIONS=""

if [ -n "$GCLOUD_REGION" ]; then
    CLUSTER_OPTIONS="$CLUSTER_OPTIONS --region '$GCLOUD_REGION'"
fi
if [ -n "$GCLOUD_ZONE" ]; then
    CLUSTER_OPTIONS="$CLUSTER_OPTIONS --zone '$GCLOUD_ZONE'"
fi

gcloud container clusters get-credentials "$GCLOUD_CLUSTER" $CLUSTER_OPTIONS

IMAGE_NAME="eu.gcr.io/$GCLOUD_PROJECT/$BITBUCKET_REPO_SLUG:$BITBUCKET_COMMIT"
kubectl set image deployment --namespace="$GCLOUD_NAMESPACE" front front="$IMAGE_NAME" --record
kubectl set image deployment --namespace="$GCLOUD_NAMESPACE" async async="$IMAGE_NAME" --record
kubectl set image deployment --namespace="$GCLOUD_NAMESPACE" sync sync="$IMAGE_NAME" --record
