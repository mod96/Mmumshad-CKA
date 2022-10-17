sudo yum install yum-utils

if [ -z ${releasever+x} ]; then
    export releasever="7"
else
    echo "releasever=$releasever"
fi

if [ -z ${basearch+x} ]; then
    export basearch="x86_64"
else
    echo "basearch=$basearch"
fi

cat <<EOF | sudo tee /etc/yum.repos.d/nginx.repo
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF

sudo yum install -y nginx

sudo firewall-cmd --permanent --zone=public --add-port=6443/tcp
sudo firewall-cmd --reload
sudo firewall-cmd --list-ports

sudo systemctl enable nginx
sudo systemctl start nginx

mkdir /etc/nginx
cat << EOF > /etc/nginx/nginx.conf
events {}
stream {
    upstream stream_backend {
        least_conn;
        server $1:6443;
        server $2:6443;
        server $3:6443;
    }
    server {
        listen         6443;
        proxy_pass stream_backend;
        proxy_timeout 300s;
        proxy_connect_timeout 1s;
    }
}
EOF

sudo systemctl restart nginx