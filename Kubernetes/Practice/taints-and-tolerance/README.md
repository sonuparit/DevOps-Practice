# Kubernetes Taints & Tolerations

This folder contains my practice material and examples for Kubernetes **taints** and **tolerations**, the mechanism used to control where pods can schedule (or not) on a cluster.

- **Taints** are applied to nodes and repel pods.
- **Tolerations** are applied to pods and allow them to tolerate (or ignore) taints.

> ✅ Goal: use taints + tolerations to isolate specialized node pools, implement soft anti-affinity, and protect critical nodes from noisy workloads.

---

## 1) Core concepts (quick recap)

### What is a taint?
A taint is a node-level rule that tells the scheduler: *“don’t place pods here unless they tolerate this.”* A taint is defined by three fields:

- `key`: a string name (e.g., `dedicated`, `workload`, `maintenance`)
- `value`: an optional string value (e.g., `database`, `true`)
- `effect`: one of:
  - `NoSchedule` – avoid scheduling new pods that don’t tolerate it
  - `PreferNoSchedule` – try to avoid scheduling, but may still schedule if needed
  - `NoExecute` – evict existing pods and prevent new ones from scheduling

### What is a toleration?
A toleration is a pod-level declaration that says: *“I can run on nodes that have this taint.”*  
Tolerations are specified under `spec.tolerations` in any pod spec (Deployment, StatefulSet, DaemonSet, etc.).

---

## 2) Why (and when) you need taints + tolerations

✅ **Node isolation** – Dedicated node pools (e.g., GPU, storage, security) can be protected from general workloads.

✅ **Soft reservation** – Use `PreferNoSchedule` to keep nodes mostly free but allow fallbacks when capacity is tight.

✅ **Maintenance & upgrades** – Use `NoExecute` to drain nodes quickly during rolling upgrades or decommissioning.

✅ **Critical pod placement** – Ensure system pods (monitoring, logging, networking) can run on nodes that are otherwise tainted.

---

## 3) What they do (behaviors explained)

### NoSchedule (hard scheduling barrier)
- Pods without a matching toleration will **never** schedule onto the tainted node.

### PreferNoSchedule (soft scheduling barrier)
- The scheduler will **try** to avoid the node, but it can still place pods when there are no better options.

### NoExecute (eviction + scheduling barrier)
- Pods without a matching toleration will be **evicted immediately**, and won’t be allowed to reschedule on that node.
- Pods with a matching toleration can optionally stay for a limited time (`tolerationSeconds`).

---

## 4) Life cycle / when this matters

1. **Node is tainted** (e.g., `kubectl taint nodes node01 dedicated=database:NoSchedule`)
2. **Existing pods** without matching tolerations are unaffected (for NoSchedule/PreferNoSchedule) but cannot be rescheduled there.
3. **New pods** without matching tolerations will not be scheduled (or will avoid the node).
4. For `NoExecute` taints, existing non-tolerating pods are **evicted**.
5. Pods with matching tolerations can be scheduled and/or remain running.

> 🔎 Note: Taints do not “push” pods off a node in the case of `NoSchedule`; they only prevent new scheduling.

---

## 5) Production-ready reference (examples)

### A) Apply taints (node-side)

```bash
# Dedicated node pool for database workloads (hard block)
kubectl taint node <node-name> dedicated=database:NoSchedule

# Reserve nodes for maintenance/backfill (soft preference)
kubectl taint node <node-name> maintenance=true:PreferNoSchedule

# Temporarily drain/upgrade a node (evict pods)
kubectl taint node <node-name> upgrade=planned:NoExecute
```

> ⚠️ Tip: Avoid applying taints to control plane nodes unless you know what you’re doing (system pods may need tolerations).

### B) Pod tolerations (pod-side)

Here’s a production-like Pod spec showing common tolerations:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example-taint-toleration
  labels:
    app: example
spec:
  containers:
  - name: app
    image: nginx:stable
    ports:
    - containerPort: 80
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "database"
    effect: "NoSchedule"

  - key: "maintenance"
    operator: "Equal"
    value: "true"
    effect: "PreferNoSchedule"

  - key: "upgrade"
    operator: "Equal"
    value: "planned"
    effect: "NoExecute"
    tolerationSeconds: 3600
```

---

## 6) Important considerations (production hints)

### ✅ Don’t overuse broad tolerations
- Avoid `key: ""` or `operator: "Exists"` unless you intentionally want to tolerate all taints.

### ✅ Pair with node selectors / node affinity
- Use `nodeSelector` / `nodeAffinity` to target the correct node pool and combine it with taints for stronger guarantees.

### ✅ Track taint/toleration drift
- Over time, clusters accrue taints and tolerations. Periodically review taints and the deployments that rely on them.

### ✅ Document your taint strategy
- Keep a short reference (like this README) and document why a taint exists, who owns it, and when it can be removed.

### ✅ Use taints for “safety guards”
- Taint nodes that should never take general workloads (e.g., dedicated storage nodes, GPU nodes, security-isolated nodes).

---

## 7) Useful commands (quick lookup)

```bash
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.taints}{"\n"}{end}'

kubectl describe node <node-name> # shows taints

kubectl get pod <pod> -o yaml | yq '.spec.tolerations'  # view tolerations
```

---

Happy tainting! Keep your taints intentional, your tolerations narrow, and your clusters predictable.
