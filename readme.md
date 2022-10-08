# Section 1&2 : Core Concepts

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
Extract the pod definition in YAML file
```bash
kubectl get pod webapp -o yaml > my-new-pod.yaml
```
Create a `Deployment`
```bash
kubectl create deployment --image=nginx nginx
```
Generate Deployment YAML file (-o yaml). Don't create it(--dry-run) with 4 Replicas (--replicas=4)
```bash
kubectl create deployment nginx --image=nginx --replicas=4 --dry-run=client -o yaml > nginx-deployment.yaml
```
Save it to a file, make necessary changes to the file (for example, adding more replicas) and then create the deployment.
```bash
kubectl create -f nginx-deployment.yaml
```

Create a `Service` named redis-service of type ClusterIP to expose pod redis on port 6379
```bash
kubectl expose pod redis --port=6379 --name redis-service --dry-run=client -o yaml
```
(This will automatically use the pod's labels as selectors)


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


# Section 2 : Scheduling

## Selector in cli
```bash
k get all --selector env=prod
```

## Node Selecting : usually use 1&4 together

### 1. Taint & Tolerence

taint the node
```bash
k taint nodes node-name key=value:taint-effect
```
untaint
```
k taint nodes node-name key=value:taint-effect-
```
* taint-effect defines what happens to PODs that do not tolerate this taint. 
* NoSchedule | PreferNoSchedule | Noexecute
* example : ```k taint nodes node1 app=blue:NoSchedule```

```yml
...
spec:
  containers:
  ...
  tolerations:
  - key: "app"
    operator: "Equal"
    value: "blue"
    effect: "NoSchedule"
```

### 2. Direct selection
```yml
  containers:
  ...
  nodeName: node009
```

### 3. Label Nodes & nodeSelector

```bash
kubectl label nodes <node-name> <label-key>=<label-value>
```
* example : ```kubectl label nodes node-1 size=Large```
```yml
...
spec:
  containers:
  ...
  nodeSelector:
    size: Large
```

### 4. Node Affinity
```yml
...
spec:
  containers:
  ...
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: size
            operator: In
            values:
            - Large
            - Medium
          - key: size
            operator: NotIn
            values:
            - Small
```
* requiredDuringSchedulingIgnoredDuringExecution
* preferredDuringSchedulingIgnoredDuringExecution
* requiredDuringSchedulingRequiredDuringExecution

## Resource
```yml
containers:
...
  resources:
    requests:
      cpu: 0.1  # larger than 1m
      memory: "256Mi"  # Mebibyte
    limits:  # default 1 vCPU, 512 Mi / throttle if exceed cpu, terminated if exceed memory
      cpu: 2
      memory: "1Gi"
```
for PODs in some namespace to have default `requests`, read [docs](https://www.udemy.com/course/certified-kubernetes-administrator-with-practice-tests/learn/lecture/18055967#notes)



