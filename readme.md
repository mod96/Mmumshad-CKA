# Section 1&2 : Core Concepts

## apiVersion, synonym

|kind|apiVersion|alias|
|---|---|---|
|Pod|v1|po|
|ReplicationController|v1|rc|
|ReplicaSet|apps/v1|rs|
|Deployment|apps/v1|deploy|
|Service|v1|svc|
|Namespace|v1|n|
|ResourceQuota|v1|quota|
|DaemonSet|apps/v1|ds|
|ConfigMap|v1|cm|

* [resource shortcuts](https://medium.com/swlh/maximize-your-kubectl-productivity-with-shortcut-names-for-kubernetes-resources-f017303d95e2)
* service types : (default)ClusterIp, NodePort, LoadBalancer

## Core Object 1: Pods

```bash
kubectl get pods | grep newpods | head -1 | awk '{print $1}'
```

* There are 3 common patterns, when it comes to designing multi-container PODs: `sidecar` | `adapter` | `ambassador`

## Core Object 2: ReplicaSets

it is the replacement of Replication Controller, but supports 'selector' which is meant to monitor with context of 'set'.

```bash
kubectl scale rs $(RS) --replicas=0
```

## linux command tips
```bash
scp /opt/cluster2.db etcd-server:/root (Post a file to remote server.)
```
```bash
k get clusterroles | wc -l (count rows)
```
```bash
k exec -it my-pod -- ls /var/run/secrets/kubernetes.io/servicesaccount
```
```bash
ps -ef  (view all processes)
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
Extract the pod definition in YAML file, add command `sleep 1000`
```bash
kubectl get pod webapp -o yaml --command -- sleep 1000 > my-new-pod.yaml
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
or, recursively,
```bash
kubectl apply -f <forder> --recursive
kubectl apply -f <forder> --R
```

<br>

# Section 3 : Scheduling

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
This can't use multiple filtering. So we use node affinity

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

## DaemonSets

Only one copy of the pod is present on every Nodes. `.yaml` is the same as rs.

* kube-proxy, weave-net(networking)
* Ignored by scheduler

## Static PODs

fixed to Node.

`.yaml` of PODs must be in `/etc/kubernetes/manifests` of a Node. created by the kubelet. For example, Deploy Control Plane components as Static PODs

* Ignored by scheduler
* location of staticPods can be vary depending on `/var/lib/kubelet/config.yaml`
* To inspect other node, `ssh <<internal IP>>`

## Custom Scheduler
Create one with file
```bash
kubectl create -n kube-system configmap my-scheduler-config --from-file=/root/my-scheduler-config.yaml
```
Create POD with that scheduler
```yml
spec:
  containers:
  ...
  schedulerName: my-scheduler
```

<br>

# Section 4 : Logging & Monitoring

## Metric Server

k8s doesn't have fully-functional metrics server. But below is the default metrics server (but, this is in-memory.) For fully-functional metricds server, we need `Prometheus` | `Elastic Stack` | `Datadog` | `dynatrace`.
```bash
git clone https://github.com/kubernetes-sigs/metrics-server.git
kubectl create -f deploy/1.8+/
```
view
```bash
k top node
k top pod
```

## Logging
```bash
k create -f event-simulator-pod.yaml
k logs -f event-simulator-pod <<container name if given multiple>>
```

<br>

# Section 5 : Application Lifecycle Management


## Rolling Update

```bash
k rollout status deployment/myapp-deployment
```
* StrategyType: `Recreate` | `RollingUpdate`(default)

```bash
k rollout history deployment/myapp-deployment
k rollout undo deployment/myapp-deployment
```

## command & args

From docker,
```dockerfile
FROM Ubuntu
CMD ["sleep", "5"]
```
was general but in case we want to modify the CMD, below command is needed and it's not clean.
```bash
docker run ubuntu-sleeper sleep 10
```
In order to make command line cleaner,
```dockerfile
FROM Ubuntu
ENTRYPOINT ["sleep"]
CMD ["5"]
```
```
docker run ubuntu-sleeper 10
docker run --entrypoint sleep2.0 ubuntu-sleeper 10
```
And in k8s, `command == ENTRYPOINT` and `args == CMD`.
```yml
spec:
  containers:
  - name: ubuntu-sleeper
    image: ubuntu-sleeper
    command: ["sleep2.0"]
    args: ["10"]
```

## ConfigMaps & Secrets
Creation with Imperative way
```
k create configmap <config-name> --from-literal=<key>=<value> --from-literal=...
k create secret <secret-name> --from-literal=<key>=<value> --from-literal=...
```
1. Inject all data from configMap
```yaml
containers:
- name: simple-webapp
  ...
  envFrom:
  - configMapRef:  # secretRef
      name: app-config
```
2. Single data from configMap
```yaml
containers:
- name: simple-webapp
  ...
  env:
    - name: APP_COLOR
      valueFrom:
        configMapKeyRef:  # secretKeyRef
          name: app-config
          key: APP_COLOR
```
3. Using volume
```yaml
volumes:
- name: app-config-volume
  configMap:  # secret
    name: app-config  # secretName
```

Encoding / Decoding
```bash
echo -n 'mysql' | base64
echo -n 'bXlzcWw=' | base64 --decode
```

<br>

# Section 6 : Cluster Maintenance

## OS upgarade
```bash
k drain node01 --ignore-daemonsets
<do something on node01 such as OS upgrade>
k uncordon node01
```
* `k cordon node01` just makes a node not schedulable (pre-existed pods are still there)

## k8s version control
kube-apiserver is the main and

|component|version capacity|
|---|---|
|Controller-manager|-1 ~ 0|
|kube-scheduler|-1 ~ 0|
|kubelet| -2 ~ 0|
|kube-proxy| -2 ~ 0|
|kubectl| -1 ~ +1|

So, upgrade must be done every minor upgrades. [official docs](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)

Actually, kubeadm does all components for us (upgrade master and then worker nodes)
```bash
kubeadm upgrade plan
kubeadm upgrade apply
```
for example, we want to go v1.13 from v1.11
```bash
apt-mark unhold kubeadm && \
apt-get update && apt-get upgrade -y kubeadm=1.12.0-00 && \
apt-mark hold kubeadm

apt-mark unhold kubelet && \
apt-get upgrade -y kubelet=1.12.0-00 && \
apt-mark hold kubelet

> sudo kubeadm upgrade apply v1.12.0  # for master node (both need drain & uncordon)
> sudo kubeadm upgrade node # for worker node

sudo systemctl daemon-reload
sudo systemctl restart kubelet
```
repeat above for 1.13.

## Backup
Resources
```bash
k get all -A -o yaml > all-deploy-services.yaml
```
* there is a solution by `Velero` by HeptIO.

ETCD (actually saved in `/var/lib/etcd`)
```bash
export ETCDCTL_API=3
etcdctl snapshot save snapshot.db --endpoints=127.0.0.1:2379 \
--cacert=/etc/kubernetes/pki/etcd/ca.crt \
--cert=/etc/kubernetes/pki/etcd/server.crt \
--key=/etc/kubernetes/pki/etcd/server.key

etcdctl snapshot status snapshot.db
```
ETCD - restore (didn't worked in kodekloud. try oneline restore command in External etcd part.)
```bash
export ETCDCTL_API=3
etcdctl snapshot restore snapshot.db \
--data-dir /var/lib/etcd-from-backup  # to prevent accidentally mix etcd with existing before

vim /etc/kubernetes/manifests/etcd.yaml  # change dirs
```

## Multiple Clusters
(go KubeConfig part of security for `config` command)

Get a file from remote server.
```bash
ssh cluster1-controlplane "cat /opt/cluster1.db" > /opt/cluster1.db
```
Post a file to remote server.
```bash
scp /opt/cluster2.db etcd-server:/root
```
- External ETCD : get members
```bash
ETCDCTL_API=3 etcdctl \
 --endpoints=https://127.0.0.1:2379 \
 --cacert=/etc/etcd/pki/ca.pem \
 --cert=/etc/etcd/pki/etcd.pem \
 --key=/etc/etcd/pki/etcd-key.pem \
  member list
```
- External ETCD : inspect
```
ps -ef | grep etcd
```
- External ETCD : restore & change data-dir
```
ETCDCTL_API=3 etcdctl --endpoints=.. --cacert=.. --cert=.. --key=.. snapshot restore /root/cluster2.db --data-dir /var/lib/etcd-data-new

vi /etc/systemd/system/etcd.service
chown -R etcd:etcd /var/lib/etcd-data-new
systemctl daemon-reload
systemctl restart etcd
```


<br>

# Section 7 : Security

## Authentication
|kind|apiVersion|alias|
|---|---|---|
|servicesaccounts|v1|sa|

### 1. service account (account used by application e.g. logging app)
```bash
k create serviceaccount sa1
k create token sa1
```
Actually, every namespace has its own service account and volume projected to every pod in it. To change this,
```yml
spec:
  containers:
  ...
  serviceAccountName: sa1
```
To use old-school style, non-expirary token
```yml
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: sa1-token
  annotations:
    kubernetes.io/service-account.name: sa1
```

then we need 'authenticate' for the account. How? ~~static password file~~ | ~~static token file~~ | certificates | identity service

### 2. View certificates in k8s

There is internal CA in k8s.

![alt text cert](/img/cert.PNG)

you can check [this](./security-the-hard-way.md) or [mmumshad's tool](https://github.com/mmumshad/kubernetes-the-hard-way/tree/master/tools) to make own .crt, but let's just use kubeadm, which will do all the things for us.

```bash
cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep .crt
```
```bash
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout
```
wrong certificate can kill kube-api server, and can't use kubectl command. Then, use
```bash
docker ps -a
docker logs <container-id>
```
or
```bash
crictl ps -a
```
which is prefered for high version k8s. [docs](https://kubernetes.io/docs/tasks/debug/debug-cluster/crictl/)

### 3. Certificates API (by doing 3&4, we create User / Group)

To generate another admin, the first admin had to login to masternode and sign with ca.crt&ca.key. But there is an easy way.
```bash
openssl genrsa -out jane.key 2048
> jane.key
openssl req -new -key jane.key -subj "/CN=jane" -out jane.csr
> jane.csr
```
* setting `"/O=some-group"` will make and set group. [link](https://kubernetes-tutorial.schoolofdevops.com/configuring_authentication_and_authorization/)
```yml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: jane
spec:
  groups:
  - system:nodes
  - system:authenticated
  usages:
  - digital signature
  - key encipherment
  - client auth
  request:
    $(cat jane.csr | base64 | tr -d "\n")
```
```bash
k get csr
k certificate approve(deny) jane
k get csr jane -o yaml
```
copy certificate and
```
echo "LS0...o=" | base64 --decode
```

### 4. Detail of KubeConfig
only the one named `config` and located where kube-apiserver pod defines will be applied.
```yml
apiVersion: v1
kind: Config

current-context: dev-user@development  # choose from context

clusters:  # this is fixed most of the time
- name: kubernetes
  cluster:
    certificate-authority: /etc/kubernetes/pki/ca.crt  (certificate-authority-data: $(base64))
    server: https://kube-apiserver:6443
- name: development
  ...
- name: stage
  ...

contexts:  # change this to make connection
- name: admin@kubernetes
  context:
    cluster: kubernetes
    user: admin
    namespace: default
- name: dev-user@development
  ...
...

users:  # this is fixed most of the time
- name: admin
  user:
    client-certificate: /etc/kubernetes/pki/admin.crt
    client-key: /etc/kubernetes/pki/admin.key
- name: dev-user
  ...
- name: production
```
```bash
k config view
```
This will change the file and context.
```
k config use-context prod-user@production
```
* for temporary use, `k config --kubeconfig=/path/my-config ...`

## Authorization

Node | ABAC(Atrribute Based) | RBAC(Role Based) | Webhook | AlwaysAllow(default) | AlwaysDeny

ABAC is hard to manage since it writes every policy for each user/groups.

RBAC, for set of permissions, we define role and match users to that role. (see slide)

Webhook : such as `Open Policy Agent` can help this.

### We normally use RBAC (for User, ServiceAccount, Group)

### 1. Namespaced Objects

* such as pods, rs, jobs, deploy, svc, secrets, roles, rolebindings, configmaps, pvc
* Can inquire such resources with `k api-resources --namespaced=true`

developer-role.yaml
```yml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["list“, "get", “create“, “update“, “delete"]
- apiGroups: [""]
  resources: [“ConfigMap"]
  verbs: [“create“]
  resourceNames: ["devConfig"]
```
devuser-developer-binding.yaml
```yml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: devuser-developer-binding
  namespace: default
subjects:
- kind: User
  name: dev-user
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
```
check access
```
k auth can-i create deploy (i'm sample admin)
> yes
k auth can-i delete nodes (i'm sample admin)
> no
k auth can-i create pods --as dev-user
> no
k auth can-i create pods --as dev-user
> yes
k auth can-i create pods --as dev-user -n test
> no
```

### 2. Cluster Scoped Objects 

* Such as nodes, pv, clusterroles, clusterrolebindings, certificatessigningrequests, namespaces
* Can inquire such resources with `k api-resources --namespaced=false`
* But, if we want global scoped pod/rs/... role, this will do that.

cluster-admin-role.yaml
```yml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-administrator
rules:
- apiGroups: [""]
  resources: [“nodes"]
  verbs: ["list“, "get", “create“, “delete"]
```

cluster-admin-role-binding.yaml
```yml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-admin-role-binding
subjects:
- kind: User
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-administrator
  apiGroup: rbac.authorization.k8s.io
```


## etc

### 1. Using private image
```bash
kubectl create secret docker-registry secret-name \
--docker-server=private-registry.io \
--docker-username=registry-user \
--docker-password=registry-password \
--docker-email=registry-user@org.com
```
```yml
spec:
  containers:
  ...
  imagePullSecrets:
  - name: secret-name
```

### 2. Adding/Deleting Security Context on the Pod/Container
Pod
```yml
spec:
  containers:
  ...
  securityContext:
    runAsUser: 1000
    capabilities:
      add: ["MAC_ADMIN"]
```
Container
```yml
spec:
  containers:
  - name: ubuntu
    image: ubuntu
    securityContext:
      runAsUser: 1000
      capabilities:
        add: ["MAC_ADMIN"]
```
if both configured, container's one will override.