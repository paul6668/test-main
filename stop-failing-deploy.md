```
#!/bin/bash

# Threshold for restarts
RESTART_THRESHOLD=200

# Get all pods in the cluster
kubectl get pods --all-namespaces -o json | jq -r \
  '.items[] | select(.status.containerStatuses[].restartCount > $ENV.RESTART_THRESHOLD) | 
   "\(.metadata.namespace) \(.metadata.ownerReferences[] | select(.kind=="ReplicaSet") | .name)"' |
while read -r namespace replicaset; do
  # Get the deployment name from the replicaset
  deployment=$(kubectl get rs "$replicaset" -n "$namespace" -o jsonpath='{.metadata.ownerReferences[0].name}')

  # Scale down the deployment to 0
  kubectl scale deployment "$deployment" -n "$namespace" --replicas=0

  echo "Scaled down deployment $deployment in namespace $namespace due to restart count exceeding $RESTART_THRESHOLD"
done
```
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: check-restart-count
  namespace: default
data:
  check-restart-count.sh: |
    #!/bin/bash
    RESTART_THRESHOLD=200
    kubectl get pods --all-namespaces -o json | jq -r \
      '.items[] | select(.status.containerStatuses[].restartCount > $ENV.RESTART_THRESHOLD) | 
       "\(.metadata.namespace) \(.metadata.ownerReferences[] | select(.kind=="ReplicaSet") | .name)"' |
    while read -r namespace replicaset; do
      deployment=$(kubectl get rs "$replicaset" -n "$namespace" -o jsonpath='{.metadata.ownerReferences[0].name}')
      kubectl scale deployment "$deployment" -n "$namespace" --replicas=0
      echo "Scaled down deployment $deployment in namespace $namespace due to restart count exceeding $RESTART_THRESHOLD"
    done
```
```
apiVersion: batch/v1
kind: CronJob
metadata:
  name: stop-restarting-deployments
  namespace: default
spec:
  schedule: "0 * * * *"  # Every hour
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: check-restart-count
              image: bitnami/kubectl:latest  # Using a lightweight kubectl image
              command: ["/bin/bash", "/scripts/check-restart-count.sh"]
              volumeMounts:
                - name: script
                  mountPath: /scripts
          restartPolicy: OnFailure
          volumes:
            - name: script
              configMap:
                name: check-restart-count
```
