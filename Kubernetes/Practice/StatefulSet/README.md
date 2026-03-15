# StatefulSet Practice

This folder contains a StatefulSet practice, including a headless service, a StatefulSet definition, and the commands used to manage rollbacks.

## 🧩 What’s in this folder

- `stateful-set.yml` — defines a `StatefulSet` named `webapp` with 3 replicas and a `volumeClaimTemplates` block (per-pod persistent storage).
- `service.yml` — defines a **headless Service** (clusterIP: None) used by the StatefulSet.
- `rollbacks-command.sh` — a collection of commands to view revision history and roll back a StatefulSet using Kubernetes `rollout` and `ControllerRevision` objects.

---

## ✅ Key StatefulSet Concepts.

### 1) StatefulSet has its own **VolumeClaimTemplates** (persistent storage per replica)
- The `volumeClaimTemplates` section in `stateful-set.yml` creates a **PersistentVolumeClaim (PVC)** for each replica.
- Each replica (pod) gets its own PVC named like `my-volume-webapp-0`, `my-volume-webapp-1`, etc.
- This ensures **stable storage** that survives pod restarts and rescheduling.

> 💡 Important: StatefulSets do **not** share the same PVC across replicas. Each replica gets its own volume.

### 1.1) When you need PersistentVolumes (PV)
- How to Check if You Need to Create a PV  
- Run this command:
```bash
kubectl get storageclass
```

If you see a class marked as (default), you usually don't need to create PVs manually.
If the list is empty, you must manually create a PV for every replica in your StatefulSet.


### 2) Single Headless Service for all StatefulSet replicas
- The `Service` in `service.yml` is a **headless Service** because `clusterIP: None`.
- It allows StatefulSet pods to have stable DNS entries like:
  - `webapp-0.nginx.<namespace>.svc.cluster.local`
  - `webapp-1.nginx.<namespace>.svc.cluster.local`
- Headless services are used by StatefulSets to provide stable network identities to each pod.

### 3) Services are linked to StatefulSets via **labels/selectors**
- The Service selects pods using `selector: app: nginx`.
- The StatefulSet pod template must match that selector using the same label (`app: nginx`).
- In `stateful-set.yml`:
  - `.spec.selector.matchLabels` must match `.spec.template.metadata.labels`.
  - If the selectors don’t match, the StatefulSet will be invalid and won’t create pods.

> ⚠️ Common gotcha: selectors are immutable once the StatefulSet is created. If they mismatch, you must delete and recreate the StatefulSet.

---

## 🔄 Rollbacks (using `rollbacks-command.sh`)

The repository includes `rollbacks-command.sh`, which is a set of commands (not an executable script) you can use to manage StatefulSet rollbacks.

### View revision history
```bash
kubectl rollout history statefulset/webapp
```

### Rollback to a specific revision
```bash
kubectl rollout undo statefulset/webapp --to-revision=3
```

### Inspect ControllerRevisions (StatefulSet history objects)
```bash
kubectl get controllerrevision
kubectl get controllerrevisions -l app.kubernetes.io/name=webapp
kubectl get controllerrevision/webapp-3 -o yaml
```

> ✅ Note: Kubernetes automatically creates `ControllerRevision` objects each time you update the StatefulSet. These store the previous configurations and let you roll back safely.

---

## 🚨 Important StatefulSet gotchas

- **Order matters:** StatefulSets create and delete pods in a fixed order (0 → N). Deleting a pod may not immediately recreate it until the earlier pod is Ready.
- **Scaling down:** When you scale down, the highest ordinal pod is removed first and **its PVC is not deleted**. You must delete leftover PVCs manually if you want to reclaim storage.
- **Pod names are stable:** Pods are named like `webapp-0`, `webapp-1`. If you delete a pod, it’s recreated with the same name (and same persistent volume).
- **Selectors must match:** `.spec.selector.matchLabels` must match `.spec.template.metadata.labels`. This is a strict requirement for StatefulSets.
- **Headless service is required**: StatefulSets rely on a headless service (`clusterIP: None`) to provide stable DNS.

---

## 🧪 How to apply these manifests

```bash
kubectl apply -f service.yml
kubectl apply -f stateful-set.yml
```

## ✅ Verify

```bash
kubectl get statefulset webapp -o wide
kubectl get pods -l app=nginx
kubectl get pvc
```

---

Happy StatefulSet practicing!
