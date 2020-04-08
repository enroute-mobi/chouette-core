#!/bin/sh -ex

CLUSTER_OPTIONS=""

if [ -n "$GCLOUD_REGION" ]; then
    CLUSTER_OPTIONS="$CLUSTER_OPTIONS --region $GCLOUD_REGION"
fi
if [ -n "$GCLOUD_ZONE" ]; then
    CLUSTER_OPTIONS="$CLUSTER_OPTIONS --zone $GCLOUD_ZONE"
fi

gcloud container clusters get-credentials "$GCLOUD_CLUSTER" $CLUSTER_OPTIONS

IMAGE_NAME="eu.gcr.io/$GCLOUD_PROJECT/$BITBUCKET_REPO_SLUG:$BITBUCKET_COMMIT"

# Run migrations

MIGRATE_JOB_FILE=$(mktemp --suffix=.yaml)
cat > $MIGRATE_JOB_FILE <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: migrate
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: migrate
        image: $IMAGE_NAME
        args: ['migrate-and-seed']
        envFrom:
          - configMapRef:
              name: chouette-config
          - secretRef:
              name: chouette-secrets
EOF

kubectl --namespace="$GCLOUD_NAMESPACE" create -f $MIGRATE_JOB_FILE
kubectl --namespace="$GCLOUD_NAMESPACE" wait --for=condition=complete --timeout=600s job/migrate
kubectl --namespace="$GCLOUD_NAMESPACE" logs job/migrate
kubectl --namespace="$GCLOUD_NAMESPACE" delete job migrate

# Update containers image

kubectl set image deployment --namespace="$GCLOUD_NAMESPACE" front front="$IMAGE_NAME" --record
kubectl set image deployment --namespace="$GCLOUD_NAMESPACE" async async="$IMAGE_NAME" --record
kubectl set image deployment --namespace="$GCLOUD_NAMESPACE" sync sync="$IMAGE_NAME" --record
