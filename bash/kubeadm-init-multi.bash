cat <<EOF | tee /etc/docker/daemon.json
{
"exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

systemctl daemon-reload
systemctl restart kubelet

/usr/sbin/modprobe br_netfilter
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
echo 1 > /proc/sys/net/ipv4/ip_forward

sudo kubeadm init --control-plane-endpoint "$1" --upload-certs > kubeadm-init-log.log

cat <<EOF | tee kubeadm-join.bash
/usr/sbin/modprobe br_netfilter
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
echo 1 > /proc/sys/net/ipv4/ip_forward
EOF

sed -n '/kubeadm join/p;/--discovery-token-ca-cert-hash/p;/--control-plane/p' \
kubeadm-init-log.log >> kubeadm-join.bash