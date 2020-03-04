#!/bin/sh -e

gcloud container clusters get-credentials "$GCLOUD_CLUSTER" --zone "$GCLOUD_ZONE"

IMAGE_NAME="eu.gcr.io/$GCLOUD_PROJECT/$BITBUCKET_REPO_SLUG:$BITBUCKET_COMMIT"
kubectl set image deployment --namespace="$GCLOUD_NAMESPACE" front front="$IMAGE_NAME" --record
kubectl set image deployment --namespace="$GCLOUD_NAMESPACE" async async="$IMAGE_NAME" --record
kubectl set image deployment --namespace="$GCLOUD_NAMESPACE" sync sync="$IMAGE_NAME" --record
