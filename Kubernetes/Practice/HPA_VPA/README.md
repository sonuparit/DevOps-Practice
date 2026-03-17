# Kubernetes HPA & VPA Controller (Horizontal/Vertical Pod Autoscaler) on Minikube/Kind Cluster

## In this practice project, I deployed an HPA controller. HPA will automatically scale the number of pods based on CPU utilization whereas VPA scales by increasing or decreasing CPU and memory resources within the existing pod containers—thus scaling capacity vertically


### Pre-requisites to implement this project:

- Create 1 virtual machine on AWS with 2 CPU, 4GB of RAM (t2.medium)
- Setup minikube on it <a href="https://minikube.sigs.k8s.io/docs/start/">Minikube setup</a>.
- Setup Kind Cluster on it <a href="https://kind.sigs.k8s.io/docs/user/quick-start/">Kind Cluster Setup</a>.

**Install metrics server on minicube, run this command:**
```yml
minikube addons enable metrics-server
```
- Check minikube cluster status and nodes :
```yml
minikube status
kubectl get nodes
```
**If you are using a Kind cluster install Metrics Server**
```yml
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```
- Edit the Metrics Server Deployment
```yml
kubectl -n kube-system edit deployment metrics-server
```
- Add the security bypass in it under `container.args`
```yml
- --kubelet-insecure-tls
- --kubelet-preferred-address-types=InternalIP,Hostname,ExternalIP
```
- Restart the deployment
```yml
kubectl -n kube-system rollout restart deployment metrics-server
```
- Verify if the metrics server is running
```yml
kubectl get pods -n kube-system
kubectl top nodes
```
#
## What we are going to implement:
We will create a deployment & service files for Apache and with the help of HPA, we will automatically scale the number of pods based on CPU utilization.
#
### Steps to implement HPA:

- Update the Deployments:

  - We'll add resource: `requests and limits` in our deployment. This is required for HPA to monitor CPU usage.
```yml
#apache-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: apache
  template:
    metadata:
      labels:
        app: apache
    spec:
      containers:
      - name: apache
        image: httpd:2.4
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
          limits:
            cpu: 200m
---
apiVersion: v1
kind: Service
metadata:
  name: apache-service
spec:
  selector:
    app: apache
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```
#
- Apply the updated deployments:
```yml
kubectl apply -f apache-deployment.yaml
```
#
- Create HPA Resources
  - We will create HPA resources for both Apache deployment. The HPA will scale the number of pods based on CPU utilization.
```yml
#apache-hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: apache-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: apache-deployment
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 20
```
#
- Apply the HPA resources:
```yml
kubectl apply -f apache-hpa.yaml
```
#
- port forward to access the Apache service on browser.
```yml
kubectl port-forward svc/apache-service 8081:80 --address 0.0.0.0 &
```
#
- Verify HPA
  - You can check the status of the HPA using the following command:
```yml
kubectl get hpa
```
> This will show you the current state of the HPA, including the current and desired number of replicas.

#
### Stress Testing
#
- To see HPA in action, we will perform a stress test on our deployments. We will use `busybox` to generate load on the Apache deployment:
```yml
kubectl run -i --tty load-generator --image=busybox /bin/sh
```
#
- Inside the container, use 'wget' to generate load:
```yml
while true; do wget -q -O- http://apache-service.default.svc.cluster.local; done
```

This will generate continuous load on the Apache service, causing the HPA to scale up the number of pods.

#
- Now to check if HPA worked or not, We will open a new terminal and watch our hpa, by running following command:
```yml
kubectl get hpa -w
```

> Note: Wait for few minutes to get the status reflected.

Similarly we can implement **VPA**