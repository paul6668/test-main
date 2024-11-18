#!/bin/bash

# Variables
NAMESPACE="<namespace>" # Replace with your namespace or use "default"
NEW_MIN_REPLICAS=2      # Desired minimum replicas
NEW_MAX_REPLICAS=10     # Desired maximum replicas

# Loop through all HPAs in the namespace
for hpa in $(kubectl get hpa -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
do
  echo "Patching HPA: $hpa in namespace: $NAMESPACE"
  
  kubectl patch hpa $hpa -n $NAMESPACE \
    --type='merge' \
    -p "{\"spec\":{\"minReplicas\":$NEW_MIN_REPLICAS,\"maxReplicas\":$NEW_MAX_REPLICAS}}"
    
  if [ $? -eq 0 ]; then
    echo "Successfully patched $hpa"
  else
    echo "Failed to patch $hpa"
  fi
done
