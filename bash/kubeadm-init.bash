sudo systemctl enable docker && systemctl start docker

sudo systemctl enable kubelet && systemctl start kubelet

sudo kubeadm init