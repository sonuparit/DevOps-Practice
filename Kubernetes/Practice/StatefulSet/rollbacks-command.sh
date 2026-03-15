# Not a bash script, but a set of commands to manage rollbacks for a StatefulSet in Kubernetes.
# You can revert to a previous configuration using:

# View revision history
kubectl rollout history statefulset/webapp

# Rollback to a specific revision
kubectl rollout undo statefulset/webapp --to-revision=3


# ControllerRevisions are automatically created by Kubernetes
# to store the history of changes for StatefulSets.
# Each time you update a StatefulSet, a new ControllerRevision
# is created to capture the state of the StatefulSet at that point in time.
# This allows you to roll back to any previous revision if needed.
kubectl get controllerrevision

# To view associated ControllerRevisions:

# List all revisions for the StatefulSet
kubectl get controllerrevisions -l app.kubernetes.io/name=webapp

# View detailed configuration of a specific revision
kubectl get controllerrevision/webapp-3 -o yaml