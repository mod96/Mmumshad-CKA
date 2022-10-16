sudo systemctl enable docker && systemctl start docker

sudo systemctl enable kubelet && systemctl start kubelet

cat <<EOF | sudo tee kubeadm-config.yaml
kind: ClusterConfiguration
apiVersion: kubeadm.k8s.io/v1beta3
kubernetesVersion: v1.21.0
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
EOF

kubeadm init --config kubeadm-config.yaml