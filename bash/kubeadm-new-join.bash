cat <<EOF | tee kubeadm-join.bash
/usr/sbin/modprobe br_netfilter
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
echo 1 > /proc/sys/net/ipv4/ip_forward
EOF

echo "kubeadm join " >> tmp
cat /etc/hosts | grep $(hostname) | awk '{print $1}' >> tmp
echo ":6443 --token " >> tmp
cat ~/token.txt >> tmp
echo " --discovery-token-ca-cert-hash sha256:" >> tmp
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | \
   openssl dgst -sha256 -hex | sed 's/^.* //' >> tmp
tr -d '\n' < tmp >> kubeadm-join.bash
echo -e "\n" >> kubeadm-join.bash
rm tmp