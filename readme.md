# Section 1

## apiVersion, synonym

|kind|apiVersion|synonym|
|---|---|---|
|Pod|v1|po|
|ReplicationController|v1|rc|
|ReplicaSet|apps/v1|rs|
|Deployment|apps/v1|deploy|
|Service|v1|svc|
|Namespace|v1|ns|
|ResourceQuota|v1|quota|

* [resource shortcuts](https://medium.com/swlh/maximize-your-kubectl-productivity-with-shortcut-names-for-kubernetes-resources-f017303d95e2)
* service types : (default)ClusterIp, NodePort, LoadBalancer

## Lab1 : Pods

```bash
kubectl get pods | grep newpods | head -1 | awk '{print $1}'
```

## Lab2 : ReplicaSets

it is the replacement of Replication Controller, but supports 'selector' which is meant to monitor with context of 'set'.

```bash
kubectl scale rs $(RS) --replicas=0
```

## Tips for fast-CLI commands using **Imperative ways**

Edit existing object
```
kubectl edit deployment nginx
```

Create an NGINX `Pod`
```bash
kubectl run nginx --image=nginx
```
Generate POD Manifest YAML file (-o yaml). Don't create it(--dry-run)
```bash
kubectl run nginx --image=nginx --dry-run=client -o yaml
```
Create a `Deployment`
```bash
kubectl create deployment --image=nginx nginx
```
Generate Deployment YAML file (-o yaml). Don't create it(--dry-run)
```bash
kubectl create deployment --image=nginx nginx --dry-run=client -o yaml
```
Generate Deployment YAML file (-o yaml). Don't create it(--dry-run) with 4 Replicas (--replicas=4)
```bash
kubectl create deployment --image=nginx nginx --dry-run=client -o yaml > nginx-deployment.yaml
```
Save it to a file, make necessary changes to the file (for example, adding more replicas) and then create the deployment.
```bash
kubectl create -f nginx-deployment.yaml
```
OR

In k8s version 1.19+, we can specify the --replicas option to create a deployment with 4 replicas.
```bash
kubectl create deployment --image=nginx nginx --replicas=4 --dry-run=client -o yaml > nginx-deployment.yaml
```

Create a Service named redis-service of type ClusterIP to expose pod redis on port 6379
```bash
kubectl expose pod redis --port=6379 --name redis-service --dry-run=client -o yaml
```
(This will automatically use the pod's labels as selectors)

Or

```bash
kubectl create service clusterip redis --tcp=6379:6379 --dry-run=client -o yaml 
```
This will not use the pods labels as selectors, instead it will assume selectors as app=redis. You cannot pass in selectors as an option. So it does not work very well if your pod has a different label set. So generate the file and modify the selectors before creating the service



Create a `Service` named nginx of type NodePort to expose pod nginx's port 80 on port 30080 on the nodes:
```bash
kubectl expose pod nginx --type=NodePort --port=80 --name=nginx-service --dry-run=client -o yaml
```
This will automatically use the pod's labels as selectors, but you cannot specify the node port. You have to generate a definition file and then add the node port in manually before creating the service with the pod.

Or

```bash
kubectl create service nodeport nginx --tcp=80:80 --node-port=30080 --dry-run=client -o yaml
```
This will not use the pods labels as selectors

Both the above commands have their own challenges. While one of it cannot accept a selector the other cannot accept a node port. I would recommend going with the kubectl expose command. If you need to specify a node port, generate a definition file using the same command and manually input the nodeport before creating the service.

## DNS & Namespace & Resource Quota
To reach `db-service` in `local` or `default` namespace,
```javascript
mysql.connect("db-service");
```
To reach `db-service` in `dev` namespace,
```javascript
mysql.connect("db-service.dev.svc.cluster.local");
```
why? `cluster.local` is the default domain name of the k8s cluster, `svc` is subdomain representing service, `dev` is the namespace.

To check resources in another namespaces,
```bash
kubectl get pods --namespace=kube-system
```

To switch to specific namespace,
```bash
kubectl config set-context $(kubectl config current-context) --namespace=dev
```

To view resources in all namespaces,
```
kubectl get pods -A
or
kubectl get pods --all-namespaces
```

## Applying all files in folder at once in **Declarative way**
```bash
kubectl apply -f /path/to/config-files
```