## TLS Basic (PKI: Public Key Infrastructure)

### Admin side
```
ssh-keygen
> id_rsa(private key) id_rsa.pub(public lock)
```
admin gives it's public lock to the server to protect ssh connection. If we want to access multiple servers, all servers must have public lock. And if there're many admin, their keys must be there, too.

<br>


### Server side

![alt text pki](/img/pki.PNG)

A client must generate a symmetric key to communicate with server(NOT password). Then need to send symmetric key to the server at the initial transmission safely. (Then the client sends id&pwd to authenticate to the server.)

* we don't use asynchronous key in every transmission because it consumes lots of hardware resources.

```
openssl genrsa -out ex.key 1024
> ex.key (private key,  *.key  *-key.pem)
openssl rsa -in ex.key -pubout > ex.pem
> ex.pem (public lock,  *.crt  *.pem)
```
user sends it's private key (symmetric key) to server using public lock of the server.

But malicious server could get your key using it's own public lock. So we added `certificate` that validates it's the safe server, which has 'issued by' signature. Every time server sends public lock, it must send certificate. (Think .crt contains the lock)

Getting certificate from certificate authority(CA, live symantec, globalsign, digicert, ...)
```bash
openssl req -new -key ex.key -out ex.csr -subj "/C=US/ST=CA/O=Org, Inc./CN=domain.com"
> ex.csr (certificate)
```
send it to trusted CA, and they will return it with their sign added. (*.crt will be given)

The browser has all the public locks from CAs. So it can check whether the certificate is manifested. (If a company uses private CA, all employee's computer must have installed public lock of that CA.)

Actually, a server can request client certificate to identify if it's truely their user. Client then make it's rsa key and csr from CA then send it to the server. 

* actually, one with encrypted with public key can only decrypted with private key, vice versa.


## K8S TLS

Also, there is internal CA in k8s.

![alt text cert](/img/cert.PNG)


### Creating crt

First generate internal `CA certificate`.
```bash
openssl genrsa -out ca.key 2048
> ca.key (generated private key)
openssl req -new -key ca.key -subj "/CN=KUBERNETES-CA" -out ca.csr
> ca.csr (generated public lock)
openssl x509 -req -in ca.csr -signkey ca.key -out ca.crt
> ca.crt (self-signed certificate. remember, this must be distributed.)
```

Next generate client certificate. (for `admin` user,)
```bash
openssl genrsa -out admin.key 2048
> admin.key
openssl req -new -key admin.key -subj "/CN=kube-admin/O=system:masters" -out admin.csr
> admin.csr ('O=system:masters' will make this one to have group=system:masters privilege)
openssl x509 -req -in admin.csr -CA ca.crt -CAKey ca.key -out admin.crt
> admin.crt (CA-signed certificate)
```
for `scheduler`, `controller manager`, `kube-proxy`, must have name prefix `system:` (like `system:scheduler`)

For `kube-api server`, it needs to add all alt_names in its certificate.
```bash
openssl genrsa -out apiserver.key 2048
> apiserver.key
openssl req -new -key apiserver.key -subj "/CN=kube-apiserver" -out apiserver.csr \
-config openssl.cnf
> apiserver.csr
openssl x509 -req -in apiserver.csr -CA ca.crt -CAkey ca.key -out apiserver.crt
> apiserver.crt
```
where openssl.cnf is
```cnf
[req]
req_extensions = v3_req
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation,
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
IP.1 = 10.96.0.1
IP.2 = 172.17.0.87
```
* also, kube-api server must have cliet certificate to connect to etcd, kubelet. see details in the [slide](/slides/Section7-Security/Kubernetes+-CKA-+0600+-+Security.pdf).

For `kubelet`, when making kubelet-client for connecting the kube-api server, prefix name with `system:node:` and use `O=system:nodes`.

### Using crt

In admin,
```bash
curl https://kube-apiserver:6443/api/v1/pods \
--key admin.key --cert admin.crt
--cacert ca.crt
```
or, kube-config.yaml
```yml
apiVersion: v1
clusters:
- cluster:
    certificate-authority: ca.crt
    server: https://kube-apiserver:6443
  name: kubernetes
kind: Config
users:
- name: kubernetes-admin
  user:
    client-certificate: admin.crt
    client-key: admin.key
```

For kubelet, (I assume this will be the same for the other components)

kubelet-config.yaml
```yml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.32.0.10"
podCIDR: "${POD_CIDR}"
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/kubelet-node01.crt"
tlsPrivateKeyFile: "/var/lib/kubelet/kubelet-node01.key"
```