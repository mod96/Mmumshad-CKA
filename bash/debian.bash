sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

systemctl disable firewalld && systemctl stop firewalld

sudo apt-get update
sudo apt-get install -y docker kubelet kubeadm kubectl kubernetes-cni
sudo apt-mark hold kubelet kubeadm kubectl

sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
sudo apt-get install -y openssh-server ii
sudo apt install ebtables ethtool iproute2

if grep -q "PermitRootLogin yes" /etc/ssh/sshd_config; then
  echo "ssh password already on."
else
  echo "This makes possible to ssh using password"
  echo -e "PermitRootLogin yes \nPasswordAuthentication yes \n" >> /etc/ssh/sshd_config
  sudo /etc/init.d/ssh restart
fi

if grep -q "PATH=" ~/.bashrc; then
  echo "PATH already configured in bashrc."
else
  echo "This adds /usr/sbin to PATH. But you need to re-login su."
  cat /etc/login.defs | grep ENV_PATH | grep PATH= | awk '{print $2}{print ":/usr/sbin"}' > tmp
  tr -d '\n' < tmp >> .bashrc
fi

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo chmod a+r /etc/apt/keyrings/docker.gpg
sudo apt-get update
sudo apt-get install -y containerd.io
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

sed -i '/"cri"/ s/^/#/' /etc/containerd/config.toml
systemctl restart containerd

sudo systemctl enable kubelet && systemctl start kubelet

sudo swapoff -a && sed -i '/ swap / s/^/#/' /etc/fstab
