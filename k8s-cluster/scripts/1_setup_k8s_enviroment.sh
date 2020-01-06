echo '修改主机名'
hostnamectl set-hostname k8s-node2
hostname
echo 'HOSTNAME=k8s-node2' >> /etc/sysconfig/network

cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

echo '关闭防火墙'
systemctl disable firewalld
systemctl stop firewalld 
firewall-cmd --state
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

echo '关闭swap'
swapoff -a
sed -e "s/\(^.*swap.*$\)/#\1/" /etc/fstab
free -m

echo '设置yum源'
yum install  -y curl wget git
# cd /etc/yum.repos.d/
# curl -o CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
# curl -o docker-ce.repo https://download.docker.com/linux/centos/docker-ce.repo
rm -f /etc/yum.repos.d/Centos-7.repo
rm -f /etc/yum.repos.d/docker-ce.repo
cp -f ./repo/Centos-7.repo /etc/yum.repos.d/Centos-7.repo
cp -f ./repo/docker-ce.repo /etc/yum.repos.d/docker-ce.repo

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
        http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum clean all  
yum makecache  
yum repolist

echo '卸载Docker-ce'
yum list installed | grep docker
yum remove docker-ce.x86_64 ddocker-ce-cli.x86_64 -y
rm -rf /var/lib/docker
rm -rf /var/run/docker

echo '安装Docker-ce'
yum list docker-ce --showduplicates | sort -r
yum install -y docker-ce
systemctl start docker
systemctl enable docker
docker info

echo '修改 Docker 的镜像存储位置'
mkdir -p /data
rm -rf /data/docker
service docker stop
mv /var/lib/docker /data/
ln -s /data/docker /var/lib/docker
systemctl daemon-reload
systemctl restart docker
systemctl enable docker
docker info

