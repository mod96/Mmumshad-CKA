## Authentication
|kind|apiVersion|alias|
|---|---|---|
|servicesaccounts|v1|sa|

create account
```bash
k create serviceaccount sa1
k get servicesaccount
```
* how? static password file | static token file | certificates | identity service


### 1. Using static password file (not recommanded, need volume mount)

user-details.csv
```csv
pass1,usrname1,usrid1,group1
pass2,usrname2,usrid2,group2
```
kube-apiserver.yaml
```yaml
- command:
  - kube-apiserver
  - ...
  - -- basic-auth-file=user-details.csv
```
accessing
```bash
curl -v -k https://master-node-ip:6443/api/v1/pods -u "usrname1:pass1"
```

### 2. Using static token file (not recommanded, need volume mount)
user-token-details.csv
```csv
tkn1,usrname1,usrid1,group1
tkn2,usrname2,usrid2,group2
```
kube-apiserver.yaml
```yaml
- command:
  - kube-apiserver
  - ...
  - -- token-auth-file=user-token-details.csv
```
accessing
```bash
curl -v -k https://master-node-ip:6443/api/v1/pods --header "Authorization: Bearer tkn1"
```