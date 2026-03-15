# Kubernetes Probes Practice

This folder contains examples and practice material for Kubernetes **probes** (readiness, liveness, and startup probes). Probes are how Kubernetes checks the health and readiness of your containers and decides whether to start traffic, restart a container, or consider it healthy.

---

## 1) Introduction

Kubernetes probes are small checks run by the kubelet against a container. They can:

- Verify a container is up and running (liveness)
- Verify a container is ready to accept traffic (readiness)
- Ensure initialization has completed (startup)

Probes allow Kubernetes to treat a container as an orchestrated, self-healing unit rather than a "black box."

---

## 2) Why we need probes

Probes provide **reliable, declarative health checking** so Kubernetes can make the right decisions:

- **Avoid routing traffic to a container that isn’t ready yet** (readiness probe)
- **Restart containers that are alive but unhealthy** (liveness probe)
- **Avoid premature failure detection during slow startups** (startup probe)

Without probes, Kubernetes assumes a running container is healthy and ready, which can cause issues such as:

- Sending traffic to an app before it has fully initialized
- Failing a container that is in the middle of a normal long startup
- Not detecting a stuck or crashed process inside the container

---

## 3) What probes do

Kubernetes supports three probe types, each serving a different purpose:

### ✅ Liveness Probe
- Purpose: Detects when a container is *alive* but in a bad state (e.g., deadlocked, stuck). 
- Action: If this probe fails, kubelet restarts the container.
- **Note!** It runs for pods lifetime, so keep it simple.

### ✅ Readiness Probe
- Purpose: Detects when a container is *ready to accept traffic*.
- Action: If this probe fails, Kubernetes removes the pod from Service endpoints (no traffic).
- It dosen't kill the container, it again waits for its checks to pass before sending the *traffic* again
- **Note!** It runs for pods lifetime, so keep it simple.

### ✅ Startup Probe
- Purpose: Detects when a container has completed its startup sequence.
- Action: While the startup probe is running, kubelet ignores liveness failures.
- It runs only once.

Each probe can be configured using one of three handlers:
- `exec`: run a command inside the container
- `httpGet`: perform an HTTP GET request
- `tcpSocket`: attempt a TCP connection

---

## 4) Probe lifecycle (what happens and when)

1. **Container starts**
   - The startup probe (if configured) begins running.
   - Liveness/readiness probes are ignored until the startup probe succeeds (if present).

2. **Startup probe succeeds** (or is absent)
   - Readiness and liveness probes start running on their configured intervals.

3. **Readiness probe fails**
   - Pod is marked **NotReady**.
   - The pod is removed from Service endpoints, so it receives no new traffic.
   - The container is not restarted (unless liveness also fails).

4. **Liveness probe fails**
   - Kubelet restarts the container.
   - Restart count increments, and normal startup repeats.

5. **Probe recovery**\n   - When probes start passing again, readiness returns and the pod is eligible for traffic.

---

## 5) Important considerations for probes

### ✅ Choose the right probe type
- Use **liveness** to restart unhealthy containers.
- Use **readiness** to control traffic flow.
- Use **startup** for slow-starting apps (e.g., JVM apps, databases).

### ✅ Configure timeouts and thresholds carefully
- `initialDelaySeconds` avoids false failures at startup
- `periodSeconds` controls frequency
- `timeoutSeconds` should be shorter than the work being checked
- `failureThreshold` determines how many consecutive failures are allowed

### ✅ Avoid expensive checks
- Probes run frequently; keep them fast and lightweight.
- Heavy operations can overload the container or infrastructure.

### ✅ Understand your app’s behavior
- Some apps are “ready” before they can serve traffic (e.g., migrations run after start).
- Some apps may appear healthy but can still refuse traffic (e.g., cache loading in progress).

### ✅ Don’t probe external dependencies (unless that’s what you want)
- Probing a database connection or external API can hide issues or cause cascading failures.
- If you need external checks, consider using a sidecar or dedicated health endpoint.

---

## 🧪 Quick validation (example commands)


```bash
kubectl describe pod <pod-name>

kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].state}'

kubectl get pod <pod-name> -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'
```

---

## 🧩 Example: probe configuration (manifest)

Here’s a simple example of a Deployment that uses all three probe types. The `startupProbe` ensures the container has time to initialize before liveness checks begin.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: probe-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: probe-demo
  template:
    metadata:
      labels:
        app: probe-demo
    spec:
      containers:
      - name: probe-demo
        image: nginx:latest
        readinessProbe:
          httpGet:
            path: /healthz
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 3
        livenessProbe:
          httpGet:
            path: /healthz
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 10
          failureThreshold: 3
        startupProbe:
          httpGet:
            path: /healthz
            port: 80
          failureThreshold: 10
          periodSeconds: 5
```

> 💡 Tip: adjust probe endpoints and timings to match your app’s real startup and response characteristics.

---

Happy probing! Keep your checks simple, deliberate, and aligned to the behaviour you want Kubernetes to enforce.
