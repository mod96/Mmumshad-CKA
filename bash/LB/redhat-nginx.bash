cat <<EOF | sudo tee /etc/yum.repos.d/nginx.repo
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/7/$basearch/
gpgcheck=0
enabled=1
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