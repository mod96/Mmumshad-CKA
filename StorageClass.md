If you use cloud provider...

Using StorageClass, you don't have to manually create every PVs. The provider will dynamically create storage.

```yml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: google-storage
provisioner: kubernetes.io/gce-pd
```

```yml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myclaim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: google-storage
  resources:
    requests:
      storage: 500Mi
```

```yml
spec:
  containers:
    - name: myfrontend
      image: nginx
      volumeMounts:
      - mountPath: "/var/www/html"
        name: mypd
  volumes:
    - name: mypd
      persistentVolumeClaim:
        claimName: myclaim
```
----------
For StatefulSets :

By using volumeClaimTemplate field in Pod definition, you don't need to manually create PVC every time, too. So the final form looks like:

```yml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: google-storage
provisioner: kubernetes.io/gce-pd
```

```yml
(headless svc)
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
...
spec:
  ...
  template:
    metadata:
    ...
    spec:
      containers:
      - name: mysql
        image: mysql
        volumeMounts:
        - mountPath: "/var/www/html"
          name: data-volume
  volumeClaimTemplates:
  - metadata:
      name: data-volume
    spec:
      accessModes:
        - ReadWriteOnce
      storageClassName: google-storage
      resources:
        requests:
        storage: 500Mi
```